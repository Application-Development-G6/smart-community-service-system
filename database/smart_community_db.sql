CREATE DATABASE IF NOT EXISTS smart_community_db;
USE smart_community_db;

CREATE TABLE IF NOT EXISTS users (
    id INT NOT NULL AUTO_INCREMENT,
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin') NOT NULL DEFAULT 'user',
    PRIMARY KEY (id),
    UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS complaints (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255) NOT NULL,
    photo_url VARCHAR(255) NULL,
    status ENUM('Pending', 'Ongoing', 'Resolved') NOT NULL DEFAULT 'Pending',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    CONSTRAINT fk_complaints_user
        FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB;

-- Add user_id to an existing complaints table if missing.
SET @has_user_id = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'complaints'
      AND COLUMN_NAME = 'user_id'
);

SET @sql = IF(
    @has_user_id = 0,
    'ALTER TABLE complaints ADD COLUMN user_id INT NULL AFTER id',
    'SELECT 1'
);

PREPARE complaint_migration FROM @sql;
EXECUTE complaint_migration;
DEALLOCATE PREPARE complaint_migration;

-- Add photo_url if missing.
SET @has_photo_url = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'complaints'
      AND COLUMN_NAME = 'photo_url'
);

SET @sql = IF(
    @has_photo_url = 0,
    'ALTER TABLE complaints ADD COLUMN photo_url VARCHAR(255) NULL AFTER location',
    'SELECT 1'
);

PREPARE complaint_migration FROM @sql;
EXECUTE complaint_migration;
DEALLOCATE PREPARE complaint_migration;

-- Add user foreign key if missing.
SET @has_user_foreign_key = (
    SELECT COUNT(*)
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'complaints'
      AND COLUMN_NAME = 'user_id'
      AND REFERENCED_TABLE_NAME = 'users'
      AND REFERENCED_COLUMN_NAME = 'id'
);

SET @sql = IF(
    @has_user_foreign_key = 0,
    'ALTER TABLE complaints ADD CONSTRAINT fk_complaints_user FOREIGN KEY (user_id) REFERENCES users(id)',
    'SELECT 1'
);

PREPARE complaint_migration FROM @sql;
EXECUTE complaint_migration;
DEALLOCATE PREPARE complaint_migration;
