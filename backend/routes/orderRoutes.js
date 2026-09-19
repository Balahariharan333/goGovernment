const express = require('express');
const router = express.Router();
const Order = require('../models/Order');
const Store = require('../models/Store');

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

    console.log(`📦 [Order Placed] Order ID: ${orderId} by User: ${userId} for Store: ${storeId}`);

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
    });
  } catch (error) {
    console.error('Error creating order:', error);
    return res.status(500).json({ success: false, message: 'Failed to create order', error: error.message });
  }
});

// 2. GET USER ORDERS (Citizen Order History)
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const orders = await Order.find({ userId }).sort({ createdAt: -1 });

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
    // Return orders ready for pickup where no rider is assigned yet
    const orders = await Order.find({
      status: 'ready_for_pickup',
      $or: [
        { 'deliveryAgent.riderId': '' },
        { 'deliveryAgent.riderId': { $exists: false } },
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
          status: 'ready_for_pickup',
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

    const validStatuses = ['placed', 'preparing', 'ready_for_pickup', 'out_for_delivery', 'delivered', 'cancelled'];
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
        io.emit('order:available', orderPayload);
        io.to('riders').emit('order:available', orderPayload);
        console.log(`📡 [Socket.io] Emitted order:available for order ${orderId}`);
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
