<?php
require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../middleware/auth.php';

class AuthController {
    // POST /api/auth/register
    public static function register($data) {
        $required = ['student_id', 'name', 'email', 'password'];
        foreach ($required as $field) {
            if (empty($data[$field])) {
                http_response_code(400);
                return ['error' => "Field '$field' is required"];
            }
        }

        $users = Database::collection('users');

        // Check existing
        $exists = $users->findOne(['$or' => [
            ['email' => $data['email']],
            ['student_id' => $data['student_id']]
        ]]);

        if ($exists) {
            http_response_code(400);
            return ['error' => 'User already exists'];
        }

        $user = [
            'student_id' => $data['student_id'],
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Auth::hashPassword($data['password']),
            'role' => $data['role'] ?? 'student',
            'faculty' => $data['faculty'] ?? '',
            'program' => $data['program'] ?? '',
            'semester' => (int)($data['semester'] ?? 1),
            'phone' => $data['phone'] ?? '',
            'created_at' => new MongoDB\BSON\UTCDateTime()
        ];

        $result = $users->insertOne($user);
        $token = Auth::generateToken([
            'id' => (string)$result->getInsertedId(),
            'role' => $user['role']
        ]);

        return [
            'token' => $token,
            'user' => [
                'id' => (string)$result->getInsertedId(),
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'student_id' => $user['student_id']
            ]
        ];
    }

    // POST /api/auth/login
    public static function login($data) {
        if (empty($data['email']) || empty($data['password'])) {
            http_response_code(400);
            return ['error' => 'Email and password required'];
        }

        $users = Database::collection('users');
        $user = $users->findOne(['email' => $data['email']]);

        if (!$user || !Auth::verifyPassword($data['password'], $user['password'])) {
            http_response_code(401);
            return ['error' => 'Invalid credentials'];
        }

        $token = Auth::generateToken([
            'id' => (string)$user['_id'],
            'role' => $user['role']
        ]);

        return [
            'token' => $token,
            'user' => [
                'id' => (string)$user['_id'],
                'name' => $user['name'],
                'email' => $user['email'],
                'role' => $user['role'],
                'student_id' => $user['student_id']
            ]
        ];
    }

    // GET /api/auth/profile
    public static function profile($authUser) {
        $users = Database::collection('users');
        $user = $users->findOne(['_id' => new MongoDB\BSON\ObjectId($authUser['id'])]);

        if (!$user) {
            http_response_code(404);
            return ['error' => 'User not found'];
        }

        return [
            'id' => (string)$user['_id'],
            'student_id' => $user['student_id'],
            'name' => $user['name'],
            'email' => $user['email'],
            'role' => $user['role'],
            'faculty' => $user['faculty'] ?? '',
            'program' => $user['program'] ?? '',
            'semester' => $user['semester'] ?? 1,
            'phone' => $user['phone'] ?? ''
        ];
    }
}
