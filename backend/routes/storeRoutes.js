const express = require('express');
const router = express.Router();
const Store = require('../models/Store');

// 1. REGISTER A NEW STORE (Status defaults to 'pending')
router.post('/register', async (req, res) => {
  try {
    const {
      ownerId,
      name,
      ownerName,
      phone,
      email,
      category,
      address,
      pincode,
      lat,
      lng,
      storeImage,
      timings,
      bankDetails,
      licenseNumber,
      licenseDoc,
    } = req.body;

    if (!name || !ownerName || !phone || !address) {
      return res.status(400).json({
        error: 'Missing required fields: name, ownerName, phone, address are mandatory',
      });
    }

    if (!bankDetails || !bankDetails.bankName || !bankDetails.accountNumber || !bankDetails.ifscCode) {
      return res.status(400).json({
        error: 'Bank details required: bankName, accountNumber, and ifscCode are mandatory',
      });
    }

    // Check if phone is already registered
    const existingStore = await Store.findOne({ phone });

    if (existingStore) {
      if (existingStore.status === 'rejected') {
        // Allow re-submission if previously rejected
        existingStore.name = name;
        existingStore.ownerName = ownerName;
        if (ownerId) existingStore.ownerId = ownerId;
        existingStore.email = email || existingStore.email;
        existingStore.category = category || existingStore.category;
        existingStore.address = address;
        existingStore.pincode = pincode || existingStore.pincode;
        if (lat !== undefined && lng !== undefined) {
          existingStore.location = { lat: Number(lat), lng: Number(lng) };
        }
        if (storeImage) existingStore.storeImage = storeImage;
        if (bankDetails) existingStore.bankDetails = bankDetails;
        if (licenseNumber) existingStore.licenseNumber = licenseNumber;
        if (licenseDoc) existingStore.licenseDoc = licenseDoc;
        existingStore.status = 'pending';
        existingStore.rejectionReason = '';
        await existingStore.save();

        return res.status(200).json({
          success: true,
          message: 'Store registration re-submitted for review 📝',
          store: existingStore,
        });
      }

      return res.status(409).json({
        error: `A store with this phone number already exists (${existingStore.status})`,
        storeId: existingStore.storeId,
        status: existingStore.status,
      });
    }

    const storeId = 'STORE_' + Math.floor(100000 + Math.random() * 900000);

    const newStore = new Store({
      storeId,
      ownerId: ownerId || '',
      name,
      ownerName,
      phone,
      email: email || '',
      category: category || 'general',
      licenseNumber: licenseNumber || '',
      address,
      pincode: pincode || '',
      location: {
        lat: lat !== undefined ? Number(lat) : 13.0827,
        lng: lng !== undefined ? Number(lng) : 80.2707,
      },
      storeImage: storeImage || '',
      licenseDoc: licenseDoc || '',
      bankDetails: {
        bankName: bankDetails.bankName || '',
        accountNumber: bankDetails.accountNumber || '',
        ifscCode: (bankDetails.ifscCode || '').toUpperCase(),
        accountHolderName: bankDetails.accountHolderName || ownerName,
      },
      status: 'pending',
      timings: timings || { open: '08:00 AM', close: '09:00 PM' },
    });

    await newStore.save();

    console.log(`🏪 [Store Registered] ${name} (${storeId}) - Owner: ${ownerId || phone} - Status: PENDING`);

    res.status(201).json({
      success: true,
      message: 'Store application submitted successfully! Pending municipal admin approval ⏳',
      store: newStore,
    });
  } catch (error) {
    console.error('Error registering store:', error);
    res.status(500).json({ error: 'Failed to register store', details: error.message });
  }
});

// 2. GET STORE BY PHONE OR OWNER ID (Used by Store App on login/launch to check status)
router.get('/my-store/:identifier', async (req, res) => {
  try {
    const { identifier } = req.params;
    const store = await Store.findOne({
      $or: [{ phone: identifier }, { ownerId: identifier }],
    });
    if (!store) {
      return res.status(404).json({ success: false, notFound: true, error: 'No store found for this account' });
    }
    res.status(200).json({ success: true, store });
  } catch (error) {
    console.error('Error fetching store by identifier:', error);
    res.status(500).json({ error: 'Failed to fetch store details' });
  }
});

// 3. GET ALL PENDING STORES (Used by Admin App for review queue)
router.get('/pending', async (req, res) => {
  try {
    const pendingStores = await Store.find({ status: 'pending' }).sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      count: pendingStores.length,
      stores: pendingStores,
    });
  } catch (error) {
    console.error('Error fetching pending stores:', error);
    res.status(500).json({ error: 'Failed to fetch pending stores' });
  }
});

// 4. GET ALL APPROVED & ONLINE STORES (Used by Citizen App for "Near Stores" map & list)
router.get('/approved', async (req, res) => {
  try {
    const { category, includeOffline } = req.query;
    const filter = { status: 'approved' };
    
    // By default, only show stores that are ONLINE (isOnline !== false)
    if (includeOffline !== 'true') {
      filter.isOnline = { $ne: false };
    }
    
    if (category && category !== 'all') {
      filter.category = category;
    }

    const approvedStores = await Store.find(filter).sort({ createdAt: -1 });
    res.status(200).json({
      success: true,
      count: approvedStores.length,
      stores: approvedStores,
    });
  } catch (error) {
    console.error('Error fetching approved stores:', error);
    res.status(500).json({ error: 'Failed to fetch approved stores' });
  }
});

// 7. GET ALL STORES (Admin overview with stats)
router.get('/', async (req, res) => {
  try {
    const { status } = req.query;
    const filter = {};
    if (status) filter.status = status;

    const stores = await Store.find(filter).sort({ createdAt: -1 });
    const pendingCount = await Store.countDocuments({ status: 'pending' });
    const approvedCount = await Store.countDocuments({ status: 'approved' });
    const rejectedCount = await Store.countDocuments({ status: 'rejected' });

    res.status(200).json({
      success: true,
      stats: {
        total: pendingCount + approvedCount + rejectedCount,
        pending: pendingCount,
        approved: approvedCount,
        rejected: rejectedCount,
      },
      stores,
    });
  } catch (error) {
    console.error('Error fetching stores:', error);
    res.status(500).json({ error: 'Failed to fetch stores' });
  }
});

// 4b. GET SINGLE STORE DETAILS BY ID
router.get('/:storeId', async (req, res) => {
  try {
    const { storeId } = req.params;
    const store = await Store.findOne({
      $or: [{ storeId: storeId }, { _id: storeId.match(/^[0-9a-fA-F]{24}$/) ? storeId : null }],
    });
    if (!store) {
      return res.status(404).json({ success: false, error: 'Store not found' });
    }
    res.status(200).json({ success: true, store });
  } catch (error) {
    console.error('Error fetching store by ID:', error);
    res.status(500).json({ error: 'Failed to fetch store details' });
  }
});

// 5. TOGGLE STORE ONLINE / OFFLINE
router.patch('/:storeId/online', async (req, res) => {
  try {
    const { storeId } = req.params;
    const { isOnline } = req.body;
    const updatedStore = await Store.findOneAndUpdate(
      { storeId },
      { $set: { isOnline: Boolean(isOnline) } },
      { new: true }
    );
    if (!updatedStore) {
      return res.status(404).json({ error: 'Store not found' });
    }
    console.log(`🏪 [Store Online Toggle] ${updatedStore.name} is now ${updatedStore.isOnline ? 'ONLINE' : 'OFFLINE'}`);
    res.status(200).json({ success: true, store: updatedStore });
  } catch (error) {
    console.error('Error toggling online status:', error);
    res.status(500).json({ error: 'Failed to update store online status' });
  }
});

// 5b. ADMIN APPROVE OR REJECT STORE
router.patch('/:storeId/status', async (req, res) => {
  try {
    const { storeId } = req.params;
    const { status, rejectionReason, verifiedBy, isOnline } = req.body;

    // Handle online toggle directly if passed without status change
    if (isOnline !== undefined && !status) {
      const updatedStore = await Store.findOneAndUpdate(
        { storeId },
        { $set: { isOnline: Boolean(isOnline) } },
        { new: true }
      );
      if (!updatedStore) return res.status(404).json({ error: 'Store not found' });
      return res.status(200).json({ success: true, store: updatedStore });
    }

    if (!['approved', 'rejected', 'pending'].includes(status)) {
      return res.status(400).json({
        error: "Invalid status. Must be 'approved', 'rejected', or 'pending'",
      });
    }

    if (status === 'rejected' && !rejectionReason) {
      return res.status(400).json({
        error: 'Please provide a rejectionReason when rejecting a store application',
      });
    }

    const updateFields = {
      status,
      rejectionReason: status === 'rejected' ? rejectionReason : '',
      verifiedAt: status === 'approved' ? new Date() : null,
      verifiedBy: verifiedBy || 'Municipal Authority',
    };

    const updatedStore = await Store.findOneAndUpdate(
      { storeId },
      { $set: updateFields },
      { new: true }
    );

    if (!updatedStore) {
      return res.status(404).json({ error: 'Store not found' });
    }

    console.log(
      `🏛️ [Admin Action] Store ${updatedStore.name} (${storeId}) status updated to: ${status.toUpperCase()}`
    );

    res.status(200).json({
      success: true,
      message: `Store ${status} successfully! 🎉`,
      store: updatedStore,
    });
  } catch (error) {
    console.error('Error updating store status:', error);
    res.status(500).json({ error: 'Failed to update store status', details: error.message });
  }
});

module.exports = router;
