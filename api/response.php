<?php
/**
 * MAPAS BONITOS - JSON Response Helper
 * Consistent API responses
 */

class Response {
    /**
     * Send JSON response and exit
     */
    public static function json($data, int $statusCode = 200): void {
        http_response_code($statusCode);
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type');
        
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
        exit;
    }
    
    /**
     * Send success response
     */
    public static function success($data = null, string $message = null): void {
        $response = ['success' => true];
        
        if ($message !== null) {
            $response['message'] = $message;
        }
        
        if ($data !== null) {
            $response['data'] = $data;
        }
        
        self::json($response, 200);
    }
    
    /**
     * Send error response
     */
    public static function error(string $message, int $statusCode = 400, array $details = []): void {
        $response = [
            'success' => false,
            'error' => $message
        ];
        
        if (!empty($details)) {
            $response['details'] = $details;
        }
        
        self::json($response, $statusCode);
    }
    
    /**
     * Send 404 Not Found
     */
    public static function notFound(string $message = 'Resource not found'): void {
        self::error($message, 404);
    }
    
    /**
     * Send 429 Too Many Requests
     */
    public static function rateLimited(int $retryAfter = 3600): void {
        header("Retry-After: {$retryAfter}");
        self::error('Rate limit exceeded. Please try again later.', 429, [
            'retry_after' => $retryAfter
        ]);
    }
    
    /**
     * Send 500 Internal Server Error
     */
    public static function serverError(string $message = 'Internal server error'): void {
        self::error($message, 500);
    }
    
    /**
     * Handle OPTIONS preflight request
     */
    public static function handleCors(): void {
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type');
        
        if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(204);
            exit;
        }
    }
}
