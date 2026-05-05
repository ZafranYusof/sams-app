const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  fee: { type: mongoose.Schema.Types.ObjectId, ref: 'Fee', required: true },
  amount: { type: Number, required: true },
  method: { type: String, enum: ['fpx', 'card', 'cash', 'scholarship'], default: 'fpx' },
  transactionId: { type: String, unique: true },
  bank: { type: String },
  status: { type: String, enum: ['pending', 'success', 'failed', 'refunded'], default: 'pending' },
  paidAt: { type: Date, default: Date.now },
  receipt: { type: String }
});

module.exports = mongoose.model('Payment', paymentSchema);
