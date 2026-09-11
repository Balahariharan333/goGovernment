const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

const uploadDir = path.join(__dirname, '..', 'uploads');
const profileDir = path.join(uploadDir, 'profile_images');

if (!fs.existsSync(profileDir)) {
  fs.mkdirSync(profileDir, { recursive: true });
}

// 1. Complaint Storage (directly in uploads/)
const complaintStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'complaint-' + Date.now() + ext);
  },
});

// 2. Profile Storage (in uploads/profile_images/)
const profileStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, profileDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'profile-' + Date.now() + ext);
  },
});

const uploadComplaint = multer({ storage: complaintStorage });
const uploadProfile = multer({ storage: profileStorage });

// POST /api/upload - Upload Complaint Photo
router.post('/', uploadComplaint.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No image uploaded' });
  const host = req.get('host');
  const imageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
  res.status(200).json({ success: true, imageUrl, filename: req.file.filename });
});

// POST /api/upload/profile - Upload User Profile Photo
router.post('/profile', uploadProfile.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No profile image uploaded' });
  const host = req.get('host');
  const imageUrl = `${req.protocol}://${host}/uploads/profile_images/${req.file.filename}`;
  res.status(200).json({ success: true, imageUrl, filename: req.file.filename });
});

module.exports = router;
