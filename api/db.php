<?php
/**
 * MAPAS BONITOS - Database Connection
 * PDO wrapper with prepared statements
 */

require_once __DIR__ . '/config.php';

class Database {
    private static $instance = null;
    private $pdo;
    
    private function __construct() {
        $config = Config::getInstance();
        
        $host = $config->get('DB_HOST');
        $dbname = $config->get('DB_NAME');
        $user = $config->get('DB_USER');
        $pass = $config->get('DB_PASS');
        $charset = $config->get('DB_CHARSET');
        
        if (!$dbname || !$user || !$pass) {
            throw new RuntimeException('Database credentials not configured in .env');
        }
        
        $dsn = "mysql:host={$host};dbname={$dbname};charset={$charset}";
        
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ];
        
        try {
            $this->pdo = new PDO($dsn, $user, $pass, $options);
        } catch (PDOException $e) {
            throw new RuntimeException('Database connection failed: ' . $e->getMessage());
        }
    }
    
    public static function getInstance(): Database {
        if (self::$instance === null) {
            self::$instance = new Database();
        }
        return self::$instance;
    }
    
    public function getPdo(): PDO {
        return $this->pdo;
    }
    
    public function query(string $sql, array $params = []): PDOStatement {
        $stmt = $this->pdo->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }
    
    public function fetch(string $sql, array $params = []): ?array {
        $stmt = $this->query($sql, $params);
        $result = $stmt->fetch();
        return $result ?: null;
    }
    
    public function fetchAll(string $sql, array $params = []): array {
        $stmt = $this->query($sql, $params);
        return $stmt->fetchAll();
    }
    
    public function insert(string $table, array $data): int {
        $columns = implode(', ', array_keys($data));
        $placeholders = implode(', ', array_fill(0, count($data), '?'));
        
        $sql = "INSERT INTO {$table} ({$columns}) VALUES ({$placeholders})";
        $this->query($sql, array_values($data));
        
        return (int) $this->pdo->lastInsertId();
    }
    
    public function update(string $table, array $data, string $where, array $whereParams = []): int {
        $set = implode(' = ?, ', array_keys($data)) . ' = ?';
        
        $sql = "UPDATE {$table} SET {$set} WHERE {$where}";
        $stmt = $this->query($sql, array_merge(array_values($data), $whereParams));
        
        return $stmt->rowCount();
    }
    
    public function lastInsertId(): string {
        return $this->pdo->lastInsertId();
    }
}
