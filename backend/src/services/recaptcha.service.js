const { env } = require('../config/env');
const { ApiError } = require('../utils/api-error');

async function verifyRecaptcha(token, ipAddress) {
  if (!env.recaptchaSecretKey) return;
  if (!token) {
    if (env.recaptchaRequired) throw new ApiError(422, 'Captcha verification is required');
    return;
  }

  const body = new URLSearchParams({
    secret: env.recaptchaSecretKey,
    response: token
  });
  if (ipAddress) body.set('remoteip', ipAddress);

  const response = await fetch('https://www.google.com/recaptcha/api/siteverify', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body
  });
  const result = await response.json().catch(() => ({}));
  if (!result.success) {
    throw new ApiError(422, 'Captcha verification failed');
  }
  if (typeof result.score === 'number' && result.score < env.recaptchaMinScore) {
    throw new ApiError(422, 'Captcha score is too low');
  }
}

module.exports = { verifyRecaptcha };
