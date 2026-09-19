const mongoose = require('mongoose');

const ProductSchema = new mongoose.Schema(
  {
    productId: { type: String, required: true, unique: true },
    storeId: { type: String, required: true, index: true },
    title: { type: String, required: true, trim: true },
    category: { type: String, default: 'general', trim: true },
    unit: { type: String, default: '1 Units', trim: true },
    price: { type: Number, required: true },
    originalPrice: { type: Number, default: 0 },
    discountPercentage: { type: String, default: '' },
    stock: { type: Number, default: 10 },
    isAvailable: { type: Boolean, default: true },
    image: { type: String, default: '' },
    description: { type: String, default: '', trim: true },
    
    // Detailed Citizen App Specifications & Highlights
    brand: { type: String, default: 'Unbranded', trim: true },
    packOf: { type: String, default: '1', trim: true },
    type: { type: String, default: '', trim: true },
    shelfLife: { type: String, default: '7 Days', trim: true },
    formFactor: { type: String, default: 'Whole', trim: true },
    origin: { type: String, default: 'India', trim: true },
    
    // Government Subsidy Fields (for Ration / PDS / Essential stores)
    isSubsidized: { type: Boolean, default: false },
    subsidyLimit: { type: String, default: '', trim: true },
  },
  {
    timestamps: true,
  }
);

ProductSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: function (doc, ret) {
    delete ret._id;
  },
});

module.exports = mongoose.model('Product', ProductSchema);
