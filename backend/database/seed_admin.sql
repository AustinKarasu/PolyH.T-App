-- Optional first-admin seed for PostgreSQL/Supabase.
-- Replace every value before running. Do not commit real password hashes.

INSERT INTO users (full_name, email, password_hash, role, is_active)
VALUES (
  '<Admin Full Name>',
  '<admin-email@example.edu>',
  '<bcrypt-password-hash>',
  'admin',
  TRUE
)
ON CONFLICT (email) DO UPDATE SET
  full_name = EXCLUDED.full_name,
  password_hash = EXCLUDED.password_hash,
  role = 'admin',
  is_active = TRUE,
  updated_at = CURRENT_TIMESTAMP;
