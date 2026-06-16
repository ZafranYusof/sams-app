// Backfill default semester fees for existing students without fee records
// Run: node backend/scripts/backfillDefaultFees.js

require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Fee = require('../models/Fee');
const { buildDefaultFee, DEFAULT_FEE_TOTAL } = require('../config/defaultFees');

async function main() {
  const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI;
  if (!mongoUri) {
    console.error('MONGO_URI not set');
    process.exit(1);
  }

  await mongoose.connect(mongoUri);
  console.log('Connected to MongoDB');

  // Find all students
  const students = await User.find({ role: 'student' });
  console.log(`Found ${students.length} students`);

  let created = 0;
  let skipped = 0;

  for (const student of students) {
    const existing = await Fee.findOne({ student: student._id });
    if (existing) {
      skipped++;
      continue;
    }

    const fee = new Fee(buildDefaultFee(student._id));
    await fee.save();
    created++;
    console.log(`+ ${student.studentId || student.email}: RM ${DEFAULT_FEE_TOTAL}`);
  }

  console.log(`\nDone. Created: ${created}, Skipped (already have fees): ${skipped}`);
  await mongoose.disconnect();
}

main().catch(err => {
  console.error('FATAL:', err);
  process.exit(1);
});
