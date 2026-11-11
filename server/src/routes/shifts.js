const express = require('express');
const { query, queryOne } = require('../db/pool');
const { authRequired } = require('../middleware/auth');
const { toMysqlDate, toIso } = require('../utils/dates');

const router = express.Router();
router.use(authRequired);

function serialize(row) {
  return {
    id: row.id,
    entryTime: toIso(row.entry_time),
    exitTime: toIso(row.exit_time),
    type: row.type,
    notes: row.notes,
    latitude: row.latitude,
    longitude: row.longitude,
    updatedAt: toIso(row.updated_at),
  };
}

// Pull: turnos del servidor (sincronizados por updatedAt para no perder cambios)
router.get('/', async (req, res, next) => {
  try {
    const since = req.query.since ? toMysqlDate(req.query.since) : null;
    const rows = await query(
      `SELECT id, entry_time, exit_time, type, notes, latitude, longitude, updated_at
       FROM shifts
       WHERE user_id = ? ${since ? 'AND updated_at > ?' : ''}
       ORDER BY entry_time DESC`,
      since ? [req.userId, since] : [req.userId]
    );
    res.json({ shifts: rows.map(serialize) });
  } catch (e) {
    next(e);
  }
});

// Push: upsert por id (el id lo genera el dispositivo con uuid)
router.post('/', async (req, res, next) => {
  try {
    const shifts = Array.isArray(req.body?.shifts) ? req.body.shifts : [];
    const saved = [];

    for (const shift of shifts) {
      if (!shift || !shift.id || !shift.entryTime) continue;

      const entryTime = toMysqlDate(shift.entryTime);
      if (!entryTime) continue;
      const exitTime = shift.exitTime ? toMysqlDate(shift.exitTime) : null;

      await query(
        `INSERT INTO shifts (id, user_id, entry_time, exit_time, type, notes, latitude, longitude)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           entry_time = VALUES(entry_time),
           exit_time = VALUES(exit_time),
           type = VALUES(type),
           notes = VALUES(notes),
           latitude = VALUES(latitude),
           longitude = VALUES(longitude)`,
        [
          shift.id,
          req.userId,
          entryTime,
          exitTime,
          shift.type ?? 0,
          shift.notes || null,
          shift.latitude ?? null,
          shift.longitude ?? null,
        ]
      );

      const row = await queryOne(
        'SELECT id, entry_time, exit_time, type, notes, latitude, longitude, updated_at FROM shifts WHERE id = ? AND user_id = ?',
        [shift.id, req.userId]
      );
      if (row) saved.push(serialize(row));
    }

    res.json({ shifts: saved });
  } catch (e) {
    next(e);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const shift = req.body || {};
    const existing = await queryOne('SELECT id FROM shifts WHERE id = ? AND user_id = ?', [
      req.params.id,
      req.userId,
    ]);
    if (!existing) {
      return res.status(404).json({ error: 'Turno no encontrado' });
    }

    await query(
      `UPDATE shifts
       SET entry_time = ?, exit_time = ?, type = ?, notes = ?, latitude = ?, longitude = ?
       WHERE id = ? AND user_id = ?`,
      [
        toMysqlDate(shift.entryTime),
        shift.exitTime ? toMysqlDate(shift.exitTime) : null,
        shift.type ?? 0,
        shift.notes || null,
        shift.latitude ?? null,
        shift.longitude ?? null,
        req.params.id,
        req.userId,
      ]
    );

    const row = await queryOne(
      'SELECT id, entry_time, exit_time, type, notes, latitude, longitude, updated_at FROM shifts WHERE id = ?',
      [req.params.id]
    );
    res.json({ shift: serialize(row) });
  } catch (e) {
    next(e);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    await query('DELETE FROM shifts WHERE id = ? AND user_id = ?', [req.params.id, req.userId]);
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
