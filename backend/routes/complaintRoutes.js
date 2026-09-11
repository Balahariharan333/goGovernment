const express = require('express');
const router = express.Router();
const Complaint = require('../models/Complaint');

// 1. GET ALL COMPLAINTS (Sorted by newest first)
router.get('/', async (req, res) => {
  try {
    const complaints = await Complaint.find().sort({ createdAt: -1 });
    res.status(200).json(complaints);
  } catch (error) {
    console.error('Error fetching complaints:', error);
    res.status(500).json({ error: 'Failed to fetch complaints' });
  }
});

// 2. GET SINGLE COMPLAINT BY COMPLAINT ID
router.get('/:complaintId', async (req, res) => {
  try {
    const complaint = await Complaint.findOne({ complaintId: req.params.complaintId });
    if (!complaint) {
      return res.status(404).json({ error: 'Complaint not found' });
    }
    res.status(200).json(complaint);
  } catch (error) {
    console.error('Error fetching complaint:', error);
    res.status(500).json({ error: 'Failed to fetch complaint' });
  }
});

// 3. GET COMPLAINTS BY USER ID
router.get('/user/:userId', async (req, res) => {
  try {
    const userComplaints = await Complaint.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.status(200).json(userComplaints);
  } catch (error) {
    console.error('Error fetching user complaints:', error);
    res.status(500).json({ error: 'Failed to fetch user complaints' });
  }
});

// 4. SUBMIT A NEW COMPLAINT
router.post('/', async (req, res) => {
  try {
    const data = req.body;

    if (!data.complaintId) {
      data.complaintId = 'CMP' + Date.now().toString().slice(-6);
    }
    data.id = data.complaintId;

    if (!data.userId) {
      data.userId = 'USER_GUEST';
    }
    if (!data.date) {
      const now = new Date();
      data.date =
        now.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) +
        ', ' +
        now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });
    }

    const complaint = await Complaint.findOneAndUpdate(
      { complaintId: data.complaintId },
      { $set: data },
      { new: true, upsert: true }
    );

    res.status(201).json({ success: true, complaint });
  } catch (error) {
    console.error('Error submitting complaint:', error);
    res.status(500).json({ error: 'Failed to submit complaint', details: error.message });
  }
});

// 5. TOGGLE LIKE (Like / Unlike by userId or citizenId)
router.post('/:complaintId/like', async (req, res) => {
  try {
    const { complaintId } = req.params;
    const userId = req.body.userId || req.body.citizenId;
    const { isCurrentlyLiked } = req.body;

    if (!userId) {
      return res.status(400).json({ error: 'userId or citizenId is required' });
    }

    const complaint = await Complaint.findOne({ complaintId });
    if (!complaint) {
      return res.status(404).json({ error: 'Complaint not found' });
    }

    if (!isCurrentlyLiked) {
      if (!complaint.likedBy.includes(userId)) {
        complaint.likedBy.push(userId);
        complaint.likesCount = complaint.likedBy.length;
      }
    } else {
      complaint.likedBy = complaint.likedBy.filter((uid) => uid !== userId);
      complaint.likesCount = complaint.likedBy.length;
    }

    await complaint.save();
    res.status(200).json({
      success: true,
      message: isCurrentlyLiked ? 'Unliked successfully' : 'Liked successfully 👍',
      complaintId: complaint.complaintId,
      likesCount: complaint.likesCount,
      likedBy: complaint.likedBy,
      complaint: complaint,
    });
  } catch (error) {
    console.error('Error toggling like:', error);
    res.status(500).json({ error: 'Failed to toggle like' });
  }
});

// 6. ADD COMMENT TO COMPLAINT
router.post('/:complaintId/comment', async (req, res) => {
  try {
    const { complaintId } = req.params;
    const userId = req.body.userId || req.body.citizenId;
    const { userName, comment } = req.body;

    if (!comment || !userId) {
      return res.status(400).json({ error: 'comment and userId/citizenId are required' });
    }

    const now = new Date();
    const formattedDate =
      now.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' }) +
      ', ' +
      now.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true });

    const newComment = {
      userName: userName || 'Citizen',
      comment,
      userId,
      date: formattedDate,
      timestamp: Date.now(),
    };

    const updated = await Complaint.findOneAndUpdate(
      { complaintId },
      { $push: { comments: newComment } },
      { new: true }
    );

    if (!updated) {
      return res.status(404).json({ error: 'Complaint not found' });
    }

    res.status(200).json({
      success: true,
      message: 'Comment added successfully 💬',
      complaintId: updated.complaintId,
      comments: updated.comments,
      complaint: updated,
    });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ error: 'Failed to add comment' });
  }
});

module.exports = router;
