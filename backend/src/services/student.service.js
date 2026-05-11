const { pool } = require('../config/db');
const { ApiError } = require('../utils/api-error');

const STUDENT_SELECT = `
  SELECT u.id, u.full_name, u.email, u.college_id, u.role, u.branch_id,
         u.dob, u.semester, u.roll_no, u.board_roll_no, u.college_name,
         u.course_name, u.guardian_name, u.phone, u.address,
         u.admission_year, u.photo_url, u.is_active, u.created_at,
         b.name AS branch_name, b.code AS branch_code
  FROM users u
  LEFT JOIN branches b ON b.id = u.branch_id`;

async function getStudentProfile(userId) {
  const [rows] = await pool.execute(
    `${STUDENT_SELECT} WHERE u.id = :userId AND u.is_active = 1 LIMIT 1`,
    { userId }
  );
  if (!rows[0]) {
    throw new ApiError(404, 'Student not found');
  }
  const student = rows[0];
  delete student.password_hash;
  return student;
}

async function updateStudentProfile(userId, patch) {
  const allowed = [
    'phone', 'address', 'guardian_name'
  ];
  const updates = [];
  const params = { userId };

  for (const key of allowed) {
    if (patch[key] !== undefined) {
      const col = key.replace(/([A-Z])/g, '_$1').toLowerCase();
      updates.push(`${col} = :${key}`);
      params[key] = patch[key];
    }
  }

  if (updates.length === 0) {
    throw new ApiError(422, 'No valid fields to update');
  }

  await pool.execute(
    `UPDATE users SET ${updates.join(', ')} WHERE id = :userId`,
    params
  );
  return getStudentProfile(userId);
}

async function listAllStudents(filters = {}) {
  const conditions = ['u.role = "student"'];
  const params = {};

  if (filters.branchId) {
    conditions.push('u.branch_id = :branchId');
    params.branchId = filters.branchId;
  }
  if (filters.semester) {
    conditions.push('u.semester = :semester');
    params.semester = filters.semester;
  }
  if (filters.search) {
    conditions.push('(u.full_name LIKE :search OR u.college_id LIKE :search OR u.roll_no LIKE :search)');
    params.search = `%${filters.search}%`;
  }

  const limit = Math.min(Number(filters.limit || 100), 500);
  const offset = Number(filters.offset || 0);

  const [students] = await pool.execute(
    `${STUDENT_SELECT}
     WHERE ${conditions.join(' AND ')}
     ORDER BY u.full_name ASC
     LIMIT ${limit} OFFSET ${offset}`,
    params
  );

  const [countResult] = await pool.execute(
    `SELECT COUNT(*) AS total FROM users u WHERE ${conditions.join(' AND ')}`,
    params
  );

  return { students, total: countResult[0].total };
}

async function getStudentById(studentId) {
  const [rows] = await pool.execute(
    `${STUDENT_SELECT} WHERE u.id = :studentId LIMIT 1`,
    { studentId }
  );
  if (!rows[0]) {
    throw new ApiError(404, 'Student not found');
  }
  delete rows[0].password_hash;
  return rows[0];
}

async function adminUpdateStudent(studentId, patch) {
  const allowed = [
    'full_name', 'dob', 'semester', 'roll_no', 'board_roll_no',
    'college_name', 'course_name', 'guardian_name', 'phone',
    'address', 'admission_year', 'is_active', 'branch_id'
  ];
  const updates = [];
  const params = { studentId };

  for (const key of allowed) {
    const camelKey = key.replace(/_([a-z])/g, (_, c) => c.toUpperCase());
    if (patch[camelKey] !== undefined) {
      updates.push(`${key} = :${camelKey}`);
      params[camelKey] = patch[camelKey];
    }
  }

  if (updates.length === 0) {
    throw new ApiError(422, 'No valid fields to update');
  }

  await pool.execute(
    `UPDATE users SET ${updates.join(', ')} WHERE id = :studentId AND role = 'student'`,
    params
  );
  return getStudentById(studentId);
}

module.exports = {
  getStudentProfile,
  updateStudentProfile,
  listAllStudents,
  getStudentById,
  adminUpdateStudent
};
