<?php
/**
 * SAMs Backend - PHP + MongoDB (All 4 Modules)
 * Run: C:\php84\php.exe -S localhost:8000 index.php
 */

require_once __DIR__ . '/config/config.php';
require_once __DIR__ . '/config/database.php';
require_once __DIR__ . '/middleware/auth.php';
require_once __DIR__ . '/vendor/autoload.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$method = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$body = json_decode(file_get_contents('php://input'), true) ?? [];
$query = $_GET;

$routes = [];

// ═══ HEALTH ═══
$routes['GET /api/health'] = fn() => ['status' => 'ok', 'timestamp' => date('c'), 'backend' => 'PHP', 'modules' => ['auth', 'registration', 'attendance', 'curriculum', 'tuition-fees']];

// ═══ AUTH ═══
$routes['POST /api/auth/register'] = function() use ($body) {
    require_once __DIR__ . '/modules/tuition-fees/controllers/AuthController.php';
    return AuthController::register($body);
};
$routes['POST /api/auth/login'] = function() use ($body) {
    require_once __DIR__ . '/modules/tuition-fees/controllers/AuthController.php';
    return AuthController::login($body);
};
$routes['GET /api/auth/profile'] = function() {
    require_once __DIR__ . '/modules/tuition-fees/controllers/AuthController.php';
    return AuthController::profile(Auth::authenticate());
};

// ═══ REGISTRATION ═══
$routes['GET /api/registration/courses'] = function() use ($query) {
    require_once __DIR__ . '/modules/registration/controllers/RegistrationController.php';
    Auth::authenticate();
    return RegistrationController::courses($query);
};
$routes['POST /api/registration/register'] = function() use ($body) {
    require_once __DIR__ . '/modules/registration/controllers/RegistrationController.php';
    return RegistrationController::register(Auth::authenticate(), $body);
};
$routes['GET /api/registration/my'] = function() {
    require_once __DIR__ . '/modules/registration/controllers/RegistrationController.php';
    return RegistrationController::my(Auth::authenticate());
};

// ═══ ATTENDANCE ═══
$routes['POST /api/attendance/check-in'] = function() use ($body) {
    require_once __DIR__ . '/modules/attendance/controllers/AttendanceController.php';
    return AttendanceController::checkIn(Auth::authenticate(), $body);
};
$routes['GET /api/attendance/my'] = function() {
    require_once __DIR__ . '/modules/attendance/controllers/AttendanceController.php';
    return AttendanceController::my(Auth::authenticate());
};
$routes['POST /api/attendance/generate-qr'] = function() use ($body) {
    require_once __DIR__ . '/modules/attendance/controllers/AttendanceController.php';
    Auth::authenticate();
    return AttendanceController::generateQR($body);
};
$routes['POST /api/attendance/mark'] = function() use ($body) {
    require_once __DIR__ . '/modules/attendance/controllers/AttendanceController.php';
    Auth::authenticate();
    return AttendanceController::mark($body);
};

// ═══ CURRICULUM ═══
$routes['GET /api/curriculum'] = function() use ($query) {
    require_once __DIR__ . '/modules/curriculum/controllers/CurriculumController.php';
    Auth::authenticate();
    return CurriculumController::all($query);
};
$routes['GET /api/curriculum/my/joined'] = function() {
    require_once __DIR__ . '/modules/curriculum/controllers/CurriculumController.php';
    return CurriculumController::myJoined(Auth::authenticate());
};
$routes['POST /api/curriculum'] = function() use ($body) {
    require_once __DIR__ . '/modules/curriculum/controllers/CurriculumController.php';
    $user = Auth::authenticate(); Auth::adminOnly($user);
    return CurriculumController::create($body);
};

// ═══ TUITION FEES ═══
$routes['GET /api/fees/my'] = function() {
    require_once __DIR__ . '/modules/tuition-fees/controllers/FeeController.php';
    return FeeController::myFees(Auth::authenticate());
};
$routes['GET /api/fees/summary'] = function() {
    require_once __DIR__ . '/modules/tuition-fees/controllers/FeeController.php';
    $user = Auth::authenticate();
    return FeeController::summary($user['id']);
};
$routes['POST /api/fees/pay'] = function() use ($body) {
    require_once __DIR__ . '/modules/tuition-fees/controllers/PaymentController.php';
    return PaymentController::pay(Auth::authenticate(), $body);
};
$routes['GET /api/fees/payments/history'] = function() {
    require_once __DIR__ . '/modules/tuition-fees/controllers/PaymentController.php';
    return PaymentController::history(Auth::authenticate());
};
$routes['GET /api/fees'] = function() {
    require_once __DIR__ . '/modules/tuition-fees/controllers/FeeController.php';
    $user = Auth::authenticate(); Auth::adminOnly($user);
    return FeeController::allFees();
};
$routes['POST /api/fees'] = function() use ($body) {
    require_once __DIR__ . '/modules/tuition-fees/controllers/FeeController.php';
    $user = Auth::authenticate(); Auth::adminOnly($user);
    return FeeController::create($body);
};

// ═══ DYNAMIC ROUTES ═══
if (preg_match('#^/api/fees/([a-f0-9]{24})$#', $uri, $m)) {
    $routes["GET $uri"] = function() use ($m) {
        require_once __DIR__ . '/modules/tuition-fees/controllers/FeeController.php';
        Auth::authenticate();
        return FeeController::details($m[1]);
    };
}
if (preg_match('#^/api/curriculum/([a-f0-9]{24})/join$#', $uri, $m)) {
    $routes["POST $uri"] = function() use ($m) {
        require_once __DIR__ . '/modules/curriculum/controllers/CurriculumController.php';
        return CurriculumController::join(Auth::authenticate(), $m[1]);
    };
}
if (preg_match('#^/api/curriculum/([a-f0-9]{24})/leave$#', $uri, $m)) {
    $routes["POST $uri"] = function() use ($m) {
        require_once __DIR__ . '/modules/curriculum/controllers/CurriculumController.php';
        return CurriculumController::leave(Auth::authenticate(), $m[1]);
    };
}
if (preg_match('#^/api/registration/drop/([a-f0-9]{24})$#', $uri, $m)) {
    $routes["PUT $uri"] = function() use ($m) {
        require_once __DIR__ . '/modules/registration/controllers/RegistrationController.php';
        return RegistrationController::drop(Auth::authenticate(), $m[1]);
    };
}

// ═══ DISPATCH ═══
$routeKey = "$method $uri";
if (isset($routes[$routeKey])) {
    echo json_encode($routes[$routeKey]());
} else {
    http_response_code(404);
    echo json_encode(['error' => 'Route not found', 'path' => $uri]);
}
