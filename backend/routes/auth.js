const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Fee = require('../models/Fee');
const { jwtSecret, jwtExpire } = require('../config');
const { auth } = require('../middleware/auth');
const { computeStudentStatus, buildDefaultFee } = require('../config/defaultFees');

// Helper: derive student academic status from latest fee record + UMP payment schedule.
// Returns one of: 'active', 'warning', 'restricted_1', 'restricted_2', 'deferred', 'restricted_3'.
// Admins always 'active'. financingType pulled from user document.
async function getStudentStatus(userDoc) {
  if (!userDoc) return 'active';
  if (userDoc.role && userDoc.role !== 'student') return 'active';
  const fee = await Fee.findOne({ student: userDoc._id }).sort({ createdAt: -1 });
  return computeStudentStatus(fee, new Date(), userDoc.financingType || 'unfinanced');
}

const router = express.Router();

// Register
router.post('/register', async (req, res) => {
  try {
    const studentId = req.body.studentId || req.body.student_id;
    const { name, email, password, faculty, program, financingType } = req.body;

    // [Bug #8] Input validation on registration
    if (!studentId || !name || !email || !password) {
      return res.status(400).json({ error: 'studentId, name, email, and password are required' });
    }
    // Email format validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    // StudentId format validation (CB##### pattern)
    const studentIdRegex = /^CB\d{5}$/;
    if (!studentIdRegex.test(studentId)) {
      return res.status(400).json({ error: 'Invalid studentId format. Expected CB##### (e.g., CB23109)' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    // Validate financingType if provided
    const validFinancing = ['unfinanced', 'ptptn', 'sponsored'];
    const ft = financingType && validFinancing.includes(financingType) ? financingType : 'unfinanced';

    const exists = await User.findOne({ $or: [{ email }, { studentId }] });
    if (exists) return res.status(400).json({ error: 'User already exists' });

    const user = new User({ studentId, name, email, password, faculty, program, financingType: ft });
    await user.save();

    // Auto-create default semester fee for ALL new students (admins skipped).
    // Sponsored students still get the fee record — only the restriction rules differ
    // (sponsor settles directly, no week-by-week restriction triggers).
    const isStudent = user.role === 'student' || !user.role;
    if (isStudent) {
      try {
        const defaultFee = new Fee(buildDefaultFee(user._id));
        await defaultFee.save();
      } catch (feeErr) {
        // Non-fatal — registration succeeds even if fee seeding fails
        console.error('[register] failed to seed default fee:', feeErr.message);
      }
    }

    const token = jwt.sign({ id: user._id, role: user.role }, jwtSecret, { expiresIn: jwtExpire });
    // [Bug #4] Include studentId + financingType + studentStatus in register response
    const studentStatus = await getStudentStatus(user);
    res.status(201).json({
      token,
      user: {
        id: user._id, name: user.name, email: user.email, role: user.role,
        studentId: user.studentId, student_id: user.studentId,
        financingType: user.financingType,
        studentStatus,
      }
    });
  } catch (err) {
    // [Bug #9] Don't leak internal errors
    console.error('Register error:', err.message);
    res.status(500).json({ error: 'Registration failed. Please try again.' });
  }
});

// Login
router.post('/login', async (req, res) => {
  try {
    const identifier = req.body.email || req.body.student_id || req.body.studentId;
    const { password } = req.body;
    const user = await User.findOne({ $or: [{ email: identifier }, { studentId: identifier }] });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id, role: user.role }, jwtSecret, { expiresIn: jwtExpire });
    const studentStatus = await getStudentStatus(user);
    res.json({
      token,
      user: {
        id: user._id, name: user.name, email: user.email, role: user.role,
        studentId: user.studentId, student_id: user.studentId,
        financingType: user.financingType,
        studentStatus,
      }
    });
  } catch (err) {
    console.error('Login error:', err.message);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
});

// Get profile
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.studentStatus = await getStudentStatus(user);
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Alias /me -> /profile
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password').lean();
    if (!user) return res.status(404).json({ error: 'User not found' });
    user.studentStatus = await getStudentStatus(user);
    res.json(user);
  } catch (err) {
    console.error('Profile error:', err.message);
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Update profile
router.put('/profile', auth, async (req, res) => {
  try {
    const { name, phone, faculty, program, financingType } = req.body;
    const update = { name, phone, faculty, program };
    const validFinancing = ['unfinanced', 'ptptn', 'sponsored'];
    if (financingType && validFinancing.includes(financingType)) {
      update.financingType = financingType;
    }
    const user = await User.findByIdAndUpdate(req.user.id, update, { new: true }).select('-password');
    res.json(user);
  } catch (err) {
    console.error('Update profile error:', err.message);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

module.exports = router;
