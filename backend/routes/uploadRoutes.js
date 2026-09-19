const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const router = express.Router();

const uploadDir = path.join(__dirname, '..', 'uploads');
const profileDir = path.join(uploadDir, 'profile_images');
const storeDir = path.join(uploadDir, 'store_images');
const productDir = path.join(uploadDir, 'product_images');

[uploadDir, profileDir, storeDir, productDir].forEach((dir) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// 1. General Upload Storage (Handles complaint, store, and product prefixes)
const generalStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const type = req.query.type || req.body.type || '';
    if (type === 'store' || type === 'storeimg') {
      return cb(null, uploadDir);
    }
    if (type === 'product' || type === 'productimg') {
      return cb(null, uploadDir);
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    const type = (req.query.type || req.body.type || '').toLowerCase();
    let prefix = 'complaint-';
    if (type === 'store' || type === 'storeimg') {
      prefix = 'storeimg-';
    } else if (type === 'product' || type === 'productimg') {
      prefix = 'productimg-';
    }
    cb(null, prefix + Date.now() + ext);
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

// 3. Store Image Dedicated Storage
const storeStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'storeimg-' + Date.now() + ext);
  },
});

// 4. Product Image Dedicated Storage
const productStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, 'productimg-' + Date.now() + ext);
  },
});

const uploadGeneral = multer({ storage: generalStorage });
const uploadProfile = multer({ storage: profileStorage });
const uploadStore = multer({ storage: storeStorage });
const uploadProduct = multer({ storage: productStorage });

// POST /api/upload - Upload with optional query ?type=store or ?type=product
router.post('/', uploadGeneral.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No image uploaded' });
  const host = req.get('host');
  const imageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
  console.log(`📸 [Image Uploaded] Filename: ${req.file.filename} -> ${imageUrl}`);
  res.status(200).json({ success: true, imageUrl, filename: req.file.filename });
});

// POST /api/upload/store - Dedicated Store Image Upload
router.post('/store', uploadStore.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No store image uploaded' });
  const host = req.get('host');
  const imageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
  console.log(`🏪 [Store Image Uploaded] Filename: ${req.file.filename} -> ${imageUrl}`);
  res.status(200).json({ success: true, imageUrl, filename: req.file.filename });
});

// POST /api/upload/product - Dedicated Product Image Upload
router.post('/product', uploadProduct.single('image'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No product image uploaded' });
  const host = req.get('host');
  const imageUrl = `${req.protocol}://${host}/uploads/${req.file.filename}`;
  console.log(`📦 [Product Image Uploaded] Filename: ${req.file.filename} -> ${imageUrl}`);
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
