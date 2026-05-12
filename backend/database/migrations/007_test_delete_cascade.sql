BEGIN;

ALTER TABLE test_attempts
  DROP CONSTRAINT IF EXISTS test_attempts_test_id_fkey,
  ADD CONSTRAINT test_attempts_test_id_fkey
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE;

ALTER TABLE exam_events
  DROP CONSTRAINT IF EXISTS exam_events_attempt_id_fkey,
  ADD CONSTRAINT exam_events_attempt_id_fkey
    FOREIGN KEY (attempt_id) REFERENCES test_attempts(id) ON DELETE SET NULL;

ALTER TABLE exam_events
  DROP CONSTRAINT IF EXISTS exam_events_test_id_fkey,
  ADD CONSTRAINT exam_events_test_id_fkey
    FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE;

COMMIT;
