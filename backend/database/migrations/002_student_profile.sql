-- Migration: Add student profile fields
ALTER TABLE users
  ADD COLUMN dob DATE NULL AFTER branch_id,
  ADD COLUMN semester TINYINT NULL AFTER dob,
  ADD COLUMN roll_no VARCHAR(40) NULL AFTER semester,
  ADD COLUMN board_roll_no VARCHAR(40) NULL AFTER roll_no,
  ADD COLUMN college_name VARCHAR(200) NULL DEFAULT 'Govt. Polytechnic Kangra' AFTER board_roll_no,
  ADD COLUMN course_name VARCHAR(120) NULL AFTER college_name,
  ADD COLUMN guardian_name VARCHAR(120) NULL AFTER course_name,
  ADD COLUMN phone VARCHAR(20) NULL AFTER guardian_name,
  ADD COLUMN address TEXT NULL AFTER phone,
  ADD COLUMN admission_year YEAR NULL AFTER address,
  ADD COLUMN photo_url VARCHAR(500) NULL AFTER admission_year;
