const router = require('express').Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { imageUpload } = require('../middleware/upload.middleware');
const { authLimiter } = require('../middleware/security.middleware');
const { validate } = require('../middleware/validate.middleware');

router.post(
  '/login',
  authLimiter,
  [
    body('identifier').trim().notEmpty(),
    body('password').isLength({ min: 6 }),
    body('totpCode').optional({ nullable: true, checkFalsy: true }).trim().isLength({ min: 6, max: 8 }),
    body('recaptchaToken').optional({ nullable: true, checkFalsy: true }).trim().isLength({ min: 10, max: 4096 }),
    body('deviceLabel').optional().trim().isLength({ max: 160 })
  ],
  validate,
  authController.login
);

router.get('/me', authenticate, authController.me);
router.patch(
  '/me',
  authenticate,
  [
    body('fullName').optional().trim().isLength({ min: 2, max: 120 }),
    body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
    body('phone').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 20 }),
    body('address').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 500 }),
    body('guardianName').optional({ nullable: true, checkFalsy: true }).trim().isLength({ max: 120 })
  ],
  validate,
  authController.updateMe
);
router.put('/me/photo', authenticate, imageUpload.single('photo'), authController.updateMyPhoto);
router.post(
  '/me/password',
  authenticate,
  [
    body('currentPassword').isLength({ min: 6 }),
    body('newPassword').isStrongPassword({
      minLength: 8,
      minLowercase: 1,
      minUppercase: 1,
      minNumbers: 1,
      minSymbols: 1
    }),
    body('totpCode').trim().isLength({ min: 6, max: 8 })
  ],
  validate,
  authController.changePassword
);
router.post('/2fa/setup', authenticate, authController.setupTwoFactor);
router.post(
  '/2fa/enable',
  authenticate,
  [body('code').trim().isLength({ min: 6, max: 8 })],
  validate,
  authController.enableTwoFactor
);
router.post(
  '/2fa/disable',
  authenticate,
  [body('code').trim().isLength({ min: 6, max: 8 })],
  validate,
  authController.disableTwoFactor
);
router.post('/logout', authenticate, authController.logout);

module.exports = router;
