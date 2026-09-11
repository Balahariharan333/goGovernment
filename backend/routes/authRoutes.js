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
    await user.save();

    // Existing user: Has filled their userName previously
    const hasProfile = Boolean(user.userName && user.userName.trim().length > 0);
    const isNewUser = !hasProfile;

    res.status(200).json({
      success: true,
      message: isNewUser ? 'New user! Please setup profile.' : 'Welcome back!',
      isNewUser: isNewUser,
      userId: user.userId,
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

module.exports = router;
