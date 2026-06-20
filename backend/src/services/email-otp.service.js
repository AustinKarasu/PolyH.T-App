const crypto = require('crypto');
const nodemailer = require('nodemailer');
const { env } = require('../config/env');
const { query } = require('../config/db');
const { ApiError } = require('../utils/api-error');

const OTP_TTL_MINUTES = 10;

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function hashCode(email, purpose, code) {
  return crypto
    .createHash('sha256')
    .update(`${normalizeEmail(email)}:${purpose}:${String(code).trim()}`)
    .digest('hex');
}

function generateCode() {
  return String(crypto.randomInt(100000, 1000000));
}

function transporter() {
  if (!env.smtp.host || !env.smtp.user || !env.smtp.pass || !env.smtp.from) {
    throw new ApiError(500, 'Email OTP is not configured');
  }
  return nodemailer.createTransport({
    host: env.smtp.host,
    port: env.smtp.port,
    secure: env.smtp.secure,
    auth: {
      user: env.smtp.user,
      pass: env.smtp.pass
    }
  });
}

async function sendOtp(email, purpose, subject = 'e-PolyPariksha HP verification code') {
  const normalizedEmail = normalizeEmail(email);
  if (!normalizedEmail) throw new ApiError(422, 'Email is required');

  const code = generateCode();
  await query(
    `INSERT INTO email_otps (email, purpose, code_hash, expires_at)
     VALUES ($1, $2, $3, CURRENT_TIMESTAMP + ($4 || ' minutes')::INTERVAL)`,
    [normalizedEmail, purpose, hashCode(normalizedEmail, purpose, code), OTP_TTL_MINUTES]
  );

  await transporter().sendMail({
    from: env.smtp.from,
    to: normalizedEmail,
    subject,
    text: `Your e-PolyPariksha HP verification code is ${code}. It expires in ${OTP_TTL_MINUTES} minutes.`
  });
}

async function verifyOtp(email, purpose, code) {
  const normalizedEmail = normalizeEmail(email);
  const cleanCode = String(code || '').trim();
  if (!normalizedEmail || !cleanCode) {
    throw new ApiError(422, 'Email OTP is required');
  }
  const rows = await query(
    `SELECT id, code_hash
     FROM email_otps
     WHERE email = $1
       AND purpose = $2
       AND consumed_at IS NULL
       AND expires_at > CURRENT_TIMESTAMP
     ORDER BY created_at DESC
     LIMIT 1`,
    [normalizedEmail, purpose]
  );
  const otp = rows[0];
  if (!otp || otp.code_hash !== hashCode(normalizedEmail, purpose, cleanCode)) {
    throw new ApiError(422, 'Invalid or expired email OTP');
  }
  await query('UPDATE email_otps SET consumed_at = CURRENT_TIMESTAMP WHERE id = $1', [otp.id]);
}

module.exports = { sendOtp, verifyOtp };
