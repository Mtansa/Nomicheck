const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { query, queryOne } = require('../db/pool');
const { signToken, authRequired } = require('../middleware/auth');

const router = express.Router();

router.post('/register', async (req, res, next) => {
  try {
    const { name, email, password, position, company } = req.body || {};

    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Nombre, email y contraseña son requeridos' });
    }
    if (String(password).length < 6) {
      return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const existing = await queryOne('SELECT id FROM users WHERE email = ?', [normalizedEmail]);
    if (existing) {
      return res.status(409).json({ error: 'Ya existe una cuenta con ese correo' });
    }

    const id = uuidv4();
    const hash = await bcrypt.hash(String(password), 10);

    await query(
      `INSERT INTO users (id, name, email, password_hash, position, company)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [id, String(name).trim(), normalizedEmail, hash, position || null, company || null]
    );
    await query('INSERT INTO user_configs (user_id) VALUES (?)', [id]);

    const user = await queryOne(
      'SELECT id, name, email, position, company, created_at FROM users WHERE id = ?',
      [id]
    );

    res.status(201).json({ token: signToken(user), user });
  } catch (e) {
    next(e);
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: 'Email y contraseña son requeridos' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const user = await queryOne(
      'SELECT id, name, email, position, company, password_hash FROM users WHERE email = ?',
      [normalizedEmail]
    );

    if (!user) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    const ok = await bcrypt.compare(String(password), user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: 'Credenciales inválidas' });
    }

    delete user.password_hash;
    res.json({ token: signToken(user), user });
  } catch (e) {
    next(e);
  }
});

router.get('/me', authRequired, async (req, res, next) => {
  try {
    const user = await queryOne(
      'SELECT id, name, email, position, company, created_at FROM users WHERE id = ?',
      [req.userId]
    );
    if (!user) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json({ user });
  } catch (e) {
    next(e);
  }
});

router.put('/me', authRequired, async (req, res, next) => {
  try {
    const { name, position, company } = req.body || {};
    const current = await queryOne('SELECT id, name, position, company FROM users WHERE id = ?', [
      req.userId,
    ]);
    if (!current) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    await query('UPDATE users SET name = ?, position = ?, company = ? WHERE id = ?', [
      name != null ? String(name).trim() : current.name,
      position !== undefined ? position : current.position,
      company !== undefined ? company : current.company,
      req.userId,
    ]);

    const user = await queryOne(
      'SELECT id, name, email, position, company, created_at FROM users WHERE id = ?',
      [req.userId]
    );
    res.json({ user });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
