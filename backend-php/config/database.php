<?php
require_once __DIR__ . '/config.php';

class Database {
    private static $client = null;
    private static $db = null;

    public static function connect() {
        if (self::$client === null) {
            self::$client = new MongoDB\Client(MONGO_URI);
            self::$db = self::$client->selectDatabase(MONGO_DB);
        }
        return self::$db;
    }

    public static function collection($name) {
        return self::connect()->selectCollection($name);
    }
}
