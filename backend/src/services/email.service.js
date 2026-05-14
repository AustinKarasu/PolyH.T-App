const nodemailer = require('nodemailer');
const { env } = require('../config/env');

let transporter;

function getTransporter() {
  if (!env.mail.enabled) return null;
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.mail.host,
      port: env.mail.port,
      secure: env.mail.secure,
      auth: {
        user: env.mail.user,
        pass: env.mail.password
      }
    });
  }
  return transporter;
}

async function sendMail({ to, subject, text, html }) {
  if (!to) return { skipped: true, reason: 'missing-recipient' };
  const mailer = getTransporter();
  if (!mailer) {
    console.log(`[mail disabled] ${subject} -> ${to}`);
    return { skipped: true, reason: 'mail-disabled' };
  }
  return mailer.sendMail({
    from: env.mail.from,
    to,
    subject,
    text,
    html
  });
}

async function sendLoginOtp(user, code) {
  return sendMail({
    to: user.email,
    subject: `${env.appTitle} login OTP`,
    text: `${env.appDescription}\n\nYour ${env.appTitle} login OTP is ${code}. It expires in 10 minutes.`,
    html: `<p>${escapeHtml(env.appDescription)}</p><p>Your ${escapeHtml(env.appTitle)} login OTP is <strong>${code}</strong>.</p><p>It expires in 10 minutes.</p>`
  });
}

async function sendTestNotice(student, test, kind) {
  const startsAt = new Date(test.scheduled_start).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
  const subject = kind === 'started' ? `${env.appTitle} test started: ${test.title}` : `${env.appTitle} test scheduled: ${test.title}`;
  const intro = kind === 'started'
    ? 'Your house test has started.'
    : 'A house test has been scheduled for you.';
  return sendMail({
    to: student.email,
    subject,
    text: `${env.appDescription}\n\n${intro}\n\nTest: ${test.title}\nBranch: ${test.branch_name || ''}\nSemester: ${test.semester}\nStarts: ${startsAt}`,
    html: `<p>${escapeHtml(env.appDescription)}</p><p>${intro}</p><p><strong>Test:</strong> ${escapeHtml(test.title)}<br><strong>Semester:</strong> ${test.semester}<br><strong>Starts:</strong> ${startsAt}</p>`
  });
}

function escapeHtml(value) {
  return String(value || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

module.exports = { sendMail, sendLoginOtp, sendTestNotice };
