const express = require('express');
const mongoose = require('mongoose');
const Payment = require('../models/Payment');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /api/payments/:studentId - view payment history
router.get('/:studentId', auth, async (req, res) => {
  try {
    const user = await User.findOne({ studentId: req.params.studentId });
    if (!user) return res.json({ payments: [] });
    // Authorization: only own data or admin
    if (user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    
    const payments = await Payment.find({ student: user._id }).populate('fee').sort({ paidAt: -1 });
    res.json({ payments });
  } catch (err) {
    console.error('Get payments error:', err.message);
    res.status(500).json({ error: 'Failed to fetch payments' });
  }
});

// POST /api/payments - make a payment
router.post('/', auth, async (req, res) => {
  try {
    const { fee_id, feeId, amount, bank, student_id } = req.body;
    const crypto = require('crypto');
    const Fee = require('../models/Fee');

    const targetFeeId = fee_id || feeId;
    if (!targetFeeId || !mongoose.Types.ObjectId.isValid(targetFeeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    const fee = await Fee.findById(targetFeeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    // Authorization: only fee owner can pay
    if (fee.student.toString() !== req.user.id) {
      return res.status(403).json({ error: 'You can only pay your own fees' });
    }
    if (fee.status === 'paid') {
      return res.status(400).json({ error: 'Fee already fully paid' });
    }

    // Cap amount at remaining balance to prevent overpayment
    const remaining = fee.totalAmount - fee.paidAmount;
    const actualAmount = Math.min(amount, remaining);

    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();

    const payment = new Payment({
      student: req.user.id,
      fee: targetFeeId,
      amount: actualAmount,
      method: 'fpx',
      bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    // Allocate payment to fee items in priority order:
    // 1. Yuran Pengajian (tuition) — first, so student becomes "active"
    // 2. Yuran Asrama (facility) — second
    // 3. Other items (insurance, activity, etc.)
    const ITEM_PRIORITY = { tuition: 1, facility: 2, insurance: 3, activity: 4, other: 5 };
    const sortedItems = [...fee.items].sort((a, b) =>
      (ITEM_PRIORITY[a.category] || 99) - (ITEM_PRIORITY[b.category] || 99)
    );

    let amountToAllocate = actualAmount;
    for (const item of sortedItems) {
      if (amountToAllocate <= 0) break;
      const itemRemaining = item.amount - (item.paidAmount || 0);
      if (itemRemaining <= 0) continue;
      const apply = Math.min(amountToAllocate, itemRemaining);
      // Find the actual item in fee.items by _id and update it
      const targetItem = fee.items.id(item._id);
      if (targetItem) {
        targetItem.paidAmount = (targetItem.paidAmount || 0) + apply;
        if (targetItem.paidAmount >= targetItem.amount) {
          targetItem.paidAt = new Date();
        }
      }
      amountToAllocate -= apply;
    }

    // The pre('save') hook will auto-recompute paidAmount + status from items
    await fee.save();

    res.status(201).json({ payment, fee, txn_id: transactionId, status: 'success' });
  } catch (err) {
    console.error('Payment error:', err.message);
    res.status(500).json({ error: 'Payment failed. Please try again.' });
  }
});

module.exports = router;
