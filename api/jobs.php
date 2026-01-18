<?php
/**
 * MAPAS BONITOS - Jobs API Endpoint
 * POST: Create new job
 * GET:  Get job status
 */

require_once __DIR__ . '/config.php';
require_once __DIR__ . '/db.php';
require_once __DIR__ . '/rate_limiter.php';
require_once __DIR__ . '/response.php';

Response::handleCors();

$db = Database::getInstance();
$rateLimiter = new RateLimiter();

// Route by method
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';
switch ($method) {
    case 'GET':
        handleGetJob($db);
        break;
    case 'POST':
        handleCreateJob($db, $rateLimiter);
        break;
    default:
        Response::error('Method not allowed', 405);
}

/**
 * GET /api/jobs.php?id={job_id}
 * Returns job status and result if available
 */
function handleGetJob(Database $db): void {
    $jobId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
    
    if (!$jobId) {
        Response::error('Job ID is required', 400);
    }
    
    $sql = "SELECT id, location, theme, distance, title, subtitle, status, 
                   result_path, latitude, longitude, error_message,
                   created_at, started_at, finished_at
            FROM jobs WHERE id = ?";
    
    $job = $db->fetch($sql, [$jobId]);
    
    if (!$job) {
        Response::notFound('Job not found');
    }
    
    // Build response
    $response = [
        'id' => (int) $job['id'],
        'location' => $job['location'],
        'theme' => $job['theme'],
        'distance' => (int) $job['distance'],
        'status' => $job['status'],
        'created_at' => $job['created_at']
    ];
    
    if ($job['title']) {
        $response['title'] = $job['title'];
    }
    if ($job['subtitle']) {
        $response['subtitle'] = $job['subtitle'];
    }
    
    // Add timing info
    if ($job['started_at']) {
        $response['started_at'] = $job['started_at'];
    }
    if ($job['finished_at']) {
        $response['finished_at'] = $job['finished_at'];
    }
    
    // Add result info for completed jobs
    if ($job['status'] === 'done' && $job['result_path']) {
        $response['result_url'] = '/api/download.php?id=' . $job['id'];
        $response['latitude'] = (float) $job['latitude'];
        $response['longitude'] = (float) $job['longitude'];
    }
    
    // Add error info for failed jobs
    if ($job['status'] === 'error' && $job['error_message']) {
        $response['error_message'] = $job['error_message'];
    }
    
    Response::success($response);
}

/**
 * POST /api/jobs.php
 * Creates a new map generation job
 * Body: {location, theme?, distance?, title?, subtitle?}
 */
function handleCreateJob(Database $db, RateLimiter $rateLimiter): void {
    // Check rate limit
    if ($rateLimiter->isLimited()) {
        Response::rateLimited($rateLimiter->getResetTime());
    }
    
    // Parse JSON body
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (json_last_error() !== JSON_ERROR_NONE) {
        Response::error('Invalid JSON body', 400);
    }
    
    // Validate required fields
    $location = trim($input['location'] ?? '');
    if (empty($location)) {
        Response::error('Location is required', 400);
    }
    if (strlen($location) > 255) {
        Response::error('Location must be 255 characters or less', 400);
    }
    
    // Validate theme
    $theme = trim($input['theme'] ?? 'noir');
    if (!validateTheme($db, $theme)) {
        Response::error('Invalid theme: ' . $theme, 400);
    }
    
    // Validate distance (4000 - 25000 meters)
    $distance = (int) ($input['distance'] ?? 10000);
    if ($distance < 4000 || $distance > 25000) {
        Response::error('Distance must be between 4000 and 25000 meters', 400);
    }
    
    // Optional fields
    $title = isset($input['title']) ? trim($input['title']) : null;
    $subtitle = isset($input['subtitle']) ? trim($input['subtitle']) : null;
    
    if ($title && strlen($title) > 100) {
        Response::error('Title must be 100 characters or less', 400);
    }
    if ($subtitle && strlen($subtitle) > 100) {
        Response::error('Subtitle must be 100 characters or less', 400);
    }
    
    // Create job
    $jobData = [
        'location' => $location,
        'theme' => $theme,
        'distance' => $distance,
        'title' => $title,
        'subtitle' => $subtitle,
        'status' => 'queued',
        'ip_hash' => $rateLimiter->getIpHash()
    ];
    
    $jobId = $db->insert('jobs', $jobData);
    
    // Record rate limit
    $rateLimiter->record();
    
    // Return created job
    Response::success([
        'id' => $jobId,
        'status' => 'queued',
        'location' => $location,
        'theme' => $theme,
        'distance' => $distance,
        'remaining_requests' => $rateLimiter->getRemaining()
    ], 'Job created successfully');
}

/**
 * Check if theme exists and is active
 */
function validateTheme(Database $db, string $themeId): bool {
    $sql = "SELECT id FROM themes WHERE id = ? AND active = 1";
    $result = $db->fetch($sql, [$themeId]);
    return $result !== null;
}
