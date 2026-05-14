DROP TABLE IF EXISTS email_otps;

ALTER TABLE tests
  DROP COLUMN IF EXISTS scheduled_email_notified_at,
  DROP COLUMN IF EXISTS start_email_notified_at;
