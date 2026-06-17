-- ========================================
-- TestPilot Phase 0: 初始化建库建表
-- 使用方法: 在 MySQL 中执行本文件
-- ========================================

CREATE DATABASE IF NOT EXISTS testpilot
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE testpilot;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(120) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    nickname VARCHAR(50) DEFAULT '',
    role VARCHAR(20) DEFAULT 'viewer',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_username (username),
    INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 插入默认管理员 (密码: admin123)
INSERT INTO users (id, username, email, hashed_password, nickname, role)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin',
    'admin@testpilot.local',
    '$2b$12$LJ3m4ys3Lk0TSwHlvFQyGOdkxTI5TW3vKQEBFK3Tqh5PjPFvbQyCa',
    '系统管理员',
    'admin'
) ON DUPLICATE KEY UPDATE username=username;
