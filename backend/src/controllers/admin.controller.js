const adminService = require('../services/admin.service');

async function listAdmins(_req, res, next) {
  try {
    const admins = await adminService.listAdmins();
    res.json({ admins });
  } catch (err) {
    next(err);
  }
}

async function createAdmin(req, res, next) {
  try {
    const admin = await adminService.createAdmin(req.body);
    res.status(201).json({ admin });
  } catch (err) {
    next(err);
  }
}

async function setAdminActive(req, res, next) {
  try {
    await adminService.setAdminActive(
      Number(req.params.id),
      Boolean(req.body.isActive),
      req.user.sub
    );
    res.json({ status: 'updated' });
  } catch (err) {
    next(err);
  }
}

async function setPrimaryAdmin(req, res, next) {
  try {
    await adminService.setPrimaryAdmin(Number(req.params.id));
    res.json({ status: 'updated' });
  } catch (err) {
    next(err);
  }
}

async function deleteAdmin(req, res, next) {
  try {
    await adminService.deleteAdmin(Number(req.params.id), req.user.sub);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
}

module.exports = { listAdmins, createAdmin, setAdminActive, setPrimaryAdmin, deleteAdmin };
