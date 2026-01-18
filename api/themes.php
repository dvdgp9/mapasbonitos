<?php
/**
 * MAPAS BONITOS - Themes API Endpoint
 * GET: List all available themes
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/response.php';

Response::handleCors();

if (!isset($_SERVER['REQUEST_METHOD']) || $_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

$db = Database::getInstance();

$sql = "SELECT id, name, description, preview_bg, preview_road, config_json
        FROM themes 
        WHERE active = 1 
        ORDER BY sort_order ASC";

$themes = $db->fetchAll($sql);

$result = [];
foreach ($themes as $theme) {
    $config = json_decode($theme['config_json'], true);
    
    $result[] = [
        'id' => $theme['id'],
        'name' => $theme['name'],
        'description' => $theme['description'],
        'preview' => [
            'bg' => $theme['preview_bg'],
            'road' => $theme['preview_road'],
            'text' => $config['text'] ?? '#000000',
            'water' => $config['water'] ?? '#C0C0C0'
        ]
    ];
}

Response::success($result);
