const mongoose = require('mongoose');

const feeSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  semester: { type: Number, required: true },
  academicYear: { type: String, required: true },
  items: [{
    description: { type: String, required: true },
    amount: { type: Number, required: true },
    paidAmount: { type: Number, default: 0 },
    category: { type: String, enum: ['tuition', 'facility', 'insurance', 'activity', 'other'] },
    paidAt: { type: Date }
  }],
  totalAmount: { type: Number, required: true },
  paidAmount: { type: Number, default: 0 },
  status: { type: String, enum: ['unpaid', 'partial', 'paid', 'overdue'], default: 'unpaid' },
  dueDate: { type: Date },
  createdAt: { type: Date, default: Date.now }
});

// Computed: student is "active" if Yuran Pengajian (tuition) is fully paid,
// even if other fees (asrama, etc.) are still outstanding.
feeSchema.virtual('studentStatus').get(function () {
  const tuitionItem = this.items.find(i => i.category === 'tuition');
  if (!tuitionItem) return 'unknown';
  const tuitionPaid = (tuitionItem.paidAmount || 0) >= tuitionItem.amount;
  return tuitionPaid ? 'active' : 'inactive';
});

// Auto-derive overall status from item-level payment data
feeSchema.pre('save', function (next) {
  // Re-compute paidAmount from item-level data
  this.paidAmount = this.items.reduce((sum, i) => sum + (i.paidAmount || 0), 0);

  if (this.paidAmount === 0) {
    this.status = 'unpaid';
  } else if (this.paidAmount >= this.totalAmount) {
    this.status = 'paid';
  } else {
    this.status = 'partial';
  }

  // Mark overdue if past due date
  if (this.dueDate && new Date() > this.dueDate && this.status !== 'paid') {
    this.status = 'overdue';
  }

  next();
});

feeSchema.set('toJSON', { virtuals: true });
feeSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Fee', feeSchema);
