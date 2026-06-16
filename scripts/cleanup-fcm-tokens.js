#!/usr/bin/env node
// FCM Token Cleanup - removes expired/invalid tokens from database
// Run: node scripts/cleanup-fcm-tokens.js

const mongoose = require('mongoose');
const FcmToken = require('../backend/models/FcmToken');

async function cleanupTokens() {
  try {
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/umpsa_sams');
    
    const now = new Date();
    
    // Remove expired tokens
    const expiredResult = await FcmToken.deleteMany({
      expiresAt: { $lt: now }
    });
    
    console.log(`[FCM Cleanup] Removed ${expiredResult.deletedCount} expired tokens`);
    
    // Remove orphaned tokens (user doesn't exist)
    const User = require('../backend/models/User');
    const userIds = await User.distinct('_id');
    
    const orphanedResult = await FcmToken.deleteMany({
      userId: { $nin: userIds }
    });
    
    console.log(`[FCM Cleanup] Removed ${orphanedResult.deletedCount} orphaned tokens`);
    
    await mongoose.disconnect();
    process.exit(0);
  } catch (err) {
    console.error('[FCM Cleanup] Error:', err.message);
    process.exit(1);
  }
}

cleanupTokens();
