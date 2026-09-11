const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, unique: true },
    phone: { type: String, required: true, unique: true },
    userName: { type: String, default: '' },
    email: { type: String, default: '' },
    profileImage: { type: String, default: '' },
    otp: { type: String, default: '' },
    otpExpires: { type: Date },
  },
  {
    timestamps: true,
  }
);

UserSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: function (doc, ret) {
    delete ret._id;
    delete ret.otp; // Never expose OTP in response
    delete ret.otpExpires;
  },
});

module.exports = mongoose.model('User', UserSchema);
