const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const registrationRoutes = require('./routes/registration');
const curriculumRoutes = require('./routes/curriculum');
const attendanceRoutes = require('./routes/attendance');
const feesRoutes = require('./routes/fees');
const paymentsRoutes = require('./routes/payments');
const notificationsRoutes = require('./routes/notifications');
const paymentGatewayRoutes = require('./routes/payment-gateway');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/registration', registrationRoutes);
app.use('/api/curriculum', curriculumRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/fees', feesRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/payment', paymentGatewayRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Connect to MongoDB and start server
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sams';

mongoose.connect(MONGODB_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    app.listen(PORT, () => {
      console.log(`SAMs API running on port ${PORT}`);
    });
  })
  .catch(err => {
    console.error('MongoDB connection error:', err);
    process.exit(1);
  });

module.exports = app;
