// Default semester fees for all students
// Based on UMP Computer Science program fee schedule
// As of 2026

const DEFAULT_FEE_ITEMS = [
  { description: 'Yuran Pengajian', amount: 860, category: 'tuition' },
  { description: 'Yuran Asrama', amount: 650, category: 'facility' },
];

const DEFAULT_FEE_TOTAL = DEFAULT_FEE_ITEMS.reduce((sum, item) => sum + item.amount, 0);

// Helper to build a default fee object for a student
function buildDefaultFee(studentObjectId, options = {}) {
  return {
    student: studentObjectId,
    items: DEFAULT_FEE_ITEMS.map(item => ({ ...item })),
    semester: options.semester || 1,
    academicYear: options.academicYear || '2025/2026',
    totalAmount: DEFAULT_FEE_TOTAL,
    paidAmount: 0,
    status: 'unpaid',
    dueDate: options.dueDate || new Date(Date.now() + 90 * 24 * 60 * 60 * 1000),
  };
}

module.exports = {
  DEFAULT_FEE_ITEMS,
  DEFAULT_FEE_TOTAL,
  buildDefaultFee,
};
