const fs = require('fs');
const path = require('path');
const multer = require('multer');
const { env } = require('../config/env');
const { ApiError } = require('../utils/api-error');

const uploadPath = path.resolve(env.uploadDir);
fs.mkdirSync(uploadPath, { recursive: true });

const diskStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadPath),
  filename: (_req, file, cb) => {
    const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${Date.now()}-${safeName}`);
  }
});

const pdfUpload = multer({
  storage: env.storage.driver === 's3' ? multer.memoryStorage() : diskStorage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    if (file.mimetype !== 'application/pdf') {
      return cb(new ApiError(422, 'Only PDF files are allowed'));
    }
    return cb(null, true);
  }
});

module.exports = { pdfUpload };
