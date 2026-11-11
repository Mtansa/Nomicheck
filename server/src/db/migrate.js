const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
require('dotenv').config();

async function main() {
  const sql = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
  const statements = sql
    .split(';')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: false,
  });

  try {
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${process.env.DB_NAME || 'nomicheck'}\` ` +
        'CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci'
    );
    await connection.changeUser({ database: process.env.DB_NAME || 'nomicheck' });

    for (const statement of statements) {
      await connection.query(statement);
    }
    console.log('Esquema aplicado correctamente.');
  } finally {
    await connection.end();
  }
}

main().catch((err) => {
  console.error('Error aplicando el esquema:', err.message);
  process.exit(1);
});
