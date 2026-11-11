const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || '127.0.0.1',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'nomicheck',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'nomicheck',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  dateStrings: false,
  timezone: 'Z',
});

async function query(sql, params) {
  const [rows] = await pool.execute(sql, params);
  return rows;
}

async function queryOne(sql, params) {
  const rows = await query(sql, params);
  return rows[0] || null;
}

module.exports = { pool, query, queryOne };
