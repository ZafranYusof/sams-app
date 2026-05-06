<?php
// Database Configuration - MongoDB
define('MONGO_URI', 'mongodb://localhost:27017');
define('MONGO_DB', 'umpsa_sams');

// JWT Configuration
define('JWT_SECRET', 'umpsa_sams_jwt_secret_2026');
define('JWT_EXPIRY', 604800); // 7 days

// CORS
define('ALLOWED_ORIGINS', '*');

// App
define('APP_ENV', 'development');
define('APP_PORT', 8000);
