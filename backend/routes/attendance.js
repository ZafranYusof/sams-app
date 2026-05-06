const express = require('express');
const crypto = require('crypto');
const Attendance = require('../models/Attendance');
const Course = require('../models/Course');
const Registration = require('../models/Registration');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// Generate QR code for attendance (lecturer/admin)
router.post('/generate-qr', auth, async (req, res) => {
  try {
    const { courseId, date } = req.body;
    const qrCode = crypto.randomBytes(16).toString('hex');
    // QR valid for 15 minutes
    const expiry = new Date(Date.now() + 15 * 60 * 1000);
    res.json({ qrCode, courseId, date, expiry });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Check in with QR
router.post('/check-in', auth, async (req, res) => {
  try {
    const { courseId, qrCode } = req.body;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existing = await Attendance.findOne({ student: req.user.id, course: courseId, date: today });
    if (existing) return res.status(400).json({ error: 'Already checked in today' });

    const attendance = new Attendance({
      student: req.user.id,
      course: courseId,
      date: today,
      status: 'present',
      checkInTime: new Date(),
      method: 'qr',
      qrCode
    });
    await attendance.save();
    res.status(201).json(attendance);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my attendance for a course
router.get('/my/:courseId', auth, async (req, res) => {
  try {
    const records = await Attendance.find({ student: req.user.id, course: req.params.courseId }).sort({ date: -1 });
    const total = records.length;
    const present = records.filter(r => r.status === 'present' || r.status === 'late').length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
    res.json({ records, stats: { total, present, percentage } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my overall attendance
router.get('/my', auth, async (req, res) => {
  try {
    const records = await Attendance.find({ student: req.user.id }).populate('course', 'code name');
    const total = records.length;
    const present = records.filter(r => r.status === 'present' || r.status === 'late').length;
    const percentage = total > 0 ? Math.round((present / total) * 100) : 0;
    res.json({ records, stats: { total, present, percentage } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin/Lecturer: Mark attendance manually
router.post('/mark', auth, async (req, res) => {
  try {
    const { studentId, courseId, date, status } = req.body;
    const attendance = await Attendance.findOneAndUpdate(
      { student: studentId, course: courseId, date: new Date(date) },
      { status, method: 'manual' },
      { upsert: true, new: true }
    );
    res.json(attendance);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Get attendance for a course on a date
router.get('/course/:courseId', auth, async (req, res) => {
  try {
    const { date } = req.query;
    const filter = { course: req.params.courseId };
    if (date) filter.date = new Date(date);
    const records = await Attendance.find(filter).populate('student', 'name studentId');
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
