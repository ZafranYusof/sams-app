// Default semester fees for all students
// Based on UMP Computer Science program fee schedule
// Academic year 2025/2026 Semester II
//
// Yuran Pengajian (tuition) — required for student to be "active"
// Yuran Asrama (facility) — additional, due by end of semester (week 16)

const SEMESTER_END_DATE = new Date('2026-06-19'); // Week 16, last day of lectures

const DEFAULT_FEE_ITEMS = [
  { description: 'Yuran Pengajian', amount: 860, paidAmount: 0, category: 'tuition' },
  { description: 'Yuran Asrama', amount: 650, paidAmount: 0, category: 'facility' },
];

const DEFAULT_FEE_TOTAL = DEFAULT_FEE_ITEMS.reduce((sum, item) => sum + item.amount, 0);

// Helper to build a default fee object for a student
function buildDefaultFee(studentObjectId, options = {}) {
  return {
    student: studentObjectId,
    items: DEFAULT_FEE_ITEMS.map(item => ({ ...item })),
    semester: options.semester || 2,
    academicYear: options.academicYear || '2025/2026',
    totalAmount: DEFAULT_FEE_TOTAL,
    paidAmount: 0,
    status: 'unpaid',
    dueDate: options.dueDate || SEMESTER_END_DATE,
  };
}

module.exports = {
  DEFAULT_FEE_ITEMS,
  DEFAULT_FEE_TOTAL,
  SEMESTER_END_DATE,
  buildDefaultFee,
};
