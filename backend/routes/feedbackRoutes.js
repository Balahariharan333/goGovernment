const express = require('express');
const router = express.Router();
const Feedback = require('../models/Feedback');

// 1. SUBMIT CITIZEN FEEDBACK / SURVEY
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      userName,
      phone,
      type = 'survey',
      rating = 5,
      comments = '',
      surveyAnswers = [],
    } = req.body;

    const feedbackId = 'FB-' + Date.now().toString().slice(-6) + Math.floor(100 + Math.random() * 900);

    const newFeedback = new Feedback({
      feedbackId,
      userId: userId || 'USER_GUEST',
      userName: userName || 'Citizen',
      phone: phone || '',
      type,
      rating: Number(rating) || 5,
      comments: comments ? comments.trim() : '',
      surveyAnswers: Array.isArray(surveyAnswers) ? surveyAnswers : [],
    });

    const saved = await newFeedback.save();

    // Broadcast live to connected admin clients via Socket.io
    const io = req.app.get('io');
    if (io) {
      io.emit('new_feedback', saved);
    }

    console.log(`💬 [Feedback Received] [${type}] from ${userName || 'Citizen'} (${phone || 'No phone'}): ${rating}★`);

    res.status(201).json({
      success: true,
      message: 'Thank you! Your feedback has been recorded.',
      feedback: saved,
    });
  } catch (error) {
    console.error('Error saving feedback:', error);
    res.status(500).json({ success: false, error: 'Failed to submit feedback', details: error.message });
  }
});

// 2. GET ALL FEEDBACK (Admin Portal with Search & Filters)
router.get('/', async (req, res) => {
  try {
    const { type, rating, search } = req.query;
    const filter = {};

    if (type && type !== 'all') {
      filter.type = type;
    }

    if (rating && rating !== 'all') {
      filter.rating = Number(rating);
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      filter.$or = [
        { userName: { $regex: q, $options: 'i' } },
        { phone: { $regex: q, $options: 'i' } },
        { comments: { $regex: q, $options: 'i' } },
        { feedbackId: { $regex: q, $options: 'i' } },
      ];
    }

    const feedbacks = await Feedback.find(filter).sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: feedbacks.length,
      feedbacks,
    });
  } catch (error) {
    console.error('Error fetching feedbacks:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch feedback list', details: error.message });
  }
});

// 3. GET FEEDBACK KPI STATS (Admin Dashboard Overview)
router.get('/stats', async (req, res) => {
  try {
    const all = await Feedback.find();

    const total = all.length;
    let totalScore = 0;
    let surveyCount = 0;
    let appRatingCount = 0;
    const ratingBreakdown = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };

    all.forEach((fb) => {
      const r = Math.round(fb.rating) || 5;
      if (ratingBreakdown[r] !== undefined) {
        ratingBreakdown[r]++;
      }
      totalScore += fb.rating || 5;

      if (fb.type === 'survey') surveyCount++;
      if (fb.type === 'app_rating') appRatingCount++;
    });

    const avgRating = total > 0 ? (totalScore / total).toFixed(1) : '5.0';

    res.status(200).json({
      success: true,
      stats: {
        total,
        avgRating: parseFloat(avgRating),
        surveyCount,
        appRatingCount,
        ratingBreakdown,
      },
    });
  } catch (error) {
    console.error('Error fetching feedback stats:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch feedback stats', details: error.message });
  }
});

module.exports = router;
