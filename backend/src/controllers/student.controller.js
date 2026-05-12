const studentService = require('../services/student.service');

async function getProfile(req, res, next) {
  try {
    const student = await studentService.getStudentProfile(req.user.sub);
    res.json({ student });
  } catch (err) {
    next(err);
  }
}

async function updateProfile(req, res, next) {
  try {
    const student = await studentService.updateStudentProfile(req.user.sub, req.body);
    res.json({ student });
  } catch (err) {
    next(err);
  }
}

async function listStudents(req, res, next) {
  try {
    const result = await studentService.listAllStudents(req.query);
    res.json(result);
  } catch (err) {
    next(err);
  }
}

async function getStudentById(req, res, next) {
  try {
    const student = await studentService.getStudentById(Number(req.params.id));
    res.json({ student });
  } catch (err) {
    next(err);
  }
}

async function adminCreateStudent(req, res, next) {
  try {
    const student = await studentService.adminCreateStudent(req.body);
    res.status(201).json({ student });
  } catch (err) {
    next(err);
  }
}

async function adminUpdateStudent(req, res, next) {
  try {
    const student = await studentService.adminUpdateStudent(
      Number(req.params.id),
      req.body
    );
    res.json({ student });
  } catch (err) {
    next(err);
  }
}

module.exports = { getProfile, updateProfile, listStudents, getStudentById, adminCreateStudent, adminUpdateStudent };
