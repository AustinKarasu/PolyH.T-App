// Minimal test to isolate the crash
module.exports = (req, res) => {
  res.json({ status: 'ok', path: req.url });
};
