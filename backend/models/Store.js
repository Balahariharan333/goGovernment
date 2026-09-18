const mongoose = require('mongoose');

const StoreSchema = new mongoose.Schema(
  {
    storeId: { type: String, required: true, unique: true },
    ownerId: { type: String, default: '', index: true },
    name: { type: String, required: true, trim: true },
    ownerName: { type: String, required: true, trim: true },
    phone: { type: String, required: true, index: true },
    email: { type: String, default: '', trim: true },
    category: {
      type: String,
      required: true,
      enum: ['ration', 'medical', 'vegstore', 'supermarket', 'general', 'dairy'],
      default: 'general',
    },
    licenseNumber: { type: String, default: '', trim: true },
    address: { type: String, required: true, trim: true },
    pincode: { type: String, default: '' },
    location: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
    },
    storeImage: { type: String, default: '' },
    licenseDoc: { type: String, default: '' },
    bankDetails: {
      bankName: { type: String, default: '' },
      accountNumber: { type: String, default: '' },
      ifscCode: { type: String, default: '' },
      accountHolderName: { type: String, default: '' },
    },
    status: {
      type: String,
      enum: ['pending', 'approved', 'rejected'],
      default: 'pending',
      index: true,
    },
    rejectionReason: { type: String, default: '' },
    timings: {
      open: { type: String, default: '08:00 AM' },
      close: { type: String, default: '09:00 PM' },
    },
    isOnline: { type: Boolean, default: true },
    rating: { type: Number, default: 4.5 },
    verifiedAt: { type: Date },
    verifiedBy: { type: String, default: '' },
  },
  {
    timestamps: true,
  }
);

StoreSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: function (doc, ret) {
    delete ret._id;
  },
});

module.exports = mongoose.model('Store', StoreSchema);
