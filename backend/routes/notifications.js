const express = require('express');
const mongoose = require('mongoose');
const { auth, adminOnly } = require('../middleware/auth');
const User = require('../models/User');
const fcm = require('../services/fcmService');

const router = express.Router();

// Resolve a student-string-id (e.g. CB23109) OR a Mongo ObjectId to a user._id.
// Returns null if no matching user or invalid.
async function resolveUserId(rawId) {
  if (!rawId) return null;
  // Already an ObjectId? trust it
  if (/^[a-f0-9]{24}$/i.test(rawId)) return rawId;
  // Else look up by studentId
  const u = await User.findOne({ studentId: rawId }).select('_id');
  return u ? u._id.toString() : null;
}

// Fire-and-forget push to many studentIds (string IDs OR Mongo IDs). Never blocks the response.
function pushToStudents(studentIds, payload) {
  Promise.all(studentIds.map(async (sid) => {
    const uid = await resolveUserId(sid);
    if (!uid) return;
    try { await fcm.sendToUser(uid, payload); }
    catch (e) { console.error('[notif push]', sid, e.message); }
  })).catch(e => console.error('[notif push batch]', e.message));
}

// Notification schema (inline, simple)
const notificationSchema = new mongoose.Schema({
  studentId: { type: String, required: true },
  title: { type: String, required: true },
  message: { type: String },
  type: { type: String, enum: ['info', 'warning', 'payment', 'reminder'], default: 'info' },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

const Notification = mongoose.models.Notification || mongoose.model('Notification', notificationSchema);

// POST /api/notifications - create notification(s) [admin only]
router.post('/', auth, adminOnly, async (req, res) => {
  try {
    const { notifications } = req.body;
    if (Array.isArray(notifications) && notifications.length > 0) {
      const created = await Notification.insertMany(notifications);
      // Push to each student's devices
      const grouped = {};
      for (const n of notifications) {
        if (!n.studentId) continue;
        if (!grouped[n.studentId]) grouped[n.studentId] = [];
        grouped[n.studentId].push(n);
      }
      Object.entries(grouped).forEach(([sid, list]) => {
        const first = list[0];
        pushToStudents([sid], {
          title: first.title || 'Notification',
          body: first.message || '',
          data: { type: first.type || 'info' },
        });
      });
      return res.status(201).json({ success: true, count: created.length });
    }
    // Single notification
    const { studentId, title, message, type } = req.body;
    if (!studentId || !title) {
      return res.status(400).json({ error: 'studentId and title are required' });
    }
    const notif = await Notification.create({ studentId, title, message, type: type || 'reminder' });
    pushToStudents([studentId], {
      title,
      body: message || '',
      data: { type: type || 'reminder', notificationId: notif._id.toString() },
    });
    res.status(201).json({ success: true, notification: notif });
  } catch (err) {
    console.error('Create notification error:', err.message);
    res.status(500).json({ error: 'Failed to create notification' });
  }
});

// POST /api/notifications/send-reminder - bulk send payment reminders [admin only]
router.post('/send-reminder', auth, adminOnly, async (req, res) => {
  try {
    const { studentIds, message } = req.body;
    if (!Array.isArray(studentIds) || studentIds.length === 0) {
      return res.status(400).json({ error: 'studentIds array required' });
    }
    const reminderText = message || 'You have outstanding tuition fees. Please make payment before the deadline to avoid penalties.';
    const notifications = studentIds.map(sid => ({
      studentId: sid,
      title: 'Payment Reminder',
      message: reminderText,
      type: 'reminder',
      read: false,
    }));
    const created = await Notification.insertMany(notifications);

    // Debug: log what studentIds treasury sends + resolve to User IDs
    console.log('[send-reminder] Received studentIds:', studentIds);
    console.log('[send-reminder] Count:', studentIds.length);
    
    // Resolve studentIds to User IDs for debugging
    const resolved = await Promise.all(studentIds.map(async (sid) => {
      const uid = await resolveUserId(sid);
      return { studentId: sid, userId: uid };
    }));
    console.log('[send-reminder] Resolved:', resolved);
    
    // Fire-and-forget FCM push to every targeted student's devices
    pushToStudents(studentIds, {
      title: 'Payment Reminder',
      body: reminderText,
      data: { type: 'reminder' },
    });

    res.status(201).json({ 
      success: true, 
      count: created.length,
      debug: { sent: studentIds, resolved: resolved.map(r => ({ ...r, found: !!r.userId })) }
    });
  } catch (err) {
    console.error('Send reminder error:', err.message);
    res.status(500).json({ error: 'Failed to send reminders' });
  }
});

// PUT /api/notifications/read-all/:studentId - mark all as read (specific path to avoid conflict)
router.put('/read-all/:studentId', auth, async (req, res) => {
  try {
    // Authorization: only own notifications or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (user.studentId !== req.params.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    await Notification.updateMany({ studentId: req.params.studentId }, { read: true });
    res.json({ success: true });
  } catch (err) {
    console.error('Read-all error:', err.message);
    res.status(500).json({ error: 'Failed to mark notifications as read' });
  }
});

// PUT /api/notifications/:id/read - mark single as read
router.put('/:id/read', auth, async (req, res) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ error: 'Invalid notification ID' });
    }
    const notif = await Notification.findById(req.params.id);
    if (!notif) return res.status(404).json({ error: 'Notification not found' });
    // Authorization: only own notification or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (notif.studentId !== user.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    await Notification.findByIdAndUpdate(req.params.id, { read: true });
    res.json({ success: true });
  } catch (err) {
    console.error('Mark read error:', err.message);
    res.status(500).json({ error: 'Failed to mark notification as read' });
  }
});

// GET /api/notifications/:studentId - get notifications for student
router.get('/:studentId', auth, async (req, res) => {
  try {
    // Authorization: only own notifications or admin
    const User = require('../models/User');
    const user = await User.findById(req.user.id);
    if (user.studentId !== req.params.studentId && req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied' });
    }
    const notifications = await Notification.find({ studentId: req.params.studentId }).sort({ createdAt: -1 });
    res.json({ notifications });
  } catch (err) {
    console.error('Get notifications error:', err.message);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

module.exports = router;
