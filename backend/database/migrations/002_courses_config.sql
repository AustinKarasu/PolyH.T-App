USE polyht;

CREATE TABLE IF NOT EXISTS courses (
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

CREATE TABLE IF NOT EXISTS app_config (
  config_key VARCHAR(120) PRIMARY KEY,
  config_value JSON NOT NULL,
  updated_by INT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

ALTER TABLE tests
  ADD COLUMN course_id INT NULL AFTER branch_id,
  ADD CONSTRAINT fk_tests_course FOREIGN KEY (course_id) REFERENCES courses(id);
