function toMysqlDate(value) {
  if (!value) return null;
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toISOString().slice(0, 19).replace('T', ' ');
}

function toIso(value) {
  if (!value) return null;
  if (value instanceof Date) return value.toISOString();
  // MySQL DATETIME comes back as 'YYYY-MM-DD HH:MM:SS' in UTC
  const iso = `${value.replace(' ', 'T')}Z`;
  return iso;
}

module.exports = { toMysqlDate, toIso };
