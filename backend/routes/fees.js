const express = require('express');
const mongoose = require('mongoose');
const Fee = require('../models/Fee');
const Payment = require('../models/Payment');
const { auth, adminOnly } = require('../middleware/auth');
const crypto = require('crypto');
const fcm = require('../services/fcmService');

const router = express.Router();

// Get my fees
router.get('/my', auth, async (req, res) => {
  try {
    const fees = await Fee.find({ student: req.user.id }).sort({ createdAt: -1 });
    res.json(fees);
  } catch (err) {
    console.error('Get my fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

// Get payment history (MUST be before /:studentId to avoid route conflict)
router.get('/payments/history', auth, async (req, res) => {
  try {
    const payments = await Payment.find({ student: req.user.id }).populate('fee').sort({ paidAt: -1 });
    res.json(payments);
  } catch (err) {
    console.error('Payment history error:', err.message);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
});

// Get fees by student ID (e.g. CB23109)
router.get('/:studentId', auth, async (req, res) => {
  try {
    const sid = req.params.studentId;
    // If it looks like a MongoDB ObjectId, find by _id
    if (/^[a-f0-9]{24}$/.test(sid)) {
      const fee = await Fee.findById(sid);
      if (!fee) return res.status(404).json({ error: 'Fee not found' });
      // Authorization: only owner or admin can view
      if (fee.student.toString() !== req.user.id && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Access denied' });
      }
      const payments = await Payment.find({ fee: sid }).sort({ paidAt: -1 });
      return res.json({ fee, payments });
    }
    // Otherwise find by studentId string
    const User = require('../models/User');
    const user = await User.findOne({ studentId: sid });
    if (!user) return res.json({ fees: [], summary: { total_due: 0, total_paid: 0, balance: 0 } });
    // Authorization: only own data or admin
    if (user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const fees = await Fee.find({ student: user._id }).sort({ createdAt: -1 });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ fees, summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    console.error('Get fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

// Get summary by student ID
router.get('/:studentId/summary', auth, async (req, res) => {
  try {
    const User = require('../models/User');
    const user = await User.findOne({ studentId: req.params.studentId });
    if (!user) return res.json({ summary: { total_due: 0, total_paid: 0, balance: 0 } });
    // Authorization: only own data or admin
    if (user._id.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const fees = await Fee.find({ student: user._id });
    const totalDue = fees.reduce((s, f) => s + f.totalAmount, 0);
    const totalPaid = fees.reduce((s, f) => s + f.paidAmount, 0);
    res.json({ summary: { total_due: totalDue, total_paid: totalPaid, balance: totalDue - totalPaid } });
  } catch (err) {
    console.error('Fee summary error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fee summary' });
  }
});

// Make payment (FPX simulation)
router.post('/pay', auth, async (req, res) => {
  try {
    const { feeId, amount, bank } = req.body;
    if (!feeId || !mongoose.Types.ObjectId.isValid(feeId)) {
      return res.status(400).json({ error: 'Invalid fee ID' });
    }
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }
    // BUG 5 FIX: Validate bank parameter
    const VALID_BANKS = [
      'Maybank', 'CIMB', 'Public Bank', 'RHB', 'Hong Leong',
      'AmBank', 'Bank Islam', 'Bank Rakyat', 'BSN', 'Affin Bank',
      'Alliance Bank', 'HSBC', 'Standard Chartered', 'OCBC', 'UOB',
      'Agrobank', 'Bank Muamalat', 'MBSB Bank', 'KFH',
    ];
    const trimmedBank = bank ? bank.trim() : '';
    if (trimmedBank && (trimmedBank.length > 50 || !VALID_BANKS.some(b => b.toLowerCase() === trimmedBank.toLowerCase()))) {
      return res.status(400).json({ error: 'Invalid bank name' });
    }

    const fee = await Fee.findById(feeId);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    // Authorization: fee owner or admin can pay
    if (fee.student.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'You can only pay your own fees' });
    }
    if (fee.status === 'paid') return res.status(400).json({ error: 'Already fully paid' });

    // [Bug #1-3 FIX] Atomic payment via MongoDB aggregation pipeline
    const transactionId = 'FPX' + crypto.randomBytes(8).toString('hex').toUpperCase();

    // BUG 1 FIX: Atomic condition check + pipeline prevents concurrent overpayment.
    // BUG 2 FIX: Item allocation computed atomically via $reduce inside the pipeline.
    // BUG 3 FIX: Status derived from new paidAmount (pre('save') doesn't fire on findOneAndUpdate).
    const updatedFee = await Fee.findOneAndUpdate(
      { _id: feeId, paidAmount: { $lt: fee.totalAmount }, status: { $ne: 'paid' } },
      [
        // Step 1: compute capped amount atomically based on current DB state
        { $set: { _payAmt: { $min: [amount, { $subtract: ['$totalAmount', '$paidAmount'] }] } } },
        // Step 2: apply payment + allocate to items + set status
        {
          $set: {
            paidAmount: { $add: ['$paidAmount', '$_payAmt'] },
            items: {
              $let: {
                vars: {
                  result: {
                    $reduce: {
                      input: '$items',
                      initialValue: { rem: '$_payAmt', items: [] },
                      in: {
                        $let: {
                          vars: {
                            unpaid: { $max: [0, { $subtract: ['$$this.amount', { $ifNull: ['$$this.paidAmount', 0] }] }] },
                            prevRem: '$$value.rem'
                          },
                          in: {
                            rem: { $max: [0, { $subtract: ['$$prevRem', { $min: ['$$unpaid', '$$prevRem'] }] }] },
                            items: {
                              $concatArrays: [
                                '$$value.items',
                                [{
                                  $mergeObjects: [
                                    '$$this',
                                    {
                                      paidAmount: {
                                        $add: [
                                          { $ifNull: ['$$this.paidAmount', 0] },
                                          { $min: ['$$unpaid', '$$prevRem'] }
                                        ]
                                      },
                                      paidAt: {
                                        $cond: {
                                          if: { $gt: [{ $min: ['$$unpaid', '$$prevRem'] }, 0] },
                                          then: '$$NOW',
                                          else: '$$this.paidAt'
                                        }
                                      }
                                    }
                                  ]
                                }]
                              ]
                            }
                          }
                        }
                      }
                    }
                  }
                },
                in: '$$result.items'
              }
            },
            status: {
              $switch: {
                branches: [
                  { case: { $gte: [{ $add: ['$paidAmount', '$_payAmt'] }, '$totalAmount'] }, then: 'paid' }
                ],
                default: 'partial'
              }
            }
          }
        },
        { $unset: '_payAmt' }
      ],
      { new: true }
    );

    if (!updatedFee) {
      return res.status(409).json({ error: 'Payment conflict — fee may already be fully paid' });
    }

    // Compute actual amount deducted (handles case where pipeline capped the amount)
    const actualAmount = updatedFee.paidAmount - fee.paidAmount;

    const payment = new Payment({
      student: req.user.id,
      fee: feeId,
      amount: actualAmount,
      method: 'fpx',
      bank: trimmedBank || bank,
      transactionId,
      status: 'success',
      receipt: `RCP-${Date.now()}`
    });
    await payment.save();

    res.status(201).json({ payment, fee: updatedFee });
  } catch (err) {
    console.error('Payment error:', err.message);
    res.status(500).json({ error: 'Payment failed. Please try again.' });
  }
});

// Admin: Create fee for student
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const User = require('../models/User');
    let { student, studentId, items, semester, academicYear, dueDate } = req.body;

    // Resolve studentId string to ObjectId
    if (!student && studentId) {
      const user = await User.findOne({ studentId });
      if (!user) return res.status(404).json({ error: `Student ${studentId} not found` });
      student = user._id;
    }
    if (!student) return res.status(400).json({ error: 'Student ID required' });
    if (!items || !items.length) return res.status(400).json({ error: 'Fee items required' });

    const totalAmount = items.reduce((sum, item) => sum + (item.amount || 0), 0);
    
    // Validate dueDate (must be future date)
    let parsedDueDate = dueDate ? new Date(dueDate) : new Date(Date.now() + 90 * 24 * 60 * 60 * 1000);
    if (dueDate && parsedDueDate < new Date()) {
      return res.status(400).json({ error: 'Due date must be in the future' });
    }
    
    const fee = new Fee({
      student,
      items,
      semester: semester || 1,
      academicYear: academicYear || '2025/2026',
      totalAmount,
      paidAmount: 0,
      status: 'unpaid',
      dueDate: parsedDueDate,
    });
    await fee.save();

    // Push notification to student (fire-and-forget)
    fcm.sendToUser(student.toString(), {
      title: 'New Fee Assigned',
      body: `RM${totalAmount.toFixed(2)} for semester ${semester || 1} ${academicYear || ''} — due ${fee.dueDate.toLocaleDateString('en-GB')}`,
      data: { type: 'new_fee', feeId: fee._id.toString() },
    }).catch(e => console.error('[push] new_fee:', e.message));

    res.status(201).json(fee);
  } catch (err) {
    console.error('Create fee error:', err.message);
    res.status(500).json({ error: 'Failed to create fee' });
  }
});

// Admin: Get all fees (with pagination)
router.get('/', auth, adminOnly, async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 100;
    const skip = (page - 1) * limit;
    
    const fees = await Fee.find().populate('student', 'name studentId').skip(skip).limit(limit).sort({ createdAt: -1 });
    const total = await Fee.countDocuments();
    res.json({ fees, total, page, pages: Math.ceil(total / limit) });
  } catch (err) {
    console.error('Get all fees error:', err.message);
    res.status(500).json({ error: 'Failed to fetch fees' });
  }
});

// Admin: Fix all fee item allocations (one-time migration)
router.post('/fix-items', auth, adminOnly, async (req, res) => {
  try {
    const fees = await Fee.find();
    let fixed = 0;
    for (const fee of fees) {
      const itemsPaid = fee.items.reduce((sum, i) => sum + (i.paidAmount || 0), 0);
      if (fee.paidAmount > 0 && itemsPaid === 0 && fee.items.length > 0) {
        await fee.save(); // pre-save hook will auto-allocate
        fixed++;
      }
    }
    res.json({ message: `Fixed ${fixed} fees`, total: fees.length });
  } catch (err) {
    console.error('Fix items error:', err.message);
    res.status(500).json({ error: 'Failed to fix items' });
  }
});

// Admin: Merge duplicate fee records for same student
router.post('/merge-duplicates', auth, adminOnly, async (req, res) => {
  try {
    const allFees = await Fee.find().populate('student', 'studentId');
    // Group by student
    const byStudent = {};
    for (const fee of allFees) {
      const sid = fee.student?._id?.toString();
      if (!sid) continue;
      if (!byStudent[sid]) byStudent[sid] = [];
      byStudent[sid].push(fee);
    }

    let merged = 0;
    for (const [studentId, fees] of Object.entries(byStudent)) {
      if (fees.length <= 1) continue;

      // Keep the fee with most items or most recent, merge others into it
      fees.sort((a, b) => b.items.length - a.items.length || new Date(b.createdAt) - new Date(a.createdAt));
      const keep = fees[0];
      const merge = fees.slice(1);

      for (const other of merge) {
        // Add items from other fee that don't already exist
        for (const item of other.items) {
          const exists = keep.items.some(i =>
            i.description === item.description && i.category === item.category
          );
          if (!exists) {
            keep.items.push({
              description: item.description,
              amount: item.amount,
              paidAmount: item.paidAmount || 0,
              category: item.category || 'other',
              paidAt: item.paidAt
            });
          }
        }
        // Recalculate total
        keep.totalAmount = keep.items.reduce((sum, i) => sum + i.amount, 0);
        await keep.save();
        // Delete the merged fee
        await Fee.findByIdAndDelete(other._id);
        merged++;
      }
    }
    res.json({ message: `Merged ${merged} duplicate fees`, studentsAffected: Object.keys(byStudent).filter(s => byStudent[s].length > 1).length });
  } catch (err) {
    console.error('Merge duplicates error:', err.message);
    res.status(500).json({ error: 'Failed to merge duplicates' });
  }
});

// Admin: Delete a fee by ID
router.delete('/:id', auth, adminOnly, async (req, res) => {
  try {
    const fee = await Fee.findByIdAndDelete(req.params.id);
    if (!fee) return res.status(404).json({ error: 'Fee not found' });
    res.json({ message: 'Fee deleted', id: req.params.id });
  } catch (err) {
    console.error('Delete fee error:', err.message);
    res.status(500).json({ error: 'Failed to delete fee' });
  }
});

module.exports = router;
