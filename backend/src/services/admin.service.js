const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const { ApiError } = require('../utils/api-error');

async function listAdmins() {
  const [admins] = await pool.execute(
    `SELECT id, full_name, email, is_active, created_at
     FROM users
     WHERE role = 'admin'
     ORDER BY created_at DESC`
  );
  return admins;
}

async function createAdmin({ fullName, email, password }) {
  const passwordHash = await bcrypt.hash(password, 12);
  try {
    const [result] = await pool.execute(
      `INSERT INTO users (full_name, email, password_hash, role, is_active)
       VALUES (:fullName, :email, :passwordHash, 'admin', TRUE)`,
      { fullName, email, passwordHash }
    );
    return { id: result.insertId, full_name: fullName, email, role: 'admin' };
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      throw new ApiError(409, 'Admin email already exists');
    }
    throw err;
  }
}

async function setAdminActive(adminId, isActive, actingAdminId) {
  if (adminId === actingAdminId && !isActive) {
    throw new ApiError(422, 'You cannot deactivate your own admin account');
  }
  await pool.execute(
    `UPDATE users
     SET is_active = :isActive
     WHERE id = :adminId AND role = 'admin'`,
    { adminId, isActive }
  );
}

module.exports = { listAdmins, createAdmin, setAdminActive };
