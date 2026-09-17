<?php
declare(strict_types=1);

const DB_HOST = '127.0.0.1';
const DB_PORT = 3307;
const DB_NAME = 'motorstock_db';
const DB_USER = 'root';
const DB_PASS = 'root';
const DB_FALLBACK_PASS = '';

function db(): PDO {
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }
    $dsn = 'mysql:host=' . DB_HOST . ';port=' . DB_PORT . ';charset=utf8mb4';
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ];
    try {
        $pdo = new PDO($dsn, DB_USER, DB_PASS, $options);
    } catch (PDOException $e) {
        if (($e->errorInfo[1] ?? null) !== 1045 || DB_FALLBACK_PASS === DB_PASS) {
            throw $e;
        }
        $pdo = new PDO($dsn, DB_USER, DB_FALLBACK_PASS, $options);
    }
    $pdo->exec('CREATE DATABASE IF NOT EXISTS `' . DB_NAME . '` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci');
    $pdo->exec('USE `' . DB_NAME . '`');
    initialize_database($pdo);
    return $pdo;
}

function initialize_database(PDO $pdo): void {
    static $done = false;
    if ($done) {
        return;
    }
    $exists = $pdo->query("SHOW TABLES LIKE 'stores'")->fetchColumn();
    if (!$exists) {
        $schema = file_get_contents(__DIR__ . '/schema.sql');
        foreach (array_filter(array_map('trim', explode(';', (string)$schema))) as $statement) {
            if ($statement !== '') {
                $pdo->exec($statement);
            }
        }
        $pdo->exec('USE `' . DB_NAME . '`');
    }
    $done = true;
}

function json_response(array $payload): void {
    if (ob_get_length()) {
        ob_clean();
    }
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload);
    exit;
}

function request_body(): array {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw ?: '{}', true);
    return is_array($data) ? $data : [];
}
