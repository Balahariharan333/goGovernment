const express = require('express');
const router = express.Router();
const User = require('../models/User');
const WalletTransaction = require('../models/WalletTransaction');

// 1. GET WALLET DETAILS & LEDGER HISTORY
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    // Support finding by userId OR phone
    let user = await User.findOne({
      $or: [{ userId }, { phone: userId }],
    });

    if (!user) {
      // Auto-create minimal citizen profile if non-existent yet
      user = new User({
        userId,
        phone: userId,
        role: 'citizen',
        walletBalance: 0,
        coinsBalance: 0,
      });
      await user.save();
    }

    const transactions = await WalletTransaction.find({ userId: user.userId })
      .sort({ createdAt: -1 })
      .limit(50);

    res.status(200).json({
      success: true,
      userId: user.userId,
      walletBalance: user.walletBalance || 0,
      coinsBalance: user.coinsBalance || 0,
      transactions,
    });
  } catch (error) {
    console.error('Error fetching wallet details:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch wallet details' });
  }
});

// 2. TOP UP WALLET
router.post('/topup', async (req, res) => {
  try {
    const { userId, amount, paymentMethod, referenceId } = req.body;
    const numAmount = Number(amount);

    if (!userId || isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid userId and positive amount are required',
      });
    }

    const resolvedMethod = paymentMethod || 'UPI';

    // Atomically increment user walletBalance
    const updatedUser = await User.findOneAndUpdate(
      { $or: [{ userId }, { phone: userId }] },
      { $inc: { walletBalance: numAmount } },
      { new: true, upsert: true }
    );

    const txId = 'TOP_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900);
    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

    const transaction = new WalletTransaction({
      transactionId: txId,
      userId: updatedUser.userId,
      amount: numAmount,
      type: 'credit',
      category: 'topup',
      paymentMethod: resolvedMethod,
      title: 'Wallet Top-up',
      subtitle: `Added via ${resolvedMethod} · ${dateStr}`,
      balanceAfter: updatedUser.walletBalance,
      status: 'success',
      metadata: {
        referenceId: referenceId || `REF_${Date.now()}`,
      },
    });

    await transaction.save();

    console.log(`💳 [Wallet Top-up] ${updatedUser.userId} credited +₹${numAmount} via ${resolvedMethod}. New balance: ₹${updatedUser.walletBalance}`);

    res.status(200).json({
      success: true,
      message: `Successfully topped up ₹${numAmount} to wallet`,
      walletBalance: updatedUser.walletBalance,
      coinsBalance: updatedUser.coinsBalance || 0,
      transaction,
    });
  } catch (error) {
    console.error('Error topping up wallet:', error);
    res.status(500).json({ success: false, error: 'Failed to process wallet top-up' });
  }
});

// 3. ATOMICALLY DEDUCT WALLET FOR ORDER PAYMENT
router.post('/deduct', async (req, res) => {
  try {
    const { userId, amount, orderId, title, subtitle } = req.body;
    const numAmount = Number(amount);

    if (!userId || isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid userId and positive amount are required',
      });
    }

    // Atomic deduction: only matches if walletBalance is >= amount
    const updatedUser = await User.findOneAndUpdate(
      {
        $or: [{ userId }, { phone: userId }],
        walletBalance: { $gte: numAmount },
      },
      { $inc: { walletBalance: -numAmount } },
      { new: true }
    );

    if (!updatedUser) {
      // Find current user balance to report in error
      const currentUser = await User.findOne({ $or: [{ userId }, { phone: userId }] });
      const currentBal = currentUser ? currentUser.walletBalance : 0;
      return res.status(400).json({
        success: false,
        code: 'INSUFFICIENT_BALANCE',
        error: `Insufficient wallet balance. Required: ₹${numAmount}, Current: ₹${currentBal}`,
        walletBalance: currentBal,
      });
    }

    const txId = 'PAY_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900);
    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

    const transaction = new WalletTransaction({
      transactionId: txId,
      userId: updatedUser.userId,
      amount: -numAmount,
      type: 'debit',
      category: 'order_payment',
      paymentMethod: 'Wallet Account',
      orderId: orderId || '',
      title: title || 'Order Payment',
      subtitle: subtitle || `Paid for order ${orderId ? '#' + orderId : ''} · ${dateStr}`,
      balanceAfter: updatedUser.walletBalance,
      status: 'success',
    });

    await transaction.save();

    console.log(`💳 [Wallet Deduct] ${updatedUser.userId} deducted -₹${numAmount} for order ${orderId}. Remaining: ₹${updatedUser.walletBalance}`);

    res.status(200).json({
      success: true,
      message: `Deducted ₹${numAmount} from wallet for order payment`,
      walletBalance: updatedUser.walletBalance,
      transaction,
    });
  } catch (error) {
    console.error('Error deducting from wallet:', error);
    res.status(500).json({ success: false, error: 'Failed to process wallet payment' });
  }
});

// 4. REFUND CANCELLED ORDER TO WALLET
router.post('/refund', async (req, res) => {
  try {
    const { userId, amount, orderId, reason } = req.body;
    const numAmount = Number(amount);

    if (!userId || isNaN(numAmount) || numAmount <= 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid userId and positive amount are required',
      });
    }

    // Atomically refund back to user wallet
    const updatedUser = await User.findOneAndUpdate(
      { $or: [{ userId }, { phone: userId }] },
      { $inc: { walletBalance: numAmount } },
      { new: true, upsert: true }
    );

    const txId = 'REF_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900);
    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

    const transaction = new WalletTransaction({
      transactionId: txId,
      userId: updatedUser.userId,
      amount: numAmount,
      type: 'credit',
      category: 'order_refund',
      paymentMethod: 'Wallet Refund',
      orderId: orderId || '',
      title: 'Order Refund',
      subtitle: `Refund for cancelled order ${orderId ? '#' + orderId : ''} · ${dateStr}`,
      balanceAfter: updatedUser.walletBalance,
      status: 'success',
      metadata: { reason: reason || 'Order cancelled before packing' },
    });

    await transaction.save();

    console.log(`💳 [Wallet Refund] ${updatedUser.userId} refunded +₹${numAmount} for cancelled order ${orderId}. New balance: ₹${updatedUser.walletBalance}`);

    res.status(200).json({
      success: true,
      message: `Successfully refunded ₹${numAmount} to wallet`,
      walletBalance: updatedUser.walletBalance,
      transaction,
    });
  } catch (error) {
    console.error('Error processing wallet refund:', error);
    res.status(500).json({ success: false, error: 'Failed to process wallet refund' });
  }
});

// 5. REDEEM REWARD COINS TO WALLET CASH (100 coins = ₹1)
router.post('/redeem-coins', async (req, res) => {
  try {
    const { userId, coins } = req.body;
    const numCoins = Number(coins);

    if (!userId || isNaN(numCoins) || numCoins < 100) {
      return res.status(400).json({
        success: false,
        error: 'Minimum 100 reward coins required to redeem (100 coins = ₹1)',
      });
    }

    const cashAmount = Math.floor(numCoins / 100);
    const actualCoinsToDeduct = cashAmount * 100;

    // Atomically deduct coins and credit wallet
    const updatedUser = await User.findOneAndUpdate(
      {
        $or: [{ userId }, { phone: userId }],
        coinsBalance: { $gte: actualCoinsToDeduct },
      },
      {
        $inc: {
          coinsBalance: -actualCoinsToDeduct,
          walletBalance: cashAmount,
        },
      },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(400).json({
        success: false,
        error: 'Insufficient reward coins to redeem',
      });
    }

    const txId = 'COIN_' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900);
    const now = new Date();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const dateStr = `${months[now.getMonth()]} ${now.getDate()} · ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;

    const transaction = new WalletTransaction({
      transactionId: txId,
      userId: updatedUser.userId,
      amount: cashAmount,
      type: 'credit',
      category: 'reward_redemption',
      paymentMethod: 'Reward Coins',
      title: 'Coins Redeemed',
      subtitle: `${actualCoinsToDeduct} coins converted to cash · ${dateStr}`,
      balanceAfter: updatedUser.walletBalance,
      status: 'success',
      metadata: { coinsRedeemed: actualCoinsToDeduct },
    });

    await transaction.save();

    console.log(`🪙 [Coins Redeemed] ${updatedUser.userId} converted ${actualCoinsToDeduct} coins to ₹${cashAmount}. New wallet balance: ₹${updatedUser.walletBalance}`);

    res.status(200).json({
      success: true,
      message: `Successfully converted ${actualCoinsToDeduct} coins into ₹${cashAmount} wallet cash`,
      walletBalance: updatedUser.walletBalance,
      coinsBalance: updatedUser.coinsBalance,
      transaction,
    });
  } catch (error) {
    console.error('Error redeeming coins:', error);
    res.status(500).json({ success: false, error: 'Failed to redeem coins' });
  }
});

module.exports = router;
