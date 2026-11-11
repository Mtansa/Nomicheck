const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const shiftRoutes = require('./routes/shifts');
const configRoutes = require('./routes/config');
const syncRoutes = require('./routes/sync');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.use((req, res, next) => {
  console.log(`${req.method} ${req.originalUrl} -> ${res.statusCode}`);
  next();
});

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

app.use('/api/auth', authRoutes);
app.use('/api/shifts', shiftRoutes);
app.use('/api/config', configRoutes);
app.use('/api/sync', syncRoutes);

app.use((req, res) => {
  res.status(404).json({ error: 'Ruta no encontrada' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, () => {
  console.log(`NomiCheck API escuchando en http://localhost:${PORT}`);
});
