const { pool } = require('../config/db');

async function listBranches(_req, res, next) {
  try {
    const [branches] = await pool.execute('SELECT id, name, code FROM branches ORDER BY name');
    res.json({ branches });
  } catch (err) {
    next(err);
  }
}

module.exports = { listBranches };
