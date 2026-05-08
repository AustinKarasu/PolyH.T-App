USE polyht;

CREATE TABLE IF NOT EXISTS auth_sessions (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  token_jti CHAR(36) NOT NULL UNIQUE,
  device_label VARCHAR(160) NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(500) NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_sessions_user_active (user_id, revoked_at, expires_at)
);

ALTER TABLE test_attempts
  ADD COLUMN last_seen_at DATETIME NULL AFTER started_at,
  ADD COLUMN blocked_at DATETIME NULL AFTER completed_at,
  ADD COLUMN blocked_reason VARCHAR(255) NULL AFTER blocked_at,
  ADD COLUMN allowed_by INT NULL AFTER blocked_reason,
  ADD COLUMN allowed_at DATETIME NULL AFTER allowed_by,
  MODIFY COLUMN status ENUM('started', 'completed', 'expired', 'blocked', 'admin_allowed') NOT NULL DEFAULT 'started',
  ADD CONSTRAINT fk_attempts_allowed_by FOREIGN KEY (allowed_by) REFERENCES users(id);

CREATE TABLE IF NOT EXISTS exam_events (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  attempt_id INT NULL,
  test_id INT NOT NULL,
  student_id INT NOT NULL,
  branch_id INT NOT NULL,
  event_type ENUM(
    'login',
    'test_list_opened',
    'attempt_started',
    'pdf_requested',
    'pdf_opened',
    'app_inactive',
    'app_backgrounded',
    'app_resumed',
    'app_detached',
    'back_blocked',
    'submit_completed',
    'blocked',
    'admin_allowed'
  ) NOT NULL,
  severity ENUM('info', 'warning', 'critical') NOT NULL DEFAULT 'info',
  message VARCHAR(500) NULL,
  metadata JSON NULL,
  ip_address VARCHAR(64) NULL,
  user_agent VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_events_attempt FOREIGN KEY (attempt_id) REFERENCES test_attempts(id) ON DELETE SET NULL,
  CONSTRAINT fk_events_test FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
  CONSTRAINT fk_events_student FOREIGN KEY (student_id) REFERENCES users(id),
  CONSTRAINT fk_events_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
  INDEX idx_events_branch_created (branch_id, created_at),
  INDEX idx_events_test_student_created (test_id, student_id, created_at)
);
