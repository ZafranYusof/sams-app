<?php
require_once __DIR__ . '/../../../config/database.php';

class RegistrationController {
    // GET /api/registration/courses
    public static function courses($query) {
        $courses = Database::collection('courses');
        $filter = ['status' => 'active'];
        if (!empty($query['semester'])) $filter['semester'] = (int)$query['semester'];
        if (!empty($query['faculty'])) $filter['faculty'] = $query['faculty'];
        $results = $courses->find($filter)->toArray();
        $output = [];
        foreach ($results as $c) {
            $output[] = [
                '_id' => (string)$c['_id'],
                'code' => $c['code'] ?? '',
                'name' => $c['name'] ?? '',
                'creditHours' => $c['creditHours'] ?? 0,
                'faculty' => $c['faculty'] ?? '',
                'capacity' => $c['capacity'] ?? 50,
                'enrolled' => $c['enrolled'] ?? 0,
                'semester' => $c['semester'] ?? 1,
                'schedule' => $c['schedule'] ?? null,
            ];
        }
        return $output;
    }

    // POST /api/registration/register
    public static function register($authUser, $data) {
        $courses = Database::collection('courses');
        $registrations = Database::collection('registrations');

        $course = $courses->findOne(['_id' => new MongoDB\BSON\ObjectId($data['courseId'])]);
        if (!$course) { http_response_code(404); return ['error' => 'Course not found']; }
        if (($course['enrolled'] ?? 0) >= ($course['capacity'] ?? 50)) { http_response_code(400); return ['error' => 'Course is full']; }

        $existing = $registrations->findOne(['student' => $authUser['id'], 'course' => $data['courseId'], 'academicYear' => $data['academicYear'] ?? '2025/2026']);
        if ($existing) { http_response_code(400); return ['error' => 'Already registered']; }

        $reg = [
            'student' => $authUser['id'],
            'course' => $data['courseId'],
            'semester' => $data['semester'] ?? 1,
            'academicYear' => $data['academicYear'] ?? '2025/2026',
            'status' => 'registered',
            'registeredAt' => new MongoDB\BSON\UTCDateTime(),
        ];
        $registrations->insertOne($reg);
        $courses->updateOne(['_id' => $course['_id']], ['$inc' => ['enrolled' => 1]]);
        return $reg;
    }

    // GET /api/registration/my
    public static function my($authUser) {
        $registrations = Database::collection('registrations');
        $courses = Database::collection('courses');
        $results = $registrations->find(['student' => $authUser['id']])->toArray();
        $output = [];
        foreach ($results as $r) {
            $course = $courses->findOne(['_id' => new MongoDB\BSON\ObjectId($r['course'])]);
            $output[] = [
                '_id' => (string)$r['_id'],
                'status' => $r['status'] ?? 'pending',
                'course' => $course ? ['_id' => (string)$course['_id'], 'code' => $course['code'], 'name' => $course['name'], 'creditHours' => $course['creditHours'] ?? 0] : null,
            ];
        }
        return $output;
    }

    // PUT /api/registration/drop/:id
    public static function drop($authUser, $regId) {
        $registrations = Database::collection('registrations');
        $reg = $registrations->findOne(['_id' => new MongoDB\BSON\ObjectId($regId), 'student' => $authUser['id']]);
        if (!$reg) { http_response_code(404); return ['error' => 'Registration not found']; }
        $registrations->updateOne(['_id' => $reg['_id']], ['$set' => ['status' => 'dropped', 'droppedAt' => new MongoDB\BSON\UTCDateTime()]]);
        Database::collection('courses')->updateOne(['_id' => new MongoDB\BSON\ObjectId($reg['course'])], ['$inc' => ['enrolled' => -1]]);
        return ['status' => 'dropped'];
    }
}
