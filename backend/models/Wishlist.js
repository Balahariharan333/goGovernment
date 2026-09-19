const mongoose = require('mongoose');

const WishlistItemSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  product: { type: Object, default: {} },
  addedAt: { type: Date, default: Date.now },
});

const WishlistSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, unique: true, index: true },
    items: [WishlistItemSchema],
  },
  {
    timestamps: true,
  }
);

WishlistSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: function (doc, ret) {
    delete ret._id;
  },
});

module.exports = mongoose.model('Wishlist', WishlistSchema);
