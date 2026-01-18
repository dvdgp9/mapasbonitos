<?php
/**
 * MAPAS BONITOS - Rate Limiter
 * MySQL-based rate limiting by IP
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';

class RateLimiter {
    private $db;
    private $maxJobs;
    private $windowHours;
    
    public function __construct() {
        $this->db = Database::getInstance();
        $config = Config::getInstance();
        
        $this->maxJobs = (int) $config->get('RATE_LIMIT_MAX_JOBS', 5);
        $this->windowHours = (int) $config->get('RATE_LIMIT_WINDOW_HOURS', 1);
    }
    
    /**
     * Get hashed IP address for privacy
     */
    public function getIpHash(): string {
        $ip = $this->getClientIp();
        return hash('sha256', $ip . 'mapasbonitos_salt');
    }
    
    /**
     * Get client IP address
     */
    private function getClientIp(): string {
        $headers = [
            'HTTP_CF_CONNECTING_IP',     // Cloudflare
            'HTTP_X_FORWARDED_FOR',      // Proxies
            'HTTP_X_REAL_IP',            // Nginx
            'REMOTE_ADDR'
        ];
        
        foreach ($headers as $header) {
            if (!empty($_SERVER[$header])) {
                $ips = explode(',', $_SERVER[$header]);
                $ip = trim($ips[0]);
                if (filter_var($ip, FILTER_VALIDATE_IP)) {
                    return $ip;
                }
            }
        }
        
        return '127.0.0.1';
    }
    
    /**
     * Check if IP is rate limited
     */
    public function isLimited(): bool {
        $ipHash = $this->getIpHash();
        
        // Clean old entries first (lazy cleanup)
        $this->cleanup();
        
        // Count requests in window
        $sql = "SELECT COUNT(*) as count FROM rate_limits 
                WHERE ip_hash = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? HOUR)";
        
        $result = $this->db->fetch($sql, [$ipHash, $this->windowHours]);
        $count = $result ? (int) $result['count'] : 0;
        
        return $count >= $this->maxJobs;
    }
    
    /**
     * Record a new request
     */
    public function record(): void {
        $this->db->insert('rate_limits', [
            'ip_hash' => $this->getIpHash()
        ]);
    }
    
    /**
     * Get remaining requests for current IP
     */
    public function getRemaining(): int {
        $ipHash = $this->getIpHash();
        
        $sql = "SELECT COUNT(*) as count FROM rate_limits 
                WHERE ip_hash = ? AND created_at > DATE_SUB(NOW(), INTERVAL ? HOUR)";
        
        $result = $this->db->fetch($sql, [$ipHash, $this->windowHours]);
        $count = $result ? (int) $result['count'] : 0;
        
        return max(0, $this->maxJobs - $count);
    }
    
    /**
     * Get seconds until rate limit resets
     */
    public function getResetTime(): int {
        $ipHash = $this->getIpHash();
        
        $sql = "SELECT created_at FROM rate_limits 
                WHERE ip_hash = ? 
                ORDER BY created_at ASC 
                LIMIT 1";
        
        $result = $this->db->fetch($sql, [$ipHash]);
        
        if (!$result) {
            return 0;
        }
        
        $oldest = strtotime($result['created_at']);
        $resetAt = $oldest + ($this->windowHours * 3600);
        
        return max(0, $resetAt - time());
    }
    
    /**
     * Clean old rate limit entries
     */
    private function cleanup(): void {
        // Only cleanup occasionally (1% chance per request)
        if (rand(1, 100) === 1) {
            $sql = "DELETE FROM rate_limits WHERE created_at < DATE_SUB(NOW(), INTERVAL ? HOUR)";
            $this->db->query($sql, [$this->windowHours * 2]);
        }
    }
}
