const bcrypt = require('bcryptjs');
const { query, transaction } = require('../config/db');
const { ApiError } = require('../utils/api-error');
const authService = require('./auth.service');

async function listAdmins() {
  return query(
    `SELECT id, full_name, email, is_active, two_factor_enabled, is_primary_admin, created_at
     FROM users WHERE role = 'admin' ORDER BY is_primary_admin DESC, created_at DESC`
  );
}

async function createAdmin({ fullName, email, password }) {
  const passwordHash = await bcrypt.hash(password, 12);
  try {
    const rows = await query(
      `INSERT INTO users (full_name, email, password_hash, role, is_active, is_primary_admin)
       VALUES ($1, $2, $3, 'admin', TRUE, FALSE) RETURNING id`,
      [fullName, email, passwordHash]
    );
    return { id: rows[0].id, full_name: fullName, email, role: 'admin' };
  } catch (err) {
    if (err.code === '23505') {
      throw new ApiError(409, 'Admin email already exists');
    }
    throw err;
  }
}

async function setAdminActive(adminId, isActive, actingAdminId) {
  if (adminId === actingAdminId && !isActive) {
    throw new ApiError(422, 'You cannot deactivate your own admin account');
  }
  const rows = await query('SELECT is_primary_admin FROM users WHERE id = $1 AND role = $2 LIMIT 1', [adminId, 'admin']);
  if (!rows[0]) throw new ApiError(404, 'Admin account not found');
  if (rows[0].is_primary_admin && !isActive) {
    throw new ApiError(422, 'Primary admin cannot be deactivated until another admin is made primary');
  }
  await query(
    `UPDATE users SET is_active = $1 WHERE id = $2 AND role = 'admin'`,
    [isActive, adminId]
  );
}

async function setPrimaryAdmin(adminId) {
  const rows = await query('SELECT id, is_active FROM users WHERE id = $1 AND role = $2 LIMIT 1', [adminId, 'admin']);
  if (!rows[0]) throw new ApiError(404, 'Admin account not found');
  if (!rows[0].is_active) throw new ApiError(422, 'Only an active admin can be primary');
  await query('UPDATE users SET is_primary_admin = FALSE WHERE role = $1', ['admin']);
  await query('UPDATE users SET is_primary_admin = TRUE, updated_at = CURRENT_TIMESTAMP WHERE id = $1 AND role = $2', [adminId, 'admin']);
}

async function deleteAdmin(adminId, actingAdminId) {
  if (adminId === actingAdminId) throw new ApiError(422, 'You cannot delete your own admin account');
  const rows = await query('SELECT is_primary_admin FROM users WHERE id = $1 AND role = $2 LIMIT 1', [adminId, 'admin']);
  if (!rows[0]) throw new ApiError(404, 'Admin account not found');
  if (rows[0].is_primary_admin) throw new ApiError(422, 'Primary admin cannot be deleted until another admin is made primary');
  await query('UPDATE test_attempts SET allowed_by = NULL WHERE allowed_by = $1', [adminId]);
  await query('DELETE FROM auth_sessions WHERE user_id = $1', [adminId]);
  await query('DELETE FROM users WHERE id = $1 AND role = $2', [adminId, 'admin']);
}

async function clearData(actingAdminId, { totpCode, tests = false, history = false, students = false, sessions = false }) {
  await authService.requireVerifiedTwoFactor(actingAdminId, totpCode);
  if (!tests && !history && !students && !sessions) {
    throw new ApiError(422, 'Select at least one data type to clear');
  }

  await transaction(async (tx) => {
    if (students) {
      await tx('DELETE FROM auth_sessions WHERE user_id IN (SELECT id FROM users WHERE role = $1)', ['student']);
      await tx('DELETE FROM exam_events WHERE student_id IN (SELECT id FROM users WHERE role = $1)', ['student']);
      await tx('DELETE FROM test_attempts WHERE student_id IN (SELECT id FROM users WHERE role = $1)', ['student']);
      await tx('DELETE FROM users WHERE role = $1', ['student']);
    }
    if (tests) {
      await tx('DELETE FROM exam_events', []);
      await tx('DELETE FROM test_attempts', []);
      await tx('DELETE FROM tests', []);
    } else if (history) {
      await tx('DELETE FROM exam_events', []);
      await tx('DELETE FROM test_attempts', []);
    }
    if (sessions) {
      await tx('UPDATE auth_sessions SET revoked_at = CURRENT_TIMESTAMP WHERE revoked_at IS NULL', []);
    }
  });
}

module.exports = { listAdmins, createAdmin, setAdminActive, setPrimaryAdmin, deleteAdmin, clearData };
