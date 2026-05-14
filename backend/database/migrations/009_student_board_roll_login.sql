CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_student_board_roll_no
  ON users (board_roll_no)
  WHERE role = 'student' AND board_roll_no IS NOT NULL AND board_roll_no <> '';
