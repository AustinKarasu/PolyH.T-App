const router = require('express').Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { authLimiter } = require('../middleware/security.middleware');
const { validate } = require('../middleware/validate.middleware');

router.post(
  '/login',
  authLimiter,
  [
    body('identifier').trim().notEmpty(),
    body('password').isLength({ min: 6 }),
    body('deviceLabel').optional().trim().isLength({ max: 160 })
  ],
  validate,
  authController.login
);

router.get('/me', authenticate, authController.me);
router.post('/logout', authenticate, authController.logout);

module.exports = router;
