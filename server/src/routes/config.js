const express = require('express');
const { query, queryOne } = require('../db/pool');
const { authRequired } = require('../middleware/auth');

const router = express.Router();
router.use(authRequired);

function serialize(row) {
  return {
    hourlyRate: Number(row.hourly_rate),
    monthlySalary: Number(row.monthly_salary),
    salaryType: row.salary_type,
    nightSurchargePercent: Number(row.night_surcharge_percent),
    sundaySurchargePercent: Number(row.sunday_surcharge_percent),
    extraDaySurchargePercent: Number(row.extra_day_surcharge_percent),
    extraNightSurchargePercent: Number(row.extra_night_surcharge_percent),
    workLatitude: row.work_latitude,
    workLongitude: row.work_longitude,
    gpsRadius: Number(row.gps_radius),
    notificationsEnabled: Boolean(row.notifications_enabled),
    reminderMinutesBefore: row.reminder_minutes_before,
    standardHoursPerDay: row.standard_hours_per_day,
    workDays: String(row.work_days || '')
      .split(',')
      .filter((d) => d !== '')
      .map(Number),
    updatedAt: row.updated_at,
  };
}

router.get('/', async (req, res, next) => {
  try {
    const row = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);
    if (!row) {
      await query('INSERT INTO user_configs (user_id) VALUES (?)', [req.userId]);
      const created = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);
      return res.json({ config: serialize(created) });
    }
    res.json({ config: serialize(row) });
  } catch (e) {
    next(e);
  }
});

router.put('/', async (req, res, next) => {
  try {
    const body = req.body || {};
    const current = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);

    if (body.salaryType !== undefined && ![0, 1].includes(Number(body.salaryType))) {
      return res.status(400).json({ error: 'salaryType debe ser 0 (por hora) o 1 (mensual)' });
    }

    const workDays = Array.isArray(body.workDays)
      ? body.workDays.join(',')
      : body.workDays || current?.work_days || '1,2,3,4,5';

    await query(
      `INSERT INTO user_configs (
         user_id, hourly_rate, monthly_salary, salary_type,
         night_surcharge_percent, sunday_surcharge_percent,
         extra_day_surcharge_percent, extra_night_surcharge_percent,
         work_latitude, work_longitude, gps_radius,
         notifications_enabled, reminder_minutes_before,
         standard_hours_per_day, work_days
       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE
         hourly_rate = VALUES(hourly_rate),
         monthly_salary = VALUES(monthly_salary),
         salary_type = VALUES(salary_type),
         night_surcharge_percent = VALUES(night_surcharge_percent),
         sunday_surcharge_percent = VALUES(sunday_surcharge_percent),
         extra_day_surcharge_percent = VALUES(extra_day_surcharge_percent),
         extra_night_surcharge_percent = VALUES(extra_night_surcharge_percent),
         work_latitude = VALUES(work_latitude),
         work_longitude = VALUES(work_longitude),
         gps_radius = VALUES(gps_radius),
         notifications_enabled = VALUES(notifications_enabled),
         reminder_minutes_before = VALUES(reminder_minutes_before),
         standard_hours_per_day = VALUES(standard_hours_per_day),
         work_days = VALUES(work_days)`,
      [
        req.userId,
        body.hourlyRate ?? current?.hourly_rate ?? 0,
        body.monthlySalary ?? current?.monthly_salary ?? 0,
        body.salaryType ?? current?.salary_type ?? 0,
        body.nightSurchargePercent ?? current?.night_surcharge_percent ?? 35,
        body.sundaySurchargePercent ?? current?.sunday_surcharge_percent ?? 75,
        body.extraDaySurchargePercent ?? current?.extra_day_surcharge_percent ?? 25,
        body.extraNightSurchargePercent ?? current?.extra_night_surcharge_percent ?? 50,
        body.workLatitude !== undefined ? body.workLatitude : current?.work_latitude ?? null,
        body.workLongitude !== undefined ? body.workLongitude : current?.work_longitude ?? null,
        body.gpsRadius ?? current?.gps_radius ?? 100,
        body.notificationsEnabled !== undefined
          ? body.notificationsEnabled
          : current?.notifications_enabled ?? 1,
        body.reminderMinutesBefore ?? current?.reminder_minutes_before ?? 30,
        body.standardHoursPerDay ?? current?.standard_hours_per_day ?? 8,
        workDays,
      ]
    );

    const row = await queryOne('SELECT * FROM user_configs WHERE user_id = ?', [req.userId]);
    res.json({ config: serialize(row) });
  } catch (e) {
    next(e);
  }
});

module.exports = router;
