const mongoose = require('mongoose');

const SurveyAnswerSchema = new mongoose.Schema({
  question: { type: String, required: true },
  answer: { type: String, required: true },
});

const FeedbackSchema = new mongoose.Schema(
  {
    feedbackId: { type: String, required: true, unique: true },
    userId: { type: String, default: '' },
    userName: { type: String, default: 'Anonymous Citizen' },
    phone: { type: String, default: '' },
    type: { type: String, enum: ['survey', 'app_rating', 'general'], default: 'survey' },
    rating: { type: Number, default: 5, min: 1, max: 5 },
    comments: { type: String, default: '' },

    surveyAnswers: [SurveyAnswerSchema],
  },
  {
    timestamps: true,
  }
);

FeedbackSchema.set('toJSON', {
  virtuals: true,
  versionKey: false,
  transform: function (doc, ret) {
    ret._mongoId = ret._id;
    delete ret._id;
  },
});

module.exports = mongoose.model('Feedback', FeedbackSchema);
