const authService = require('../services/auth.service');

async function login(req, res, next) {
  try {
    const result = await authService.login(req.body.identifier, req.body.password, {
      deviceLabel: req.body.deviceLabel,
      ipAddress: req.ip,
      userAgent: req.get('user-agent')
    });
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await authService.getCurrentUser(req.user.sub);
    res.json({ user });
  } catch (err) {
    next(err);
  }
}

async function logout(req, res, next) {
  try {
    await authService.logout(req.user);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { login, me, logout };
