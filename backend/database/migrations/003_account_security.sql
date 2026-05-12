ALTER TABLE users
  ADD COLUMN IF NOT EXISTS two_factor_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS two_factor_secret VARCHAR(160),
  ADD COLUMN IF NOT EXISTS is_primary_admin BOOLEAN NOT NULL DEFAULT FALSE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_one_primary_admin
  ON users (role)
  WHERE role = 'admin' AND is_primary_admin = TRUE;

UPDATE users
SET is_primary_admin = TRUE
WHERE id = (
  SELECT id FROM users
  WHERE role = 'admin' AND is_active = TRUE
  ORDER BY created_at ASC, id ASC
  LIMIT 1
)
AND NOT EXISTS (
  SELECT 1 FROM users WHERE role = 'admin' AND is_primary_admin = TRUE
);
