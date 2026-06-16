const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Fee = require('../models/Fee');
const { jwtSecret, jwtExpire } = require('../config');
const { buildDefaultFee } = require('../config/defaultFees');

// Register
exports.register = async (req, res) => {
  try {
    const studentId = req.body.studentId || req.body.student_id;
    const { name, email, password, faculty, program, financingType } = req.body;

    const exists = await User.findOne({ $or: [{ email }, { studentId }] });
    if (exists) return res.status(400).json({ error: 'User already exists' });

    const user = new User({ studentId, name, email, password, faculty, program, financingType });
    await user.save();

    // Auto-create default semester fee for ALL new students (admins skipped).
    // Sponsored students still get the fee record — restriction rules differ only.
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
    res.status(201).json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Login
exports.login = async (req, res) => {
  try {
    const identifier = req.body.email || req.body.student_id || req.body.studentId;
    const { password } = req.body;
    const user = await User.findOne({ $or: [{ email: identifier }, { studentId: identifier }] });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const isMatch = await user.comparePassword(password);
    if (!isMatch) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id, role: user.role }, jwtSecret, { expiresIn: jwtExpire });
    res.json({ token, user: { id: user._id, name: user.name, email: user.email, role: user.role, studentId: user.studentId, student_id: user.studentId } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Update profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, faculty, program } = req.body;
    const user = await User.findByIdAndUpdate(req.user.id, { name, phone, faculty, program }, { new: true }).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
