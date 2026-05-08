CREATE DATABASE IF NOT EXISTS polyht;
USE polyht;

CREATE TABLE branches (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL UNIQUE,
  code VARCHAR(20) NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE courses (
  id INT PRIMARY KEY AUTO_INCREMENT,
  branch_id INT NOT NULL,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(40) NOT NULL,
  semester TINYINT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_courses_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
  UNIQUE KEY uq_courses_branch_code (branch_id, code)
);

CREATE TABLE app_config (
  config_key VARCHAR(120) PRIMARY KEY,
  config_value JSON NOT NULL,
  updated_by INT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  full_name VARCHAR(120) NOT NULL,
  email VARCHAR(160) UNIQUE,
  college_id VARCHAR(60) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin', 'student') NOT NULL,
  branch_id INT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_users_branch FOREIGN KEY (branch_id) REFERENCES branches(id)
);

CREATE TABLE auth_sessions (
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

CREATE TABLE tests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  title VARCHAR(120) NOT NULL,
  branch_id INT NOT NULL,
  course_id INT NULL,
  original_filename VARCHAR(255) NOT NULL,
  stored_filename VARCHAR(255) NOT NULL,
  file_path VARCHAR(500) NOT NULL,
  scheduled_start DATETIME NOT NULL,
  scheduled_end DATETIME NOT NULL,
  time_limit_minutes INT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_tests_branch FOREIGN KEY (branch_id) REFERENCES branches(id),
  CONSTRAINT fk_tests_course FOREIGN KEY (course_id) REFERENCES courses(id),
  CONSTRAINT fk_tests_created_by FOREIGN KEY (created_by) REFERENCES users(id),
  INDEX idx_tests_branch_schedule (branch_id, scheduled_start, scheduled_end)
);

CREATE TABLE test_attempts (
  id INT PRIMARY KEY AUTO_INCREMENT,
  test_id INT NOT NULL,
  student_id INT NOT NULL,
  started_at DATETIME NOT NULL,
  last_seen_at DATETIME NULL,
  completed_at DATETIME NULL,
  blocked_at DATETIME NULL,
  blocked_reason VARCHAR(255) NULL,
  allowed_by INT NULL,
  allowed_at DATETIME NULL,
  status ENUM('started', 'completed', 'expired', 'blocked', 'admin_allowed') NOT NULL DEFAULT 'started',
  answer_note TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_attempts_test FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
  CONSTRAINT fk_attempts_student FOREIGN KEY (student_id) REFERENCES users(id),
  CONSTRAINT fk_attempts_allowed_by FOREIGN KEY (allowed_by) REFERENCES users(id),
  UNIQUE KEY uq_attempt_student_test (test_id, student_id)
);

CREATE TABLE exam_events (
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

INSERT INTO branches (name, code) VALUES
  ('Computer Engg', 'CE'),
  ('Mechanical Engg', 'ME'),
  ('Electrical Engg', 'EE'),
  ('Instrumental Engg', 'IE'),
  ('Electronic Engg', 'EC'),
  ('Civil Engg', 'CE')
ON DUPLICATE KEY UPDATE name = VALUES(name);
