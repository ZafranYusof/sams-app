const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  course: { type: mongoose.Schema.Types.ObjectId, ref: 'Course', required: true },
  date: { type: Date, required: true },
  status: { type: String, enum: ['present', 'absent', 'late', 'excused'], default: 'absent' },
  checkInTime: { type: Date },
  method: { type: String, enum: ['qr', 'manual', 'auto'], default: 'manual' },
  qrCode: { type: String },
  remarks: { type: String },
  createdAt: { type: Date, default: Date.now }
});

attendanceSchema.index({ student: 1, course: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
