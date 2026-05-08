const router = require('express').Router();
const { body } = require('express-validator');
const testController = require('../controllers/test.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { pdfUpload } = require('../middleware/upload.middleware');
const { validate } = require('../middleware/validate.middleware');

const testValidation = [
  body('title').trim().isLength({ min: 3, max: 120 }),
  body('branchId').isInt({ min: 1 }),
  body('scheduledStart').isISO8601(),
  body('scheduledEnd').isISO8601(),
  body('timeLimitMinutes').isInt({ min: 1, max: 360 })
];

router.get('/', authenticate, testController.listTests);
router.get('/:id/pdf', authenticate, requireRole('student'), testController.downloadPdf);

router.post(
  '/',
  authenticate,
  requireRole('admin'),
  pdfUpload.single('pdf'),
  testValidation,
  validate,
  testController.createTest
);

router.put(
  '/:id',
  authenticate,
  requireRole('admin'),
  [...testValidation, body('isActive').isBoolean()],
  validate,
  testController.updateTest
);

router.put(
  '/:id/pdf',
  authenticate,
  requireRole('admin'),
  pdfUpload.single('pdf'),
  testController.replacePdf
);

router.delete('/:id', authenticate, requireRole('admin'), testController.removeTest);

module.exports = router;
