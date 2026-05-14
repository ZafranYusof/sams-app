# SAMs - Student Academic Management System

A full-stack student academic management system with premium dark blue UI.

## Tech Stack

- **Frontend:** Flutter (Dart) + Riverpod
- **Backend:** Node.js + Express + MongoDB
- **Auth:** JWT + bcrypt
- **Design:** Premium dark blue theme with gold accents

## Modules

1. **Open Registration** - Course registration, add/drop
2. **Curriculum Activity** - Clubs, events, workshops, participation tracking
3. **Class Attendance** - QR code check-in, attendance records & reports
4. **Tuition Fees** - Fee breakdown, FPX payment, receipts, payment history

## Setup

## Project Structure

```
sams-app/
├── frontend/               Flutter mobile app
│   └── lib/
│       ├── screens/        UI screens per module
│       ├── models/         Data models
│       ├── providers/      Riverpod state providers
│       ├── services/       API service layer
│       ├── widgets/        Reusable UI widgets
│       ├── routes/         Navigation and routing
│       └── config/         App configuration
├── backend/                Node.js + Express API
│   ├── controllers/        Request handlers
│   ├── models/             Mongoose schemas
│   ├── routes/             API endpoints
│   ├── services/           Business logic
│   ├── middleware/         Auth, validation
│   ├── config/             DB and app config
│   └── utils/              Helper functions
└── backend-php/            Legacy PHP backend
    ├── modules/            PHP route modules
    ├── middleware/         PHP middleware
    └── config/             PHP configuration
```

## Setup

### Backend

```bash
cd backend
npm install
# Create .env with MONGODB_URI, JWT_SECRET, PORT
npm run dev
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

## Environment Variables

```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/sams
JWT_SECRET=your_secret_key
```

## API Endpoints

- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - Get profile
- `GET /api/registration/courses` - List courses
- `POST /api/registration/register` - Register course
- `GET /api/registration/my` - My registrations
- `GET /api/curriculum` - List activities
- `POST /api/curriculum/:id/join` - Join activity
- `POST /api/attendance/check-in` - QR check-in
- `GET /api/attendance/my` - My attendance
- `GET /api/fees/my` - My fees
- `POST /api/fees/pay` - Make payment
- `GET /api/fees/payments/history` - Payment history
