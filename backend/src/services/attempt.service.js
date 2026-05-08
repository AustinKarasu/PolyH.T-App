const { pool } = require('../config/db');
const { ApiError } = require('../utils/api-error');

const blockingEvents = new Set(['app_backgrounded', 'app_detached', 'back_blocked']);
const warningEvents = new Set(['app_inactive', 'app_resumed']);

async function startAttempt(testId, user, context = {}) {
  const test = await getAssignedLiveTest(testId, user.branchId);
  const existing = await getAttemptByStudent(testId, user.sub);

  if (existing?.status === 'blocked') {
    throw new ApiError(423, 'Attempt is locked. Admin permission is required to reopen this paper.');
  }
  if (existing?.status === 'completed') {
    throw new ApiError(409, 'This attempt has already been submitted.');
  }

  if (existing) {
    await pool.execute(
      `UPDATE test_attempts
       SET last_seen_at = CURRENT_TIMESTAMP,
           status = CASE WHEN status = 'admin_allowed' THEN 'started' ELSE status END
       WHERE id = :attemptId`,
      { attemptId: existing.id }
    );
    await recordEvent({
      attemptId: existing.id,
      testId,
      studentId: user.sub,
      branchId: test.branch_id,
      eventType: 'attempt_started',
      message: 'Student reopened the test paper after a valid start request.',
      context
    });
    return { ...existing, status: 'started' };
  }

  const [result] = await pool.execute(
    `INSERT INTO test_attempts (test_id, student_id, started_at, last_seen_at, status)
     VALUES (:testId, :studentId, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 'started')`,
    { testId, studentId: user.sub }
  );

  await recordEvent({
    attemptId: result.insertId,
    testId,
    studentId: user.sub,
    branchId: test.branch_id,
    eventType: 'attempt_started',
    message: 'Student started the test paper.',
    context
  });

  return { id: result.insertId, status: 'started' };
}

async function completeAttempt(testId, user, answerNote, context = {}) {
  const attempt = await getAttemptByStudent(testId, user.sub);
  if (!attempt) {
    throw new ApiError(404, 'Attempt not found');
  }
  if (attempt.status === 'blocked') {
    throw new ApiError(423, 'Attempt is locked. Admin permission is required before submission.');
  }

  await pool.execute(
    `UPDATE test_attempts
     SET completed_at = CURRENT_TIMESTAMP,
         last_seen_at = CURRENT_TIMESTAMP,
         status = 'completed',
         answer_note = :answerNote
     WHERE id = :attemptId`,
    { attemptId: attempt.id, answerNote: answerNote || null }
  );

  await recordEvent({
    attemptId: attempt.id,
    testId,
    studentId: user.sub,
    branchId: attempt.branch_id,
    eventType: 'submit_completed',
    message: 'Student marked the physical-answer-sheet test complete.',
    context
  });
}

async function recordStudentEvent(testId, user, eventType, metadata = {}, context = {}) {
  const attempt = await getAttemptByStudent(testId, user.sub);
  if (!attempt) {
    throw new ApiError(404, 'Attempt not found');
  }

  let message = metadata.message || `Student event: ${eventType}`;
  let severity = warningEvents.has(eventType) ? 'warning' : 'info';

  if (blockingEvents.has(eventType)) {
    severity = 'critical';
    message = metadata.message || 'Student left or attempted to leave secure exam mode.';
    await blockAttempt(attempt.id, eventType);
  } else {
    await pool.execute(
      'UPDATE test_attempts SET last_seen_at = CURRENT_TIMESTAMP WHERE id = :attemptId',
      { attemptId: attempt.id }
    );
  }

  await recordEvent({
    attemptId: attempt.id,
    testId,
    studentId: user.sub,
    branchId: attempt.branch_id,
    eventType,
    severity,
    message,
    metadata,
    context
  });

  return { locked: blockingEvents.has(eventType) };
}

async function recordEvent({
  attemptId,
  testId,
  studentId,
  branchId,
  eventType,
  severity = 'info',
  message = null,
  metadata = null,
  context = {}
}) {
  await pool.execute(
    `INSERT INTO exam_events
       (attempt_id, test_id, student_id, branch_id, event_type, severity, message, metadata, ip_address, user_agent)
     VALUES
       (:attemptId, :testId, :studentId, :branchId, :eventType, :severity, :message, :metadata, :ipAddress, :userAgent)`,
    {
      attemptId: attemptId || null,
      testId,
      studentId,
      branchId,
      eventType,
      severity,
      message,
      metadata: metadata ? JSON.stringify(metadata) : null,
      ipAddress: context.ipAddress || null,
      userAgent: context.userAgent || null
    }
  );
}

async function listEvents(filters = {}) {
  const params = {
    branchId: filters.branchId || null,
    testId: filters.testId || null,
    studentId: filters.studentId || null,
    limit: Math.min(Number(filters.limit || 100), 500)
  };

  const [events] = await pool.execute(
    `SELECT e.id, e.attempt_id, e.test_id, e.student_id, e.branch_id, e.event_type,
            e.severity, e.message, e.metadata, e.ip_address, e.user_agent, e.created_at,
            u.full_name AS student_name, u.college_id, b.name AS branch_name, b.code AS branch_code,
            t.title AS test_title
     FROM exam_events e
     JOIN users u ON u.id = e.student_id
     JOIN branches b ON b.id = e.branch_id
     JOIN tests t ON t.id = e.test_id
     WHERE (:branchId IS NULL OR e.branch_id = :branchId)
       AND (:testId IS NULL OR e.test_id = :testId)
       AND (:studentId IS NULL OR e.student_id = :studentId)
     ORDER BY e.created_at DESC
     LIMIT ${params.limit}`,
    params
  );

  return events;
}

async function listLockedAttempts(filters = {}) {
  const params = { branchId: filters.branchId || null };
  const [attempts] = await pool.execute(
    `SELECT a.id, a.test_id, a.student_id, a.status, a.started_at, a.last_seen_at,
            a.blocked_at, a.blocked_reason, a.allowed_at,
            u.full_name AS student_name, u.college_id,
            b.name AS branch_name, b.code AS branch_code,
            t.title AS test_title
     FROM test_attempts a
     JOIN users u ON u.id = a.student_id
     JOIN tests t ON t.id = a.test_id
     JOIN branches b ON b.id = t.branch_id
     WHERE a.status = 'blocked'
       AND (:branchId IS NULL OR t.branch_id = :branchId)
     ORDER BY a.blocked_at DESC`,
    params
  );
  return attempts;
}

async function allowAttempt(attemptId, adminUser, context = {}) {
  const [rows] = await pool.execute(
    `SELECT a.*, t.branch_id
     FROM test_attempts a
     JOIN tests t ON t.id = a.test_id
     WHERE a.id = :attemptId
     LIMIT 1`,
    { attemptId }
  );
  const attempt = rows[0];
  if (!attempt) {
    throw new ApiError(404, 'Attempt not found');
  }

  await pool.execute(
    `UPDATE test_attempts
     SET status = 'admin_allowed',
         allowed_by = :adminId,
         allowed_at = CURRENT_TIMESTAMP,
         blocked_reason = NULL
     WHERE id = :attemptId`,
    { attemptId, adminId: adminUser.sub }
  );

  await recordEvent({
    attemptId,
    testId: attempt.test_id,
    studentId: attempt.student_id,
    branchId: attempt.branch_id,
    eventType: 'admin_allowed',
    severity: 'warning',
    message: 'Admin allowed this student to reopen the test paper.',
    metadata: { adminId: adminUser.sub },
    context
  });
}

async function assertPdfAccess(testId, user, context = {}) {
  const attempt = await getAttemptByStudent(testId, user.sub);
  if (!attempt) {
    throw new ApiError(403, 'Start the test before opening the PDF.');
  }
  if (attempt.status === 'blocked') {
    throw new ApiError(423, 'Attempt is locked. Admin permission is required to reopen this paper.');
  }
  if (attempt.status === 'completed') {
    throw new ApiError(403, 'This attempt has already been completed.');
  }

  await pool.execute(
    'UPDATE test_attempts SET last_seen_at = CURRENT_TIMESTAMP WHERE id = :attemptId',
    { attemptId: attempt.id }
  );
  await recordEvent({
    attemptId: attempt.id,
    testId,
    studentId: user.sub,
    branchId: attempt.branch_id,
    eventType: 'pdf_requested',
    message: 'Student requested the scheduled PDF.',
    context
  });
}

async function blockAttempt(attemptId, reason) {
  await pool.execute(
    `UPDATE test_attempts
     SET status = 'blocked',
         blocked_at = CURRENT_TIMESTAMP,
         blocked_reason = :reason,
         last_seen_at = CURRENT_TIMESTAMP
     WHERE id = :attemptId AND status <> 'completed'`,
    { attemptId, reason }
  );
}

async function getAssignedLiveTest(testId, branchId) {
  const [rows] = await pool.execute(
    `SELECT *
     FROM tests
     WHERE id = :testId
       AND branch_id = :branchId
       AND is_active = 1
       AND CURRENT_TIMESTAMP BETWEEN scheduled_start AND scheduled_end
     LIMIT 1`,
    { testId, branchId }
  );
  if (!rows[0]) {
    throw new ApiError(403, 'This paper is not available for your branch at this time.');
  }
  return rows[0];
}

async function getAttemptByStudent(testId, studentId) {
  const [rows] = await pool.execute(
    `SELECT a.*, t.branch_id
     FROM test_attempts a
     JOIN tests t ON t.id = a.test_id
     WHERE a.test_id = :testId AND a.student_id = :studentId
     LIMIT 1`,
    { testId, studentId }
  );
  return rows[0] || null;
}

module.exports = {
  startAttempt,
  completeAttempt,
  recordStudentEvent,
  recordEvent,
  listEvents,
  listLockedAttempts,
  allowAttempt,
  assertPdfAccess
};
