const router = require('express').Router();
const { body } = require('express-validator');
const attemptController = require('../controllers/attempt.controller');
const { authenticate, requireRole } = require('../middleware/auth.middleware');
const { validate } = require('../middleware/validate.middleware');

router.post(
  '/:testId/start',
  authenticate,
  requireRole('student'),
  attemptController.startAttempt
);

router.post(
  '/:testId/events',
  authenticate,
  requireRole('student'),
  [
    body('eventType').isIn([
      'test_list_opened',
      'pdf_opened',
      'app_inactive',
      'app_backgrounded',
      'app_resumed',
      'app_detached',
      'back_blocked'
    ]),
    body('metadata').optional().isObject()
  ],
  validate,
  attemptController.recordEvent
);

router.post(
  '/:testId/complete',
  authenticate,
  requireRole('student'),
  [body('answerNote').optional().isString().isLength({ max: 1000 })],
  validate,
  attemptController.completeAttempt
);

router.get('/admin/events', authenticate, requireRole('admin'), attemptController.listEvents);
router.get('/admin/locked', authenticate, requireRole('admin'), attemptController.listLocked);
router.post('/admin/:attemptId/allow', authenticate, requireRole('admin'), attemptController.allowAttempt);

module.exports = router;
