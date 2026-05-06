<?php
require_once __DIR__ . '/../../../config/database.php';

class CurriculumController {
    // GET /api/curriculum
    public static function all($query) {
        $activities = Database::collection('activities');
        $filter = [];
        if (!empty($query['category'])) $filter['category'] = $query['category'];
        if (!empty($query['status'])) $filter['status'] = $query['status'];
        $results = $activities->find($filter, ['sort' => ['date' => -1]])->toArray();
        $output = [];
        foreach ($results as $a) {
            $output[] = self::format($a);
        }
        return $output;
    }

    // POST /api/curriculum/:id/join
    public static function join($authUser, $activityId) {
        $activities = Database::collection('activities');
        $activity = $activities->findOne(['_id' => new MongoDB\BSON\ObjectId($activityId)]);
        if (!$activity) { http_response_code(404); return ['error' => 'Activity not found']; }

        $participants = $activity['participants'] ?? [];
        if (in_array($authUser['id'], $participants)) { http_response_code(400); return ['error' => 'Already joined']; }
        if (count($participants) >= ($activity['capacity'] ?? 100)) { http_response_code(400); return ['error' => 'Activity is full']; }

        $activities->updateOne(['_id' => $activity['_id']], ['$push' => ['participants' => $authUser['id']]]);
        return ['status' => 'joined'];
    }

    // POST /api/curriculum/:id/leave
    public static function leave($authUser, $activityId) {
        $activities = Database::collection('activities');
        $activities->updateOne(['_id' => new MongoDB\BSON\ObjectId($activityId)], ['$pull' => ['participants' => $authUser['id']]]);
        return ['status' => 'left'];
    }

    // GET /api/curriculum/my/joined
    public static function myJoined($authUser) {
        $activities = Database::collection('activities');
        $results = $activities->find(['participants' => $authUser['id']], ['sort' => ['date' => -1]])->toArray();
        $output = [];
        foreach ($results as $a) { $output[] = self::format($a); }
        return $output;
    }

    // POST /api/curriculum (admin create)
    public static function create($data) {
        $activities = Database::collection('activities');
        $data['participants'] = [];
        $data['created_at'] = new MongoDB\BSON\UTCDateTime();
        $activities->insertOne($data);
        return $data;
    }

    private static function format($a) {
        return [
            '_id' => (string)$a['_id'],
            'name' => $a['name'] ?? '',
            'description' => $a['description'] ?? '',
            'category' => $a['category'] ?? '',
            'organizer' => $a['organizer'] ?? '',
            'venue' => $a['venue'] ?? '',
            'capacity' => $a['capacity'] ?? 100,
            'participants' => $a['participants'] ?? [],
            'points' => $a['points'] ?? 0,
            'status' => $a['status'] ?? 'upcoming',
        ];
    }
}
