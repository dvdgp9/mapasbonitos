<?php
/**
 * MAPAS BONITOS - Configuration Manager
 * Loads environment variables from .env file
 */

class Config {
    private static $instance = null;
    private $config = [];
    
    private function __construct() {
        $this->loadEnv();
    }
    
    public static function getInstance(): Config {
        if (self::$instance === null) {
            self::$instance = new Config();
        }
        return self::$instance;
    }
    
    private function loadEnv(): void {
        $projectRoot = dirname(__DIR__);
        
        // Try private/.env first, then root .env
        $envPaths = [
            $projectRoot . '/private/.env',
            $projectRoot . '/.env'
        ];
        
        $envFile = null;
        foreach ($envPaths as $path) {
            if (file_exists($path)) {
                $envFile = $path;
                break;
            }
        }
        
        if ($envFile === null) {
            throw new RuntimeException('No .env file found. Copy .env.example to private/.env');
        }
        
        $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        
        foreach ($lines as $line) {
            // Skip comments
            if (strpos(trim($line), '#') === 0) {
                continue;
            }
            
            // Parse KEY=value
            if (strpos($line, '=') !== false) {
                list($key, $value) = explode('=', $line, 2);
                $key = trim($key);
                $value = trim($value);
                
                // Remove quotes if present
                if (preg_match('/^(["\'])(.*)\\1$/', $value, $matches)) {
                    $value = $matches[2];
                }
                
                $this->config[$key] = $value;
            }
        }
        
        // Set defaults
        $defaults = [
            'DB_HOST' => 'localhost',
            'DB_CHARSET' => 'utf8mb4',
            'APP_ENV' => 'production',
            'APP_DEBUG' => 'false',
            'STORAGE_PATH' => 'storage/renders',
            'THEMES_PATH' => 'maptoposter-main/themes',
            'FONTS_PATH' => 'maptoposter-main/fonts',
            'RATE_LIMIT_MAX_JOBS' => '5',
            'RATE_LIMIT_WINDOW_HOURS' => '1',
            'WORKER_POLL_INTERVAL' => '2',
            'GEOCODE_CACHE_TTL' => '2592000'
        ];
        
        foreach ($defaults as $key => $value) {
            if (!isset($this->config[$key])) {
                $this->config[$key] = $value;
            }
        }
    }
    
    public function get(string $key, $default = null) {
        return $this->config[$key] ?? $default;
    }
    
    public function isDebug(): bool {
        return strtolower($this->get('APP_DEBUG', 'false')) === 'true';
    }
    
    public function getProjectRoot(): string {
        return dirname(__DIR__);
    }
    
    public function getStoragePath(): string {
        return $this->getProjectRoot() . '/' . $this->get('STORAGE_PATH');
    }
}
