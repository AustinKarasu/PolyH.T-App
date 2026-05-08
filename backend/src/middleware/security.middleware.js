const compression = require('compression');
const cors = require('cors');
const helmet = require('helmet');
const hpp = require('hpp');
const rateLimit = require('express-rate-limit');
const { env } = require('../config/env');
const { ApiError } = require('../utils/api-error');

const globalLimiter = rateLimit({
  windowMs: env.rateLimit.globalWindowMs,
  limit: env.rateLimit.globalMax,
  standardHeaders: 'draft-7',
  legacyHeaders: false
});

const authLimiter = rateLimit({
  windowMs: env.rateLimit.authWindowMs,
  limit: env.rateLimit.authMax,
  standardHeaders: 'draft-7',
  legacyHeaders: false,
  message: { message: 'Too many login attempts. Try again later.' }
});

function corsMiddleware() {
  return cors({
    origin(origin, callback) {
      if (!origin || env.corsOrigins.length === 0 || env.corsOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new ApiError(403, 'Origin is not allowed'));
    }
  });
}

module.exports = {
  compression,
  corsMiddleware,
  helmet,
  hpp,
  globalLimiter,
  authLimiter
};
