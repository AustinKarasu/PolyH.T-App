const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { authenticator } = require('otplib');
const qrcode = require('qrcode');
const { query } = require('../config/db');
const { env } = require('../config/env');
const { ApiError } = require('../utils/api-error');

async function login(identifier, password, context = {}) {
  const rows = await query(
    `SELECT u.id, u.full_name, u.email, u.college_id, u.password_hash, u.role,
            u.branch_id, u.is_active, u.dob, u.semester, u.roll_no, u.board_roll_no,
            u.college_name, u.course_name, u.guardian_name, u.phone, u.address,
            u.admission_year, u.photo_url, u.two_factor_enabled, u.two_factor_secret,
            u.is_primary_admin,
            b.name AS branch_name, b.code AS branch_code
     FROM users u
     LEFT JOIN branches b ON b.id = u.branch_id
     WHERE u.email = $1 OR u.college_id = $1
     LIMIT 1`,
    [identifier]
  );

  const user = rows[0];
  if (!user || !user.is_active) {
    throw new ApiError(401, 'Invalid credentials');
  }

  const matches = await bcrypt.compare(password, user.password_hash);
  if (!matches) {
    throw new ApiError(401, 'Invalid credentials');
  }

  if (user.two_factor_enabled) {
    if (!context.totpCode || !authenticator.check(context.totpCode, user.two_factor_secret)) {
      return { requiresTwoFactor: true, user: sanitizeUser(user) };
    }
  }

  const jti = crypto.randomUUID();
  const token = jwt.sign(
    { sub: user.id, role: user.role, branchId: user.branch_id, jti },
    env.jwtSecret,
    { expiresIn: env.jwtExpiresIn }
  );
  const decoded = jwt.decode(token);

  await query(
    `INSERT INTO auth_sessions (user_id, token_jti, device_label, ip_address, user_agent, expires_at)
     VALUES ($1, $2, $3, $4, $5, $6)`,
    [user.id, jti, context.deviceLabel || null, context.ipAddress || null, context.userAgent || null, new Date(decoded.exp * 1000).toISOString()]
  );

  return { token, user: sanitizeUser(user) };
}

async function getCurrentUser(userId) {
  const rows = await query(
    `SELECT u.id, u.full_name, u.email, u.college_id, u.role,
            u.branch_id, u.dob, u.semester, u.roll_no, u.board_roll_no,
            u.college_name, u.course_name, u.guardian_name, u.phone, u.address,
            u.admission_year, u.photo_url, u.two_factor_enabled, u.is_primary_admin,
            b.name AS branch_name, b.code AS branch_code
     FROM users u
     LEFT JOIN branches b ON b.id = u.branch_id
     WHERE u.id = $1 AND u.is_active = true
     LIMIT 1`,
    [userId]
  );

  if (!rows[0]) {
    throw new ApiError(401, 'User account is inactive or no longer exists');
  }
  return rows[0];
}

async function setupTwoFactor(userId) {
  const user = await getCurrentUser(userId);
  const secret = authenticator.generateSecret();
  await query('UPDATE users SET two_factor_secret = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2', [secret, userId]);
  const label = encodeURIComponent(`PolyH.T:${user.email || user.college_id || user.id}`);
  const otpauthUrl = authenticator.keyuri(label, 'PolyH.T', secret);
  const qrCodeDataUrl = await qrcode.toDataURL(otpauthUrl);
  return { secret, otpauthUrl, qrCodeDataUrl };
}

async function enableTwoFactor(userId, code) {
  const rows = await query('SELECT two_factor_secret FROM users WHERE id = $1 LIMIT 1', [userId]);
  const secret = rows[0]?.two_factor_secret;
  if (!secret) throw new ApiError(422, 'Start 2FA setup before enabling it');
  if (!authenticator.check(code, secret)) throw new ApiError(422, 'Invalid authenticator code');
  await query('UPDATE users SET two_factor_enabled = TRUE, updated_at = CURRENT_TIMESTAMP WHERE id = $1', [userId]);
  return getCurrentUser(userId);
}

async function disableTwoFactor(userId, code) {
  const rows = await query('SELECT two_factor_secret, two_factor_enabled FROM users WHERE id = $1 LIMIT 1', [userId]);
  const user = rows[0];
  if (!user?.two_factor_enabled) return getCurrentUser(userId);
  if (!authenticator.check(code, user.two_factor_secret)) throw new ApiError(422, 'Invalid authenticator code');
  await query('UPDATE users SET two_factor_enabled = FALSE, two_factor_secret = NULL, updated_at = CURRENT_TIMESTAMP WHERE id = $1', [userId]);
  return getCurrentUser(userId);
}

async function logout(user) {
  if (!user?.jti) return;
  await query(
    'UPDATE auth_sessions SET revoked_at = CURRENT_TIMESTAMP WHERE token_jti = $1',
    [user.jti]
  );
}

function sanitizeUser(user) {
  const copy = { ...user };
  delete copy.password_hash;
  delete copy.two_factor_secret;
  return copy;
}

module.exports = { login, getCurrentUser, setupTwoFactor, enableTwoFactor, disableTwoFactor, logout };
