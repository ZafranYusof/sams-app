const mongoose = require('mongoose');

const courseSchema = new mongoose.Schema({
  code: { type: String, unique: true, required: true },
  name: { type: String, required: true },
  creditHours: { type: Number, required: true },
  faculty: { type: String, required: true },
  lecturer: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  capacity: { type: Number, default: 50 },
  enrolled: { type: Number, default: 0 },
  semester: { type: Number, required: true },
  schedule: {
    day: { type: String },
    startTime: { type: String },
    endTime: { type: String },
    venue: { type: String }
  },
  status: { type: String, enum: ['active', 'inactive'], default: 'active' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Course', courseSchema);
