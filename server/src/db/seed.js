const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query, queryOne, pool } = require('../db/pool');

async function main() {
  const email = process.env.SEED_EMAIL || 'demo@nomicheck.app';
  const password = process.env.SEED_PASSWORD || 'demo1234';
  const name = process.env.SEED_NAME || 'Usuario Demo';

  const existing = await queryOne('SELECT id FROM users WHERE email = ?', [email]);
  if (existing) {
    console.log(`El usuario ${email} ya existe (id ${existing.id}).`);
    return;
  }

  const id = uuidv4();
  await query('INSERT INTO users (id, name, email, password_hash) VALUES (?, ?, ?, ?)', [
    id,
    name,
    email,
    await bcrypt.hash(password, 10),
  ]);
  await query('INSERT INTO user_configs (user_id) VALUES (?)', [id]);

  console.log(`Usuario demo creado: ${email} / ${password}`);
}

main()
  .catch((err) => {
    console.error('Error en el seed:', err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
