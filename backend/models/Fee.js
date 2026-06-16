const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  semester: { type: Number, required: true },
  academicYear: { type: String, required: true },
  items: [{
    description: { type: String, required: true },
    amount: { type: Number, required: true, min: [0.01, 'Amount must be positive'] },
    paidAmount: { type: Number, default: 0 },
    category: { type: String, enum: ['tuition', 'facility', 'insurance', 'activity', 'other'] },
    paidAt: { type: Date }
  }],
  totalAmount: { type: Number, required: true },
  paidAmount: { type: Number, default: 0 },
  status: { type: String, enum: ['unpaid', 'partial', 'paid', 'overdue', 'partial_overdue'], default: 'unpaid' },
  dueDate: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

// Auto-derive overall status from item-level payment data
feeSchema.pre('save', function (next) {
  // Recalculate totalAmount from items (catches treasury-added items)
  if (this.items && this.items.length > 0) {
    this.totalAmount = this.items.reduce((sum, i) => sum + (i.amount || 0), 0);
  }

  // Auto-allocate: if fee-level paidAmount > 0 but items not synced, allocate to items
  const itemsPaid = this.items.reduce((sum, i) => sum + (i.paidAmount || 0), 0);
  if (this.paidAmount > 0 && itemsPaid === 0) {
    // Allocate fee-level payment to items in priority order
    const PRIORITY = { tuition: 1, facility: 2, insurance: 3, activity: 4, other: 5 };
    const sorted = [...this.items].sort((a, b) =>
      (PRIORITY[a.category] || 99) - (PRIORITY[b.category] || 99)
    );
    let remaining = this.paidAmount;
    for (const item of sorted) {
      if (remaining <= 0) break;
      const apply = Math.min(remaining, item.amount);
      item.paidAmount = apply;
      if (apply >= item.amount) item.paidAt = new Date();
      remaining -= apply;
    }
  }

  // Re-compute paidAmount from item-level data
  this.paidAmount = this.items.reduce((sum, i) => sum + (i.paidAmount || 0), 0);

  if (this.paidAmount === 0) {
    this.status = 'unpaid';
  } else if (this.paidAmount >= this.totalAmount) {
    this.status = 'paid';
  } else {
    this.status = 'partial';
  }

  // BUG 3 FIX: Mark overdue if past due date, preserving partial distinction
  if (this.dueDate && new Date() > this.dueDate && this.status !== 'paid') {
    this.status = this.status === 'partial' ? 'partial_overdue' : 'overdue';
  }

  next();
});

feeSchema.set('toJSON', {
  virtuals: true,
  transform: function (doc, ret) {
    // Flatten studentId to top level for easier access
    if (ret.student && ret.student.studentId) {
      ret.studentId = ret.student.studentId;
    }
    return ret;
  }
});
feeSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Fee', feeSchema);
