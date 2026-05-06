<?php
require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../middleware/auth.php';

class FeeController {
    // GET /api/fees/my - Student's fees
    public static function myFees($authUser) {
        $fees = Database::collection('fees');
        $results = $fees->find(['student_id' => $authUser['id']])->toArray();

        $output = [];
        foreach ($results as $fee) {
            $output[] = self::formatFee($fee);
        }
        return $output;
    }

    // GET /api/fees/summary - Student fee summary
    public static function summary($studentId) {
        $fees = Database::collection('fees');
        $results = $fees->find(['student_id' => $studentId])->toArray();

        $totalDue = 0;
        $totalPaid = 0;
        foreach ($results as $fee) {
            $totalDue += $fee['total_amount'] ?? 0;
            $totalPaid += $fee['paid_amount'] ?? 0;
        }

        return [
            'summary' => [
                'total_due' => $totalDue,
                'total_paid' => $totalPaid,
                'balance' => $totalDue - $totalPaid
            ]
        ];
    }

    // GET /api/fees/:id - Fee details
    public static function details($feeId) {
        $fees = Database::collection('fees');
        $fee = $fees->findOne(['_id' => new MongoDB\BSON\ObjectId($feeId)]);

        if (!$fee) {
            http_response_code(404);
            return ['error' => 'Fee not found'];
        }

        $payments = Database::collection('payments');
        $paymentList = $payments->find(['fee_id' => $feeId])->toArray();

        return [
            'fee' => self::formatFee($fee),
            'payments' => array_map(function($p) {
                return self::formatPayment($p);
            }, $paymentList)
        ];
    }

    // GET /api/fees - All fees (admin)
    public static function allFees() {
        $fees = Database::collection('fees');
        $users = Database::collection('users');
        $results = $fees->find()->toArray();

        $output = [];
        foreach ($results as $fee) {
            $user = $users->findOne(['_id' => new MongoDB\BSON\ObjectId($fee['student_id'])]);
            $formatted = self::formatFee($fee);
            $formatted['student'] = $user ? [
                'name' => $user['name'],
                'student_id' => $user['student_id'],
                'program' => $user['program'] ?? ''
            ] : null;
            $output[] = $formatted;
        }
        return $output;
    }

    // POST /api/fees - Create fee (admin)
    public static function create($data) {
        $fees = Database::collection('fees');

        $items = $data['items'] ?? [];
        $totalAmount = 0;
        foreach ($items as $item) {
            $totalAmount += $item['amount'] ?? 0;
        }

        $fee = [
            'student_id' => $data['student_id'],
            'semester' => $data['semester'] ?? 1,
            'academic_year' => $data['academic_year'] ?? '2025/2026',
            'items' => $items,
            'total_amount' => $totalAmount,
            'paid_amount' => 0,
            'status' => 'unpaid',
            'due_date' => $data['due_date'] ?? null,
            'created_at' => new MongoDB\BSON\UTCDateTime()
        ];

        $result = $fees->insertOne($fee);
        $fee['_id'] = $result->getInsertedId();
        return self::formatFee((object)$fee);
    }

    private static function formatFee($fee) {
        return [
            'id' => (string)$fee['_id'],
            'student_id' => $fee['student_id'] ?? '',
            'semester' => $fee['semester'] ?? 1,
            'academic_year' => $fee['academic_year'] ?? '',
            'items' => $fee['items'] ?? [],
            'total_amount' => $fee['total_amount'] ?? 0,
            'paid_amount' => $fee['paid_amount'] ?? 0,
            'status' => $fee['status'] ?? 'unpaid',
            'due_date' => $fee['due_date'] ?? null,
        ];
    }

    private static function formatPayment($p) {
        return [
            'id' => (string)$p['_id'],
            'amount' => $p['amount'] ?? 0,
            'method' => $p['method'] ?? 'fpx',
            'bank' => $p['bank'] ?? '',
            'txn_id' => $p['txn_id'] ?? '',
            'status' => $p['status'] ?? 'pending',
            'paid_at' => isset($p['paid_at']) ? (string)$p['paid_at'] : null,
        ];
    }
}
