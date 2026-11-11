const express = require('express');
const { query, queryOne } = require('../db/pool');
const { authRequired } = require('../middleware/auth');
const { toMysqlDate, toIso } = require('../utils/dates');

const router = express.Router();
router.use(authRequired);

// Sincronización en una sola ida y vuelta: el dispositivo envía lo que tiene
// local y recibe el estado autoritativo del servidor.
router.post('/', async (req, res, next) => {
  try {
    const body = req.body || {};
    const incomingShifts = Array.isArray(body.shifts) ? body.shifts : [];
    const deletedShiftIds = Array.isArray(body.deletedShiftIds) ? body.deletedShiftIds : [];

    // Los borrados se aplican primero: si un turno viene en la lista y tambien
    // en las lapidas, la lapida manda (era lo que el dispositivo tenia antes
    // de borrarlo).
    for (const id of deletedShiftIds) {
      if (typeof id !== 'string' || !id) continue;
      await query('DELETE FROM shifts WHERE id = ? AND user_id = ?', [id, req.userId]);
    }

    const deletedSet = new Set(deletedShiftIds);

    for (const shift of incomingShifts) {
      if (!shift || !shift.id || !shift.entryTime) continue;
      if (deletedSet.has(shift.id)) continue;
      const entryTime = toMysqlDate(shift.entryTime);
      if (!entryTime) continue;

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
          shift.exitTime ? toMysqlDate(shift.exitTime) : null,
          shift.type ?? 0,
          shift.notes || null,
          shift.latitude ?? null,
          shift.longitude ?? null,
        ]
      );
    }

    const rows = await query(
      `SELECT id, entry_time, exit_time, type, notes, latitude, longitude, updated_at
       FROM shifts WHERE user_id = ? ORDER BY entry_time DESC`,
      [req.userId]
    );

    const shifts = rows.map((row) => ({
      id: row.id,
      entryTime: toIso(row.entry_time),
      exitTime: toIso(row.exit_time),
      type: row.type,
      notes: row.notes,
      latitude: row.latitude,
      longitude: row.longitude,
      updatedAt: toIso(row.updated_at),
    }));

    let configRow = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);
    if (!configRow) {
      await query('INSERT INTO user_configs (user_id) VALUES (?)', [req.userId]);
      configRow = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);
    }

    const config = {
      hourlyRate: Number(configRow.hourly_rate),
      monthlySalary: Number(configRow.monthly_salary),
      salaryType: configRow.salary_type,
      nightSurchargePercent: Number(configRow.night_surcharge_percent),
      sundaySurchargePercent: Number(configRow.sunday_surcharge_percent),
      extraDaySurchargePercent: Number(configRow.extra_day_surcharge_percent),
      extraNightSurchargePercent: Number(configRow.extra_night_surcharge_percent),
      workLatitude: configRow.work_latitude,
      workLongitude: configRow.work_longitude,
      gpsRadius: Number(configRow.gps_radius),
      notificationsEnabled: Boolean(configRow.notifications_enabled),
      reminderMinutesBefore: configRow.reminder_minutes_before,
      standardHoursPerDay: configRow.standard_hours_per_day,
      workDays: String(configRow.work_days || '')
        .split(',')
        .filter((d) => d !== '')
        .map(Number),
      updatedAt: configRow.updated_at,
    };

    const user = await queryOne(
      'SELECT id, name, email, position, company FROM users WHERE id = ?',
      [req.userId]
    );

    res.json({ user, shifts, config, syncedAt: new Date().toISOString() });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
