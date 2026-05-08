USE polyht;

INSERT INTO users (full_name, email, password_hash, role, is_active)
VALUES (
  'GPK House Test Admin',
  'gpkangra@housetest.in',
  '$2a$12$uLuKbKtEWVjSsvHPtqdD8eqgYHxaJNvP6zm7S4L1G/CzWSoflUk0m',
  'admin',
  TRUE
)
ON DUPLICATE KEY UPDATE
  full_name = VALUES(full_name),
  password_hash = VALUES(password_hash),
  role = 'admin',
  is_active = TRUE;
