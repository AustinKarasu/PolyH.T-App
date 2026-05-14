ALTER TABLE tests
  ADD COLUMN IF NOT EXISTS scheduled_email_notified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS start_email_notified_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS email_otps (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose VARCHAR(40) NOT NULL,
  code_hash VARCHAR(64) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  consumed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_email_otps_user_purpose
  ON email_otps (user_id, purpose, expires_at);
