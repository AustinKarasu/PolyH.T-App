const authService = require('../services/auth.service');

async function login(req, res, next) {
  try {
    const result = await authService.login(req.body.identifier, req.body.password, {
      deviceLabel: req.body.deviceLabel,
      totpCode: req.body.totpCode,
      recaptchaToken: req.body.recaptchaToken,
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

async function captchaPage(_req, res) {
  const { env } = require('../config/env');
  res.type('html').send(`<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,sans-serif;display:flex;min-height:100vh;align-items:center;justify-content:center;margin:0;background:#f8f5ff;color:#1f1235}
    .box{text-align:center;padding:24px}.title{font-size:20px;font-weight:700;margin-bottom:8px}.sub{font-size:14px;margin-bottom:20px;color:#675c75}
  </style>
</head>
<body>
  <div class="box">
    <div class="title">Verify CAPTCHA</div>
    <div class="sub">Complete this check to continue signing in.</div>
    <div class="g-recaptcha" data-sitekey="${env.recaptchaSiteKey}" data-callback="onCaptcha"></div>
  </div>
  <script>
    function onCaptcha(token){
      if (window.Captcha && window.Captcha.postMessage) window.Captcha.postMessage(token);
      document.title = 'captcha:' + token;
    }
  </script>
</body>
</html>`);
}

async function updateMe(req, res, next) {
  try {
    const user = await authService.updateCurrentUser(req.user.sub, req.body);
    res.json({ user });
  } catch (err) {
    next(err);
  }
}

async function updateMyPhoto(req, res, next) {
  try {
    const user = await authService.updateCurrentUserPhoto(req.user.sub, req.file);
    res.json({ user });
  } catch (err) {
    next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    await authService.changeCurrentUserPassword(req.user.sub, {
      currentPassword: req.body.currentPassword,
      newPassword: req.body.newPassword,
      totpCode: req.body.totpCode
    });
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

async function setupTwoFactor(req, res, next) {
  try {
    const result = await authService.setupTwoFactor(req.user.sub);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function enableTwoFactor(req, res, next) {
  try {
    const user = await authService.enableTwoFactor(req.user.sub, req.body.code);
    res.json({ user });
  } catch (err) {
    next(err);
  }
}

async function disableTwoFactor(req, res, next) {
  try {
    const user = await authService.disableTwoFactor(req.user.sub, req.body.code);
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

module.exports = {
  login,
  captchaPage,
  me,
  updateMe,
  updateMyPhoto,
  changePassword,
  setupTwoFactor,
  enableTwoFactor,
  disableTwoFactor,
  logout
};
