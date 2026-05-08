const router = require('express').Router();
const branchController = require('../controllers/branch.controller');
const { authenticate } = require('../middleware/auth.middleware');

router.get('/', authenticate, branchController.listBranches);

module.exports = router;
