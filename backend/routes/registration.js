const express = require('express');
const Course = require('../models/Course');
const Registration = require('../models/Registration');
const { auth, adminOnly } = require('../middleware/auth');

const router = express.Router();

// Get available courses
router.get('/courses', auth, async (req, res) => {
  try {
    const { semester, faculty } = req.query;
    const filter = { status: 'active' };
    if (semester) filter.semester = semester;
    if (faculty) filter.faculty = faculty;
    const courses = await Course.find(filter).populate('lecturer', 'name');
    res.json(courses);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Register for a course
router.post('/register', auth, async (req, res) => {
  try {
    const { courseId, semester, academicYear } = req.body;
    
    const course = await Course.findById(courseId);
    if (!course) return res.status(404).json({ error: 'Course not found' });
    if (course.enrolled >= course.capacity) return res.status(400).json({ error: 'Course is full' });

    const existing = await Registration.findOne({ student: req.user.id, course: courseId, academicYear });
    if (existing) return res.status(400).json({ error: 'Already registered' });

    const registration = new Registration({ student: req.user.id, course: courseId, semester, academicYear, status: 'registered' });
    await registration.save();

    course.enrolled += 1;
    await course.save();

    res.status(201).json(registration);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get my registrations
router.get('/my', auth, async (req, res) => {
  try {
    const registrations = await Registration.find({ student: req.user.id }).populate('course');
    res.json(registrations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Drop a course
router.put('/drop/:id', auth, async (req, res) => {
  try {
    const reg = await Registration.findOne({ _id: req.params.id, student: req.user.id });
    if (!reg) return res.status(404).json({ error: 'Registration not found' });
    if (reg.status === 'dropped') return res.status(400).json({ error: 'Already dropped' });

    reg.status = 'dropped';
    reg.droppedAt = new Date();
    await reg.save();

    await Course.findByIdAndUpdate(reg.course, { $inc: { enrolled: -1 } });
    res.json(reg);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Create course
router.post('/courses', auth, adminOnly, async (req, res) => {
  try {
    const course = new Course(req.body);
    await course.save();
    res.status(201).json(course);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: Get all registrations
router.get('/all', auth, adminOnly, async (req, res) => {
  try {
    const registrations = await Registration.find().populate('student', 'name studentId').populate('course', 'code name');
    res.json(registrations);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
