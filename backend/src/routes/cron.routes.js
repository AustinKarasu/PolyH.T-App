const router = require('express').Router();
const { env } = require('../config/env');
const testService = require('../services/test.service');

router.get('/test-notifications', async (req, res, next) => {
  try {
    if (env.cronSecret) {
      const expected = `Bearer ${env.cronSecret}`;
      if (req.get('authorization') !== expected) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
    }
    const result = await testService.notifyStartedTests();
    res.json({ status: 'ok', ...result });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
