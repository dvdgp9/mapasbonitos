<?php
/**
 * MAPAS BONITOS - Download API Endpoint
 * GET: Download generated map
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/response.php';

Response::handleCors();

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    Response::error('Method not allowed', 405);
}

$jobId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);

if (!$jobId) {
    Response::error('Job ID is required', 400);
}

$db = Database::getInstance();
$config = Config::getInstance();

// Get job info
$sql = "SELECT id, location, theme, status, result_path FROM jobs WHERE id = ?";
$job = $db->fetch($sql, [$jobId]);

if (!$job) {
    Response::notFound('Job not found');
}

if ($job['status'] !== 'done') {
    Response::error('Map not ready yet. Status: ' . $job['status'], 400);
}

if (empty($job['result_path'])) {
    Response::error('No result file available', 400);
}

// Build file path - protect against path traversal
$resultPath = $job['result_path'];

// Validate path doesn't contain traversal attempts
if (strpos($resultPath, '..') !== false || strpos($resultPath, '//') !== false) {
    Response::error('Invalid file path', 400);
}

$storagePath = $config->getStoragePath();
$filePath = $storagePath . '/' . $resultPath;

// Resolve to absolute path and verify it's within storage
$realPath = realpath($filePath);
$realStoragePath = realpath($storagePath);

if ($realPath === false) {
    Response::notFound('File not found');
}

if (strpos($realPath, $realStoragePath) !== 0) {
    Response::error('Access denied', 403);
}

if (!file_exists($realPath) || !is_readable($realPath)) {
    Response::notFound('File not found or not readable');
}

// Generate download filename
$city = preg_replace('/[^a-zA-Z0-9_-]/', '_', $job['location']);
$city = substr($city, 0, 50);
$filename = "mapa_{$city}_{$job['theme']}.png";

// Send file
header('Content-Type: image/png');
header('Content-Disposition: attachment; filename="' . $filename . '"');
header('Content-Length: ' . filesize($realPath));
header('Cache-Control: public, max-age=86400');

readfile($realPath);
exit;
