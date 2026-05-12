const router = require('express').Router();
const { body } = require('express-validator');
const studentController = require('../controllers/student.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { imageUpload } = require('../middleware/upload.middleware');
const { validate } = require('../middleware/validate.middleware');

// Student self-service
router.get('/me', authenticate, requireRole('student'), studentController.getProfile);
router.patch(
  '/me',
  authenticate,
  requireRole('student'),
  [
    body('phone').optional().trim().isLength({ max: 20 }),
    body('address').optional().trim().isLength({ max: 500 }),
    body('guardianName').optional().trim().isLength({ max: 120 }),
    body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail()
  ],
  validate,
  studentController.updateProfile
);
router.put(
  '/me/photo',
  authenticate,
  requireRole('student'),
  imageUpload.single('photo'),
  studentController.updatePhoto
);

// Admin endpoints
router.get('/', authenticate, requireRole('admin'), studentController.listStudents);
router.post(
  '/',
  authenticate,
  requireRole('admin'),
  [
    body('fullName').trim().isLength({ min: 2, max: 120 }),
    body('collegeId').trim().isLength({ min: 2, max: 60 }),
    body('password').isStrongPassword({
      minLength: 8,
      minLowercase: 1,
      minUppercase: 1,
      minNumbers: 1,
      minSymbols: 1
    }),
    body('branchId').isInt({ min: 1 }),
    body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
    body('dob').optional({ nullable: true, checkFalsy: true }).isISO8601(),
    body('semester').optional({ nullable: true, checkFalsy: true }).isInt({ min: 1, max: 8 }),
    body('rollNo').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 40 }),
    body('boardRollNo').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 40 }),
    body('collegeName').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 200 }),
    body('courseName').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 120 }),
    body('guardianName').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 120 }),
    body('phone').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 20 }),
    body('address').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 500 }),
    body('admissionYear').optional({ nullable: true, checkFalsy: true }).isInt({ min: 2000, max: 2100 })
  ],
  validate,
  studentController.adminCreateStudent
);
router.get('/:id', authenticate, requireRole('admin'), studentController.getStudentById);
router.patch(
  '/:id',
  authenticate,
  requireRole('admin'),
  [
    body('fullName').optional().trim().isLength({ min: 2, max: 120 }),
    body('collegeId').optional().trim().isLength({ min: 2, max: 60 }),
    body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
    body('dob').optional().isISO8601(),
    body('semester').optional().isInt({ min: 1, max: 8 }),
    body('rollNo').optional().trim().isLength({ max: 40 }),
    body('boardRollNo').optional().trim().isLength({ max: 40 }),
    body('collegeName').optional().trim().isLength({ max: 200 }),
    body('courseName').optional().trim().isLength({ max: 120 }),
    body('guardianName').optional().trim().isLength({ max: 120 }),
    body('phone').optional().trim().isLength({ max: 20 }),
    body('address').optional().trim().isLength({ max: 500 }),
    body('admissionYear').optional().isInt({ min: 2000, max: 2100 }),
    body('branchId').optional().isInt({ min: 1 }),
    body('isActive').optional().isBoolean(),
    body('password').optional({ nullable: true, checkFalsy: true }).isStrongPassword({
      minLength: 8,
      minLowercase: 1,
      minUppercase: 1,
      minNumbers: 1,
      minSymbols: 1
    })
  ],
  validate,
  studentController.adminUpdateStudent
);
router.delete('/:id', authenticate, requireRole('admin'), studentController.adminDeleteStudent);

module.exports = router;
