const express = require('express');
const router = express.Router();
const User = require('../models/User');

// 1. SEND OTP API
router.post('/send-otp', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    // Auto-generate random 4-digit OTP (1000 to 9999)
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const otpExpires = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes validity

    // Upsert temporary OTP against phone number
    await User.findOneAndUpdate(
      { phone },
      {
        $setOnInsert: {
          userId: 'USER_' + Date.now().toString().slice(-6),
        },
        $set: { otp, otpExpires },
      },
      { upsert: true, new: true }
    );

    console.log(`📲 [SMS Gateway] OTP sent to ${phone}: ${otp}`);

    res.status(200).json({
      success: true,
      message: `OTP sent successfully to ${phone}`,
      otp: otp, // Auto-generated OTP returned for testing
    });
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({ error: 'Failed to send OTP', details: error.message });
  }
});

// 2. VERIFY OTP API (Checks isNewUser vs Existing User)
router.post('/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ error: 'Phone and OTP are required' });
    }

    const user = await User.findOne({ phone });

    if (!user) {
      return res.status(404).json({ error: 'User not found. Please request OTP first.' });
    }

    // Check expiration
    if (user.otpExpires && new Date() > user.otpExpires) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // Verify auto-generated OTP
    if (user.otp !== otp) {
      return res.status(400).json({ error: 'Invalid OTP code. Please enter the correct OTP.' });
    }

    // Clear OTP after successful verification
    user.otp = '';
    if (req.body.role && ['citizen', 'store_owner', 'admin', 'rider', 'field_worker'].includes(req.body.role)) {
      user.role = req.body.role;
    }
    await user.save();

    // Existing user: Has filled their userName previously
    const hasProfile = Boolean(user.userName && user.userName.trim().length > 0);
    const isNewUser = !hasProfile;

    res.status(200).json({
      success: true,
      message: isNewUser ? 'New user! Please setup profile.' : 'Welcome back!',
      isNewUser: isNewUser,
      userId: user.userId,
      role: user.role || 'citizen',
      user: user,
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({ error: 'Failed to verify OTP', details: error.message });
  }
});

// 3. UPDATE / SAVE PROFILE API (Name, Email, Profile Pic)
router.post('/profile', async (req, res) => {
  try {
    const { userId, userName, email, profileImage } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId is required' });
    }

    const updatedUser = await User.findOneAndUpdate(
      { userId },
      {
        $set: {
          userId,
          ...(userName && { userName }),
          ...(email && { email }),
          ...(profileImage && { profileImage }),
        },
      },
      { new: true, upsert: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully 🎉',
      user: updatedUser,
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Failed to update profile', details: error.message });
  }
});

// 4. GET USER PROFILE BY USER ID
router.get('/profile/:userId', async (req, res) => {
  try {
    const user = await User.findOne({ userId: req.params.userId });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({ error: 'Failed to fetch profile', details: error.message });
  }
});

// 5. SEND PHONE UPDATE OTP
router.post('/send-phone-update-otp', async (req, res) => {
  try {
    const { userId, newPhone, currentPhone } = req.body;

    if (!newPhone) {
      return res.status(400).json({ error: 'newPhone is required' });
    }

    const cleanNewPhone = newPhone.toString().trim().replace(/[^0-9]/g, '').slice(-10);
    const cleanCurrentPhone = currentPhone
      ? currentPhone.toString().trim().replace(/[^0-9]/g, '').slice(-10)
      : null;

    // Find user by userId OR current registered phone
    const userQuery = [];
    if (userId) userQuery.push({ userId });
    if (cleanCurrentPhone) userQuery.push({ phone: cleanCurrentPhone });

    if (userQuery.length === 0) {
      return res.status(400).json({ error: 'userId or currentPhone is required to identify the user' });
    }

    const user = await User.findOne({ $or: userQuery });
    if (!user) {
      return res.status(404).json({ error: 'User account not found' });
    }

    // Check if new phone is already registered by another user
    const existing = await User.findOne({
      phone: cleanNewPhone,
      userId: { $ne: user.userId },
    });

    if (existing) {
      return res.status(400).json({
        error: 'This phone number is already registered with another account.',
      });
    }

    // Generate random 4-digit OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const otpExpires = new Date(Date.now() + 5 * 60 * 1000);

    user.pendingPhone = cleanNewPhone;
    user.pendingPhoneOtp = otp;
    user.pendingPhoneOtpExpires = otpExpires;
    await user.save();

    console.log(`📲 [SMS Gateway] Phone Update OTP for ${cleanNewPhone}: ${otp}`);

    res.status(200).json({
      success: true,
      message: `OTP sent successfully to ${cleanNewPhone}`,
      otp: otp, // Returned for testing
    });
  } catch (error) {
    console.error('Error sending phone update OTP:', error);
    res.status(500).json({ error: 'Failed to send OTP', details: error.message });
  }
});

// 6. VERIFY PHONE UPDATE OTP & UPDATE PHONE
router.post('/verify-phone-update-otp', async (req, res) => {
  try {
    const { userId, newPhone, currentPhone, otp } = req.body;

    if (!newPhone || !otp) {
      return res.status(400).json({ error: 'newPhone and otp are required' });
    }

    const cleanNewPhone = newPhone.toString().trim().replace(/[^0-9]/g, '').slice(-10);
    const cleanCurrentPhone = currentPhone
      ? currentPhone.toString().trim().replace(/[^0-9]/g, '').slice(-10)
      : null;

    const userQuery = [];
    if (userId) userQuery.push({ userId });
    if (cleanCurrentPhone) userQuery.push({ phone: cleanCurrentPhone });

    const user = await User.findOne({ $or: userQuery });
    if (!user) {
      return res.status(404).json({ error: 'User account not found' });
    }

    // Check pending phone match
    if (user.pendingPhone !== cleanNewPhone) {
      return res.status(400).json({ error: 'Phone number mismatch. Please request OTP again.' });
    }

    // Check expiry
    if (user.pendingPhoneOtpExpires && new Date() > user.pendingPhoneOtpExpires) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    // Verify OTP
    if (user.pendingPhoneOtp !== otp.toString().trim()) {
      return res.status(400).json({ error: 'Invalid OTP code. Please enter the correct OTP.' });
    }

    // Update phone number
    user.phone = cleanNewPhone;
    user.pendingPhone = '';
    user.pendingPhoneOtp = '';
    user.pendingPhoneOtpExpires = null;
    await user.save();

    console.log(`✅ Phone number updated successfully for user ${user.userId} to ${cleanNewPhone}`);

    res.status(200).json({
      success: true,
      message: 'Phone number updated successfully',
      phone: cleanNewPhone,
      user: user,
    });
  } catch (error) {
    console.error('Error verifying phone update OTP:', error);
    res.status(500).json({ error: 'Failed to update phone number', details: error.message });
  }
});

module.exports = router;
