const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Store = require('../models/Store');
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');

// 1. CREATE NEW ORDER (Placed by Citizen)
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      storeId,
      items,
      itemTotal,
      deliveryCharge = 0,
      handlingCharge = 2,
      couponDiscount = 0,
      coinsDiscount = 0,
      grandTotal,
      paymentMethod = 'Cash on Delivery',
      deliveryAddress,
      storeDetails,
    } = req.body;

    if (!userId || !storeId || !items || items.length === 0 || grandTotal === undefined) {
      return res.status(400).json({
        success: false,
        message: 'userId, storeId, items, and grandTotal are required',
      });
    }

    const orderId = 'ORD_' + Date.now().toString().slice(-6);

    // Fetch store details if missing or incomplete
    let resolvedStoreDetails = storeDetails || {};
    if (!resolvedStoreDetails.name || !resolvedStoreDetails.phone) {
      const storeDoc = await Store.findOne({ storeId });
      if (storeDoc) {
        resolvedStoreDetails = {
          storeId: storeDoc.storeId,
          name: storeDoc.name,
          address: storeDoc.address,
          latitude: storeDoc.latitude || 12.9716,
          longitude: storeDoc.longitude || 77.5946,
          phone: storeDoc.phone || '',
        };
      }
    }

    const isWallet = paymentMethod && paymentMethod.toLowerCase().includes('wallet');
    const numGrandTotal = Number(grandTotal);

    if (isWallet) {
      const updatedUser = await User.findOneAndUpdate(
        {
          $or: [{ userId }, { phone: userId }],
          walletBalance: { $gte: numGrandTotal },
        },
        { $inc: { walletBalance: -numGrandTotal } },
        { new: true }
      );

      if (!updatedUser) {
        const currentUser = await User.findOne({ $or: [{ userId }, { phone: userId }] });
        const curBal = currentUser ? currentUser.walletBalance || 0 : 0;
        return res.status(400).json({
          success: false,
          code: 'INSUFFICIENT_WALLET_BALANCE',
          message: `Insufficient wallet balance. Total: ₹${numGrandTotal}, Available: ₹${curBal}`,
          walletBalance: curBal,
        });
      }

      // Record wallet debit transaction
      const now = new Date();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

      const walletTx = new WalletTransaction({
        transactionId: 'PAY_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900),
        userId: updatedUser.userId,
        amount: -numGrandTotal,
        type: 'debit',
        category: 'order_payment',
        paymentMethod: 'Wallet Account',
        orderId: orderId,
        title: resolvedStoreDetails.name || 'Store Order',
        subtitle: `Paid for order #${orderId} · ${dateStr}`,
        balanceAfter: updatedUser.walletBalance,
        status: 'success',
      });
      await walletTx.save();
    }

    const newOrder = new Order({
      orderId,
      userId,
      storeId,
      items,
      itemTotal,
      deliveryCharge,
      handlingCharge,
      couponDiscount,
      coinsDiscount,
      grandTotal,
      paymentMethod,
      paymentStatus: paymentMethod.toLowerCase().includes('cash') ? 'pending' : 'paid',
      deliveryAddress: deliveryAddress || { address: 'Default Delivery Address' },
      storeDetails: resolvedStoreDetails,
      status: 'placed',
    });

    await newOrder.save();

    // ── Record order transaction in ledger for ALL payment methods ──
    if (!isWallet) {
      // For non-wallet payments, just record a ledger entry (no balance deduction)
      const now = new Date();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

      const walletTx = new WalletTransaction({
        transactionId: 'PAY_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900),
        userId,
        amount: -numGrandTotal,
        type: 'debit',
        category: 'order_payment',
        paymentMethod: paymentMethod,
        orderId,
        title: resolvedStoreDetails.name || 'Store Order',
        subtitle: `Paid for order #${orderId} · ${dateStr}`,
        balanceAfter: null,
        status: 'success',
      });
      await walletTx.save();
    }

    console.log(`📦 [Order Placed] Order ID: ${orderId} by User: ${userId} for Store: ${storeId} via ${paymentMethod}`);


    // Emit real-time Socket.io event to notify merchants of new order
    const io = req.app.get('io');
    if (io) {
      const orderPayload = newOrder.toObject ? newOrder.toObject() : newOrder;
      io.emit('order:new', orderPayload);
      io.emit(`store:${storeId}:new_order`, orderPayload);
      io.to(`store:${storeId}`).emit('order:new', orderPayload);
      console.log(`📡 [Socket.io] Emitted order:new & store:${storeId}:new_order for order ${orderId}`);
    }

    return res.status(201).json({
      success: true,
      message: 'Order placed successfully',
      data: newOrder,
      order: newOrder,
    });
  } catch (error) {
    console.error('Error creating order:', error);
    return res.status(500).json({ success: false, message: 'Failed to create order', error: error.message });
  }
});

// GET ALL ORDERS (Admin Web Monitoring)
router.get('/', async (req, res) => {
  try {
    const orders = await Order.find({}).sort({ createdAt: -1 });
    return res.status(200).json({ success: true, data: orders });
  } catch (error) {
    console.error('Error fetching all orders:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch all orders', error: error.message });
  }
});

// GET LIVE RIDER GPS LOCATIONS (For Admin Web & Backend Monitoring)
router.get('/riders/live-locations', async (req, res) => {
  try {
    const riderRegistry = req.app.get('riderRegistry') || new Map();

    // 1. Query ONLY actual delivery partners (role: 'rider' or having vehicle info)
    const dbRiders = await User.find({
      $or: [
        { role: 'rider' },
        { vehicleNumber: { $exists: true, $ne: '' } },
        { vehicleType: { $exists: true, $ne: '' } },
      ],
    });

    const now = Date.now();
    const ridersMap = new Map();

    // 1. Add DB Riders
    for (const u of dbRiders) {
      ridersMap.set(u.userId, {
        riderId: u.userId,
        name: u.userName || 'Delivery Partner',
        phone: u.phone || '',
        vehicleType: u.vehicleType || 'Motorcycle',
        vehicleNumber: u.vehicleNumber || 'KA-01-EE-4521',
        latitude: 0,
        longitude: 0,
        isOnline: false,
        socketId: null,
        lastSeenSecondsAgo: null,
        isActiveGps: false,
      });
    }

    // 2. Merge live socket registry data
    for (const [rId, info] of riderRegistry.entries()) {
      if (!rId) continue;
      
      // Match by userId first, or by phone if rId is a phone number
      let entry = ridersMap.get(rId);
      if (!entry) {
        for (const candidate of ridersMap.values()) {
          if (candidate.phone && candidate.phone === rId) {
            entry = candidate;
            break;
          }
        }
      }

      if (!entry) {
        entry = {
          riderId: rId,
          name: 'Express Rider (' + rId + ')',
          phone: rId,
          vehicleType: 'Motorcycle',
          vehicleNumber: '',
          latitude: 0,
          longitude: 0,
          isOnline: false,
          socketId: null,
          lastSeenSecondsAgo: null,
          isActiveGps: false,
        };
        ridersMap.set(rId, entry);
      }

      const lastSeenSecs = info.lastSeen ? Math.round((now - info.lastSeen) / 1000) : null;
      const hasPos = info.lat !== undefined && info.lat !== 0 && info.lng !== undefined && info.lng !== 0;
      const isActiveGps = Boolean(info.isOnline && hasPos && (lastSeenSecs === null || lastSeenSecs < 120));

      entry.latitude = info.lat || entry.latitude || 0;
      entry.longitude = info.lng || entry.longitude || 0;
      entry.isOnline = Boolean(info.isOnline);
      entry.socketId = info.socketId || null;
      entry.lastSeenSecondsAgo = lastSeenSecs;
      entry.isActiveGps = isActiveGps;
    }

    const ridersList = Array.from(ridersMap.values());
    return res.status(200).json({
      success: true,
      count: ridersList.length,
      riders: ridersList,
    });
  } catch (error) {
    console.error('Error fetching live rider locations:', error);
    return res.status(500).json({ success: false, error: error.message });
  }
});

// 2. GET USER ORDERS (Citizen Order History)
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    let queryUsers = [userId];
    const userDoc = await User.findOne({
      $or: [{ userId }, { phone: userId }],
    });
    if (userDoc) {
      if (userDoc.userId && !queryUsers.includes(userDoc.userId)) queryUsers.push(userDoc.userId);
      if (userDoc.phone && !queryUsers.includes(userDoc.phone)) queryUsers.push(userDoc.phone);
    }
    const orders = await Order.find({ userId: { $in: queryUsers } }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching user orders:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch user orders', error: error.message });
  }
});

// 3. GET STORE ORDERS (Merchant Dashboard)
router.get('/store/:storeId', async (req, res) => {
  try {
    const { storeId } = req.params;
    const orders = await Order.find({ storeId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching store orders:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch store orders', error: error.message });
  }
});

// 4. GET AVAILABLE DELIVERIES (Rider Dashboard)
router.get('/available', async (req, res) => {
  try {
    // Return orders ready for pickup where no rider is assigned yet.
    // 'accepted' orders are excluded — they already belong to another rider.
    const orders = await Order.find({
      status: 'ready_for_pickup',
      $or: [
        { 'deliveryAgent.riderId': '' },
        { 'deliveryAgent.riderId': { $exists: false } },
        { 'deliveryAgent.riderId': null },
      ],
    }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching available orders:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch available deliveries', error: error.message });
  }
});

// 5. GET RIDER DELIVERIES (Active & Past deliveries for a specific Rider)
router.get('/rider/:riderId', async (req, res) => {
  try {
    const { riderId } = req.params;
    const orders = await Order.find({ 'deliveryAgent.riderId': riderId }).sort({ createdAt: -1 });

    return res.status(200).json({
      success: true,
      data: orders,
    });
  } catch (error) {
    console.error('Error fetching rider deliveries:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch rider deliveries', error: error.message });
  }
});

// 6. GET SINGLE ORDER DETAILS
router.get('/:orderId', async (req, res) => {
  try {
    const { orderId } = req.params;
    const order = await Order.findOne({ orderId });

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    return res.status(200).json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Error fetching order details:', error);
    return res.status(500).json({ success: false, message: 'Failed to fetch order', error: error.message });
  }
});

// 7. RIDER ACCEPTS DELIVERY TASK
router.post('/:orderId/accept-rider', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { riderId, name, phone, vehicleNumber, rating = 4.9 } = req.body;

    if (!riderId || !name) {
      return res.status(400).json({ success: false, message: 'riderId and name are required' });
    }

    // 1. Check if the order exists
    const existing = await Order.findOne({ orderId });
    if (!existing) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    // 2. Check if already claimed by someone
    if (existing.deliveryAgent && existing.deliveryAgent.riderId) {
      if (existing.deliveryAgent.riderId === riderId) {
        // Idempotent retry: Same rider clicked again or retried
        return res.status(200).json({
          success: true,
          message: 'Delivery already accepted by you',
          data: existing,
        });
      } else {
        // Concurrency conflict: Another rider already claimed this delivery
        console.log(`⚠️ [Rider Conflict] Rider ${name} (${riderId}) tried to accept order ${orderId}, but it was already claimed by ${existing.deliveryAgent.name} (${existing.deliveryAgent.riderId})`);
        return res.status(409).json({
          success: false,
          code: 'ALREADY_ACCEPTED',
          message: 'This delivery task has already been accepted by another delivery partner.',
          assignedTo: existing.deliveryAgent.name || 'Another rider',
        });
      }
    }

    // 3. Atomic update: Only sets deliveryAgent if riderId is still empty / not exists
    const order = await Order.findOneAndUpdate(
      {
        orderId,
        $or: [
          { 'deliveryAgent.riderId': '' },
          { 'deliveryAgent.riderId': { $exists: false } },
          { 'deliveryAgent.riderId': null },
        ],
      },
      {
        $set: {
          'deliveryAgent.riderId': riderId,
          'deliveryAgent.name': name,
          'deliveryAgent.phone': phone || '',
          'deliveryAgent.vehicleNumber': vehicleNumber || '',
          'deliveryAgent.rating': Number(rating) || 4.9,
          // Transition to 'accepted' — removes this order from other riders' available pool
          status: 'accepted',
        },
      },
      { returnDocument: 'after' }
    );

    // If update failed, another rider claimed it in the same millisecond race
    if (!order) {
      const contested = await Order.findOne({ orderId });
      console.log(`⚠️ [Rider Conflict] Race lost: Rider ${name} (${riderId}) lost race for order ${orderId} to ${contested?.deliveryAgent?.name}`);
      return res.status(409).json({
        success: false,
        code: 'ALREADY_ACCEPTED',
        message: 'This delivery task has already been accepted by another delivery partner.',
        assignedTo: contested?.deliveryAgent?.name || 'Another rider',
      });
    }

    console.log(`🚴 [Rider Assigned] Rider ${name} (${riderId}) accepted order ${orderId}`);

    // Mark rider as BUSY in registry — dispatcher will skip them for new orders
    const riderRegistry = req.app.get('riderRegistry');
    if (riderRegistry && riderRegistry.has(riderId)) {
      riderRegistry.get(riderId).isBusy = true;
      console.log(`🔒 [Rider] ${riderId} marked BUSY — will not receive new dispatch events`);
    }

    // Emit real-time Socket.io event to notify citizen & merchant & riders
    const io = req.app.get('io');
    if (io) {
      const orderPayload = order.toObject ? order.toObject() : order;
      io.emit(`order:${orderId}:status_update`, orderPayload);
      io.emit('order:status_update', orderPayload);
      io.emit(`store:${order.storeId}:order_update`, orderPayload);
      io.to(`store:${order.storeId}`).emit('order:status_update', orderPayload);
      io.emit('order:assigned', orderPayload);
      io.to('riders').emit('order:assigned', orderPayload);
      console.log(`📡 [Socket.io] Emitted order:assigned & order:status_update for order ${orderId}`);
    }

    return res.status(200).json({
      success: true,
      message: 'Delivery accepted successfully',
      data: order,
    });
  } catch (error) {
    console.error('Error accepting delivery:', error);
    return res.status(500).json({ success: false, message: 'Failed to accept delivery', error: error.message });
  }
});

// 8. UPDATE ORDER STATUS (e.g. out_for_delivery, delivered)
router.patch('/:orderId/status', async (req, res) => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    const validStatuses = ['placed', 'preparing', 'ready_for_pickup', 'accepted', 'out_for_delivery', 'delivered', 'cancelled'];
    if (!status || !validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Invalid status. Must be one of: ${validStatuses.join(', ')}`,
      });
    }

    const updateFields = { status };
    if (status === 'delivered') {
      updateFields.deliveredAt = new Date();
      updateFields.paymentStatus = 'paid';
    }

    // If order is cancelled and was paid via wallet, automatically refund to citizen wallet
    if (status === 'cancelled') {
      const existing = await Order.findOne({ orderId });
      if (existing && existing.status !== 'cancelled') {
        const wasWallet = existing.paymentMethod && existing.paymentMethod.toLowerCase().includes('wallet');
        if (wasWallet && existing.paymentStatus === 'paid') {
          const refundAmt = Number(existing.grandTotal) || 0;
          if (refundAmt > 0) {
            const refundedUser = await User.findOneAndUpdate(
              { $or: [{ userId: existing.userId }, { phone: existing.userId }] },
              { $inc: { walletBalance: refundAmt } },
              { new: true, upsert: true }
            );

            const now = new Date();
            const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
            const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

            const refundTx = new WalletTransaction({
              transactionId: 'REF_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900),
              userId: refundedUser.userId,
              amount: refundAmt,
              type: 'credit',
              category: 'order_refund',
              paymentMethod: 'Wallet Refund',
              orderId: existing.orderId,
              title: 'Order Refund',
              subtitle: `Refund for cancelled order #${existing.orderId} · ${dateStr}`,
              balanceAfter: refundedUser.walletBalance,
              status: 'success',
            });
            await refundTx.save();
            updateFields.paymentStatus = 'refunded';
            console.log(`💳 [Auto Refund] Refunded ₹${refundAmt} to user ${refundedUser.userId} for cancelled order ${existing.orderId}`);
          }
        }
      }
    }

    const order = await Order.findOneAndUpdate(
      { orderId },
      { $set: updateFields },
      { returnDocument: 'after' }
    );

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    console.log(`🔄 [Order Status Updated] Order ${orderId} -> ${status}`);

    const io = req.app.get('io');
    if (io) {
      const orderPayload = order.toObject ? order.toObject() : order;
      io.emit(`order:${orderId}:status_update`, orderPayload);
      io.emit('order:status_update', orderPayload);
      io.emit(`store:${order.storeId}:order_update`, orderPayload);
      io.to(`store:${order.storeId}`).emit('order:status_update', orderPayload);
      if (status === 'ready_for_pickup') {
        // Proximity-based dispatch instead of broadcast
        const dispatchOrder = req.app.get('dispatchOrder');
        const storeLat = order.storeDetails?.latitude || 0;
        const storeLng = order.storeDetails?.longitude || 0;
        if (dispatchOrder && (storeLat !== 0 || storeLng !== 0)) {
          dispatchOrder(io, orderPayload, storeLat, storeLng, 1, []);
        } else {
          // Fallback: broadcast if no store coords
          io.to('riders').emit('order:dispatch', { ...orderPayload, dispatchRound: 3, countdownSecs: 30 });
          console.log(`📡 [Dispatch fallback] No store coords — broadcast for order ${orderId}`);
        }
      }
      // When rider accepted — cancel dispatch timer, remove from all riders' alert
      if (status === 'accepted') {
        const dispatchTimers = req.app.get('dispatchTimers');
        if (dispatchTimers && dispatchTimers.has(orderId)) {
          clearTimeout(dispatchTimers.get(orderId).timer);
          dispatchTimers.delete(orderId);
          console.log(`✅ [Dispatch] Cancelled timer for order ${orderId} — rider accepted`);
        }
        io.to(`store:${order.storeId}`).emit('order:status_update', orderPayload);
        // Tell all riders to dismiss any open alert for this order
        io.to('riders').emit('order:dispatch_cancelled', { orderId });
        console.log(`📡 [Socket.io] Emitted order:dispatch_cancelled for order ${orderId}`);
      }

      // When delivered — free the rider so they can receive new dispatch events
      if (status === 'delivered') {
        const riderId = order.deliveryAgent?.riderId;
        if (riderId) {
          const riderRegistry = req.app.get('riderRegistry');
          if (riderRegistry && riderRegistry.has(riderId)) {
            riderRegistry.get(riderId).isBusy = false;
            console.log(`🔓 [Rider] ${riderId} marked FREE — delivery complete, ready for new orders`);
          }
        }
      }
    }

    return res.status(200).json({
      success: true,
      message: `Order status updated to ${status}`,
      data: order,
    });
  } catch (error) {
    console.error('Error updating order status:', error);
    return res.status(500).json({ success: false, message: 'Failed to update order status', error: error.message });
  }
});

module.exports = router;
