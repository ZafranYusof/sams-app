<?php
require_once __DIR__ . '/../../../config/database.php';

class AttendanceController {
    // POST /api/attendance/check-in
    public static function checkIn($authUser, $data) {
        $attendance = Database::collection('attendance');
        $today = new MongoDB\BSON\UTCDateTime(strtotime('today') * 1000);

        $existing = $attendance->findOne(['student' => $authUser['id'], 'course' => $data['courseId'], 'date' => $today]);
        if ($existing) { http_response_code(400); return ['error' => 'Already checked in today']; }

        $record = [
            'student' => $authUser['id'],
            'course' => $data['courseId'],
            'date' => $today,
            'status' => 'present',
            'checkInTime' => new MongoDB\BSON\UTCDateTime(),
            'method' => 'qr',
            'qrCode' => $data['qrCode'] ?? '',
        ];
        $attendance->insertOne($record);
        return $record;
    }

    // GET /api/attendance/my
    public static function my($authUser) {
        $attendance = Database::collection('attendance');
        $courses = Database::collection('courses');
        $records = $attendance->find(['student' => $authUser['id']], ['sort' => ['date' => -1]])->toArray();

        $output = [];
        foreach ($records as $r) {
            $course = $courses->findOne(['_id' => new MongoDB\BSON\ObjectId($r['course'])]);
            $output[] = [
                'status' => $r['status'] ?? 'absent',
                'date' => isset($r['date']) ? (string)$r['date'] : null,
                'method' => $r['method'] ?? 'manual',
                'course' => $course ? ['name' => $course['name'], 'code' => $course['code']] : null,
            ];
        }

        $total = count($records);
        $present = count(array_filter($records, fn($r) => in_array($r['status'] ?? '', ['present', 'late'])));
        $percentage = $total > 0 ? round(($present / $total) * 100) : 0;

        return ['records' => $output, 'stats' => ['total' => $total, 'present' => $present, 'percentage' => $percentage]];
    }

    // POST /api/attendance/generate-qr
    public static function generateQR($data) {
        $qrCode = bin2hex(random_bytes(16));
        return ['qrCode' => $qrCode, 'courseId' => $data['courseId'] ?? '', 'expiry' => date('c', time() + 900)];
    }

    // POST /api/attendance/mark
    public static function mark($data) {
        $attendance = Database::collection('attendance');
        $attendance->updateOne(
            ['student' => $data['studentId'], 'course' => $data['courseId'], 'date' => new MongoDB\BSON\UTCDateTime(strtotime($data['date']) * 1000)],
            ['$set' => ['status' => $data['status'], 'method' => 'manual']],
            ['upsert' => true]
        );
        return ['status' => 'ok'];
    }
}
