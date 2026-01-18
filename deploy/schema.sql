-- ===========================================
-- MAPAS BONITOS - Database Schema
-- ===========================================
-- Run this script to create all required tables
-- mysql -u dvdgp_mapas_usr -p dvdgp_mapas < schema.sql

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------
-- Table: jobs
-- Cola de trabajos de generación de mapas
-- -------------------------------------------
DROP TABLE IF EXISTS `jobs`;
CREATE TABLE `jobs` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `location` VARCHAR(255) NOT NULL COMMENT 'Ciudad, País o dirección completa',
    `theme` VARCHAR(50) NOT NULL DEFAULT 'noir' COMMENT 'ID del tema',
    `distance` INT UNSIGNED NOT NULL DEFAULT 10000 COMMENT 'Radio en metros',
    `title` VARCHAR(100) DEFAULT NULL COMMENT 'Título personalizado (opcional)',
    `subtitle` VARCHAR(100) DEFAULT NULL COMMENT 'Subtítulo personalizado (opcional)',
    `status` ENUM('queued', 'running', 'done', 'error') NOT NULL DEFAULT 'queued',
    `result_path` VARCHAR(255) DEFAULT NULL COMMENT 'Ruta relativa al mapa generado',
    `latitude` DECIMAL(10, 7) DEFAULT NULL,
    `longitude` DECIMAL(10, 7) DEFAULT NULL,
    `error_message` TEXT DEFAULT NULL,
    `ip_hash` VARCHAR(64) DEFAULT NULL COMMENT 'Hash SHA256 de IP para rate limiting',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `started_at` TIMESTAMP NULL DEFAULT NULL,
    `finished_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    INDEX `idx_status_created` (`status`, `created_at`),
    INDEX `idx_ip_hash` (`ip_hash`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------
-- Table: geocode_cache
-- Caché de geocodificación (Nominatim)
-- -------------------------------------------
DROP TABLE IF EXISTS `geocode_cache`;
CREATE TABLE `geocode_cache` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `query_hash` VARCHAR(32) NOT NULL COMMENT 'MD5 hash del query normalizado',
    `query` VARCHAR(255) NOT NULL COMMENT 'Query original',
    `latitude` DECIMAL(10, 7) NOT NULL,
    `longitude` DECIMAL(10, 7) NOT NULL,
    `display_name` VARCHAR(500) DEFAULT NULL COMMENT 'Nombre completo devuelto por Nominatim',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NOT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_query_hash` (`query_hash`),
    INDEX `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------
-- Table: rate_limits
-- Control de rate limiting por IP
-- -------------------------------------------
DROP TABLE IF EXISTS `rate_limits`;
CREATE TABLE `rate_limits` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `ip_hash` VARCHAR(64) NOT NULL COMMENT 'Hash SHA256 de IP',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_ip_created` (`ip_hash`, `created_at`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------
-- Table: themes
-- Catálogo de temas disponibles
-- -------------------------------------------
DROP TABLE IF EXISTS `themes`;
CREATE TABLE `themes` (
    `id` VARCHAR(50) NOT NULL COMMENT 'Identificador único (slug)',
    `name` VARCHAR(100) NOT NULL COMMENT 'Nombre para mostrar',
    `description` VARCHAR(500) DEFAULT NULL,
    `config_json` JSON NOT NULL COMMENT 'Configuración completa del tema',
    `preview_bg` VARCHAR(7) NOT NULL COMMENT 'Color de fondo para preview (#XXXXXX)',
    `preview_road` VARCHAR(7) NOT NULL COMMENT 'Color de carretera principal para preview',
    `sort_order` INT NOT NULL DEFAULT 0,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    INDEX `idx_active_sort` (`active`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------
-- Cleanup event for expired cache and rate limits
-- Run manually or set up as cron if events not available
-- -------------------------------------------
-- DELETE FROM geocode_cache WHERE expires_at < NOW();
-- DELETE FROM rate_limits WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 HOUR);

SET FOREIGN_KEY_CHECKS = 1;

-- Success message
SELECT 'Schema created successfully!' AS message;
