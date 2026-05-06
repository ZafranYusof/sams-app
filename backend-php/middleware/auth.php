<?php
require_once __DIR__ . '/../config/config.php';

class Auth {
    // Generate JWT token
    public static function generateToken($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload['iat'] = time();
        $payload['exp'] = time() + JWT_EXPIRY;
        $payload = json_encode($payload);

        $base64Header = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($header));
        $base64Payload = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($payload));

        $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
        $base64Signature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        return "$base64Header.$base64Payload.$base64Signature";
    }

    // Verify JWT token
    public static function verifyToken($token) {
        $parts = explode('.', $token);
        if (count($parts) !== 3) return null;

        [$base64Header, $base64Payload, $base64Signature] = $parts;

        $signature = hash_hmac('sha256', "$base64Header.$base64Payload", JWT_SECRET, true);
        $expectedSignature = str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($signature));

        if (!hash_equals($expectedSignature, $base64Signature)) return null;

        $payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $base64Payload)), true);

        if ($payload['exp'] < time()) return null;

        return $payload;
    }

    // Middleware: Extract user from Authorization header
    public static function authenticate() {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (!str_starts_with($authHeader, 'Bearer ')) {
            http_response_code(401);
            echo json_encode(['error' => 'Access denied']);
            exit;
        }

        $token = substr($authHeader, 7);
        $user = self::verifyToken($token);

        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Invalid token']);
            exit;
        }

        return $user;
    }

    // Check admin role
    public static function adminOnly($user) {
        if (($user['role'] ?? '') !== 'admin') {
            http_response_code(403);
            echo json_encode(['error' => 'Admin access required']);
            exit;
        }
    }

    // Hash password
    public static function hashPassword($password) {
        return password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);
    }

    // Verify password
    public static function verifyPassword($password, $hash) {
        return password_verify($password, $hash);
    }
}
