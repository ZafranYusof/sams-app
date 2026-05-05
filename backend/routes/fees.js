const express = require('express');
const Fee = require('../models/Fee');
const Payment = require('../models/Payment');
const { auth, adminOnly } = require('../middleware/auth');
const crypto = require('crypto');

const router = express.Router();

// Get my fees
router.get('/my', auth, async (req, res) => {
  try {
    const fees = await Fee.find({ student: req.user.id }).sort({ createdAt: -1 });
    res.json(fees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get fee details
router.get('/:id', auth, async (req, res) => {
  try {
    const fee = await Fee.findById(req.params.id);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    const payments = await Payment.find({ fee: req.params.id }).sort({ paidAt: -1 });
    res.json({ fee, payments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Make payment (FPX simulation)
router.post('/pay', auth, async (req, res) => {
  try {
    const { feeId, amount, bank } = req.body;
    
    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    if (fee.status === 'paid') return res.status(400).json({ error: 'Already fully paid' });

    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();
    
    const payment = new Payment({
      student: req.user.id,
      fee: feeId,
      amount,
      method: 'fpx',
      bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    fee.paidAmount += amount;
    if (fee.paidAmount >= fee.totalAmount) {
      fee.status = 'paid';
    } else {
      fee.status = 'partial';
    }
    await fee.save();

    res.status(201).json({ payment, fee });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get payment history
router.get('/payments/history', auth, async (req, res) => {
  try {
    const payments = await Payment.find({ student: req.user.id }).populate('fee').sort({ paidAt: -1 });
    res.json(payments);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Create fee for student
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const fee = new Fee(req.body);
    fee.totalAmount = fee.items.reduce((sum, item) => sum + item.amount, 0);
    await fee.save();
    res.status(201).json(fee);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Get all fees
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    const fees = await Fee.find().populate('student', 'name studentId');
    res.json(fees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
