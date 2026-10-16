-- ============================================================
-- Fem-Psych Monitor — Skema Database MySQL
-- Import file ini di cPanel > phpMyAdmin untuk membuat tabel.
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  uid VARCHAR(128) NOT NULL PRIMARY KEY,
  name VARCHAR(255) NOT NULL DEFAULT 'User',
  email VARCHAR(255) DEFAULT '',
  bigfive_scores TEXT NULL,
  psych_score INT NULL,
  is_premium TINYINT(1) NOT NULL DEFAULT 0,
  premium_expiry DATETIME NULL,
  subscription_token VARCHAR(512) NULL,
  subscription_product_id VARCHAR(255) NULL,
  is_admin TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NULL,
  updated_at DATETIME NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recordings (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  uid VARCHAR(128) NOT NULL,
  date DATETIME NOT NULL,
  dominant_emotion VARCHAR(20) NOT NULL,
  confidence DOUBLE NOT NULL DEFAULT 0,
  suggestion TEXT NULL,
  audio_emotions TEXT NULL,
  transcript_emotions TEXT NULL,
  transcript_text TEXT NULL,
  duration_seconds INT NOT NULL DEFAULT 0,
  trigger_tag VARCHAR(50) NOT NULL DEFAULT '',
  audio_url VARCHAR(500) NOT NULL DEFAULT '',
  INDEX idx_recordings_uid (uid),
  CONSTRAINT fk_recordings_uid FOREIGN KEY (uid) REFERENCES users(uid) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS emotion_snapshots (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  recording_id INT UNSIGNED NOT NULL,
  emotion VARCHAR(20) NOT NULL,
  confidence DOUBLE NOT NULL DEFAULT 0,
  source VARCHAR(20) NOT NULL DEFAULT 'combined',
  timestamp DATETIME NOT NULL,
  INDEX idx_snapshots_recording (recording_id),
  CONSTRAINT fk_snapshots_recording FOREIGN KEY (recording_id) REFERENCES recordings(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
