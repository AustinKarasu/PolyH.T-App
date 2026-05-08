const { pool } = require('../config/db');
const { ApiError } = require('../utils/api-error');
const attemptService = require('./attempt.service');
const storageService = require('./storage.service');

async function createTest({ title, branchId, scheduledStart, scheduledEnd, timeLimitMinutes, file, createdBy }) {
  if (!file) {
    throw new ApiError(422, 'PDF file is required');
  }

  const saved = await storageService.savePdf(file);
  const [result] = await pool.execute(
    `INSERT INTO tests
       (title, branch_id, original_filename, stored_filename, file_path, scheduled_start, scheduled_end, time_limit_minutes, created_by)
     VALUES
       (:title, :branchId, :originalFilename, :storedFilename, :filePath, :scheduledStart, :scheduledEnd, :timeLimitMinutes, :createdBy)`,
    {
      title,
      branchId,
      originalFilename: file.originalname,
      storedFilename: saved.key,
      filePath: saved.path,
      scheduledStart,
      scheduledEnd,
      timeLimitMinutes,
      createdBy
    }
  );

  return getTestById(result.insertId);
}

async function getTestById(id) {
  const [rows] = await pool.execute(
    `SELECT t.*, b.name AS branch_name, b.code AS branch_code
     FROM tests t
     JOIN branches b ON b.id = t.branch_id
     WHERE t.id = :id`,
    { id }
  );

  if (!rows[0]) {
    throw new ApiError(404, 'Test not found');
  }
  return rows[0];
}

async function listAdminTests() {
  const [tests] = await pool.execute(
    `SELECT t.id, t.title, t.original_filename, t.scheduled_start, t.scheduled_end,
            t.time_limit_minutes, t.is_active, b.name AS branch_name, b.code AS branch_code
     FROM tests t
     JOIN branches b ON b.id = t.branch_id
     ORDER BY t.scheduled_start DESC`
  );
  return tests;
}

async function listStudentTests(user) {
  const [tests] = await pool.execute(
    `SELECT t.id, t.title, t.original_filename, t.scheduled_start, t.scheduled_end,
            t.time_limit_minutes, a.id AS attempt_id, a.status AS attempt_status,
            a.blocked_reason, a.blocked_at, a.allowed_at, a.completed_at
     FROM tests t
     LEFT JOIN test_attempts a ON a.test_id = t.id AND a.student_id = :studentId
     WHERE t.branch_id = :branchId AND t.is_active = 1
     ORDER BY t.scheduled_start DESC`,
    { branchId: user.branchId, studentId: user.sub }
  );
  return tests.map((test) => ({
    ...test,
    status: test.attempt_status === 'blocked' ? 'locked' : statusForTest(test)
  }));
}

async function updateTest(id, patch) {
  await getTestById(id);
  await pool.execute(
    `UPDATE tests
     SET title = :title,
         branch_id = :branchId,
         scheduled_start = :scheduledStart,
         scheduled_end = :scheduledEnd,
         time_limit_minutes = :timeLimitMinutes,
         is_active = :isActive
     WHERE id = :id`,
    { id, ...patch }
  );
  return getTestById(id);
}

async function replacePdf(id, file) {
  if (!file) {
    throw new ApiError(422, 'PDF file is required');
  }

  const existing = await getTestById(id);
  const saved = await storageService.savePdf(file);
  await pool.execute(
    `UPDATE tests
     SET original_filename = :originalFilename,
         stored_filename = :storedFilename,
         file_path = :filePath,
         updated_at = CURRENT_TIMESTAMP
     WHERE id = :id`,
    {
      id,
      originalFilename: file.originalname,
      storedFilename: saved.key,
      filePath: saved.path
    }
  );

  await storageService.deletePdf(existing.file_path);

  return getTestById(id);
}

async function removeTest(id) {
  const existing = await getTestById(id);
  await pool.execute('DELETE FROM tests WHERE id = :id', { id });
  await storageService.deletePdf(existing.file_path);
}

async function getStudentPdf(testId, user, context = {}) {
  const test = await getTestById(testId);
  if (!test.is_active) {
    throw new ApiError(403, 'This test is not active');
  }
  if (test.branch_id !== user.branchId) {
    throw new ApiError(403, 'This test is not assigned to your branch');
  }
  if (statusForTest(test) !== 'live') {
    throw new ApiError(403, 'PDF is available only during scheduled test time');
  }
  await attemptService.assertPdfAccess(testId, user, context);
  return storageService.getPdfDelivery(test.file_path);
}

function statusForTest(test) {
  const now = Date.now();
  const start = new Date(test.scheduled_start).getTime();
  const end = new Date(test.scheduled_end).getTime();
  if (now < start) return 'upcoming';
  if (now > end) return 'ended';
  return 'live';
}

module.exports = {
  createTest,
  listAdminTests,
  listStudentTests,
  updateTest,
  replacePdf,
  removeTest,
  getStudentPdf
};
