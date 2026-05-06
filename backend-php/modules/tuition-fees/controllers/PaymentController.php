<?php
require_once __DIR__ . '/../../../config/database.php';
require_once __DIR__ . '/../../../middleware/auth.php';

class PaymentController {
    // POST /api/fees/pay - Make payment (FPX)
    public static function pay($authUser, $data) {
        if (empty($data['fee_id']) || empty($data['amount'])) {
            http_response_code(400);
            return ['error' => 'fee_id and amount required'];
        }

        $fees = Database::collection('fees');
        $payments = Database::collection('payments');

        $fee = $fees->findOne(['_id' => new MongoDB\BSON\ObjectId($data['fee_id'])]);
        if (!$fee) {
            http_response_code(404);
            return ['error' => 'Fee not found'];
        }

        if ($fee['status'] === 'paid') {
            http_response_code(400);
            return ['error' => 'Already fully paid'];
        }

        $amount = (float)$data['amount'];
        $txnId = 'FPX' . strtoupper(bin2hex(random_bytes(8)));

        $payment = [
            'student_id' => $authUser['id'],
            'fee_id' => $data['fee_id'],
            'amount' => $amount,
            'method' => $data['method'] ?? 'fpx',
            'bank' => $data['bank'] ?? '',
            'txn_id' => $txnId,
            'status' => 'paid',
            'reference' => $data['reference'] ?? null,
            'paid_at' => new MongoDB\BSON\UTCDateTime()
        ];

        $payments->insertOne($payment);

        // Update fee
        $newPaid = ($fee['paid_amount'] ?? 0) + $amount;
        $newStatus = $newPaid >= $fee['total_amount'] ? 'paid' : 'partial';

        $fees->updateOne(
            ['_id' => $fee['_id']],
            ['$set' => ['paid_amount' => $newPaid, 'status' => $newStatus]]
        );

        return [
            'payment' => [
                'txn_id' => $txnId,
                'amount' => $amount,
                'method' => $payment['method'],
                'bank' => $payment['bank'],
                'status' => 'paid'
            ],
            'fee' => [
                'paid_amount' => $newPaid,
                'status' => $newStatus
            ]
        ];
    }

    // GET /api/fees/payments/history - Payment history
    public static function history($authUser) {
        $payments = Database::collection('payments');
        $results = $payments->find(
            ['student_id' => $authUser['id']],
            ['sort' => ['paid_at' => -1]]
        )->toArray();

        $output = [];
        foreach ($results as $p) {
            $output[] = [
                'id' => (string)$p['_id'],
                'fee_id' => $p['fee_id'] ?? '',
                'amount' => $p['amount'] ?? 0,
                'method' => $p['method'] ?? 'fpx',
                'method_label' => ($p['method'] ?? 'fpx') === 'fpx' ? 'FPX Online Banking' : 'Credit/Debit Card',
                'bank' => $p['bank'] ?? '',
                'txn_id' => $p['txn_id'] ?? '',
                'status' => $p['status'] ?? 'pending',
                'reference' => $p['reference'] ?? '',
                'paid_at' => isset($p['paid_at']) ? (string)$p['paid_at'] : null,
            ];
        }
        return ['payments' => $output];
    }
}
