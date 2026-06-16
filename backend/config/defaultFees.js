// Default semester fees + payment schedule for all students
// Based on UMP Computer Science program fee schedule
// Academic year 2025/2026 Semester II
//
// Yuran Pengajian (tuition) — required for student to be "active"
// Yuran Asrama (facility) — additional, due same as tuition
//
// Payment schedule per UMP Student Account Unit:
//   Week 4  (5 Apr 2026) — Tuition + Dorm fees due
//   Week 5  (6 Apr 2026) — 1st Restriction if unpaid
//   Week 7  (26 Apr 2026) — Full payment deadline
//   Week 8  (4 May 2026) — 2nd Restriction if outstanding debt
//   Week 10 (24 May 2026) — Final settlement deadline
//   Week 11 (25 May 2026) — Deferment of Studies
//   Week 18 (15 Jul 2026) — 3rd Restriction (financed students)

const PAYMENT_SCHEDULE = {
  tuitionAsramaDue: new Date('2026-06-14'),    // Week 4
  firstRestriction: new Date('2026-06-15'),    // Week 5
  fullPaymentDeadline: new Date('2026-07-05'), // Week 7
  secondRestriction: new Date('2026-07-13'),   // Week 8
  finalSettlement: new Date('2026-08-02'),     // Week 10
  defermentDate: new Date('2026-08-03'),       // Week 11
  thirdRestriction: new Date('2026-09-23'),    // Week 18
};

const DEFAULT_FEE_ITEMS = [
  { description: 'Yuran Pengajian', amount: 860, paidAmount: 0, category: 'tuition' },
  { description: 'Yuran Asrama', amount: 650, paidAmount: 0, category: 'facility' },
];

const DEFAULT_FEE_TOTAL = DEFAULT_FEE_ITEMS.reduce((sum, item) => sum + item.amount, 0);

// Helper to build a default fee object for a student
// BUG 4 FIX: Deep copy to prevent mutation of shared DEFAULT_FEE_ITEMS
function buildDefaultFee(studentObjectId, options = {}) {
  return {
    student: studentObjectId,
    items: JSON.parse(JSON.stringify(DEFAULT_FEE_ITEMS)),
    semester: options.semester || 2,
    academicYear: options.academicYear || '2025/2026',
    totalAmount: DEFAULT_FEE_TOTAL,
    paidAmount: 0,
    status: 'unpaid',
    dueDate: options.dueDate || PAYMENT_SCHEDULE.tuitionAsramaDue,
  };
}

/**
 * Compute student academic status based on fee payment + current date.
 * Returns one of:
 *   - 'active'        : all good, no restrictions
 *   - 'warning'       : approaching deadline, not yet restricted
 *   - 'restricted_1'  : 1st restriction (week 5+, unpaid tuition/dorm)
 *   - 'restricted_2'  : 2nd restriction (week 8+, full payment overdue)
 *   - 'deferred'      : deferment of studies (week 11+, debt unsettled)
 *   - 'restricted_3'  : 3rd restriction (week 18+, financed students with debt)
 *
 * @param {Object} fee - latest Fee document for the student
 * @param {Date} now   - reference date (defaults to current time)
 * @param {String} financingType - 'unfinanced' | 'ptptn' | 'sponsored' (default: unfinanced)
 */
function computeStudentStatus(fee, now = new Date(), financingType = 'unfinanced') {
  if (!fee) return 'active'; // No fee record yet (shouldn't happen post-backfill)

  const tuitionItem = fee.items.find(i => i.category === 'tuition');
  const asramaItem = fee.items.find(i => i.category === 'facility');
  const tuitionPaid = tuitionItem ? (tuitionItem.paidAmount || 0) >= tuitionItem.amount : true;
  const asramaPaid = asramaItem ? (asramaItem.paidAmount || 0) >= asramaItem.amount : true;
  const fullyPaid = (fee.paidAmount || 0) >= fee.totalAmount;

  // If fee is fully paid at fee-level, student is active regardless of item-level sync
  if (fullyPaid) return 'active';

  // Sponsored students: only 3rd restriction applies (week 18) if sponsor debt remains
  if (financingType === 'sponsored') {
    if (now >= PAYMENT_SCHEDULE.thirdRestriction && !fullyPaid) return 'restricted_3';
    return 'active';
  }

  // Unfinanced + PTPTN students share same schedule

  // Week 11+: Deferment if debt still unsettled
  if (now >= PAYMENT_SCHEDULE.defermentDate && !fullyPaid) {
    return 'deferred';
  }

  // Week 8+: 2nd restriction if not fully paid
  if (now >= PAYMENT_SCHEDULE.secondRestriction && !fullyPaid) {
    return 'restricted_2';
  }

  // Week 5+: 1st restriction if tuition or dorm unpaid
  if (now >= PAYMENT_SCHEDULE.firstRestriction && (!tuitionPaid || !asramaPaid)) {
    return 'restricted_1';
  }

  // Pre-week 5 but past due date with debt = warning
  if (now >= PAYMENT_SCHEDULE.tuitionAsramaDue && !fullyPaid) {
    return 'warning';
  }

  return 'active';
}

module.exports = {
  DEFAULT_FEE_ITEMS,
  DEFAULT_FEE_TOTAL,
  PAYMENT_SCHEDULE,
  buildDefaultFee,
  computeStudentStatus,
};
