function toMysqlDateTime(value) {
  const date = value instanceof Date ? value : new Date(value);
  return date.toISOString().slice(0, 19).replace('T', ' ');
}

module.exports = { toMysqlDateTime };
