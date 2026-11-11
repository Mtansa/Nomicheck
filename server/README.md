# NomiCheck — Servidor (Node.js + MySQL)

API REST que almacena usuarios, turnos y configuración en MySQL.

## Requisitos

- Node.js 18 o superior
- MySQL 8 (o MariaDB 10.4+)

## Puesta en marcha

### 1. Instalar dependencias

```bash
cd server
npm install
```

### 2. Configurar el entorno

```bash
cp .env.example .env
```

Edita `.env` con tus credenciales:

```env
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=nomicheck
DB_PASSWORD=tu_password
DB_NAME=nomicheck
JWT_SECRET=una_cadena_larga_y_aleatoria
```

### 3. Crear el usuario de MySQL

```sql
CREATE USER 'nomicheck'@'localhost' IDENTIFIED BY 'tu_password';
GRANT ALL PRIVILEGES ON nomicheck.* TO 'nomicheck'@'localhost';
FLUSH PRIVILEGES;
```

El comando `npm run migrate` crea la base de datos si no existe, pero el usuario
necesita permiso de `CREATE` para eso. Si prefieres crearla a mano:

```sql
CREATE DATABASE nomicheck CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 4. Aplicar el esquema

```bash
npm run migrate
```

Crea las tablas `users`, `shifts` y `user_configs`.

### 5. (Opcional) Usuario de prueba

```bash
npm run seed
```

Crea `demo@nomicheck.app` / `demo1234`.

### 6. Arrancar el servidor

```bash
npm start
```

El API queda en `http://localhost:3000/api`.

## Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/health` | Estado del servidor |
| POST | `/api/auth/register` | Crear cuenta → `{token, user}` |
| POST | `/api/auth/login` | Iniciar sesión → `{token, user}` |
| GET | `/api/auth/me` | Perfil del usuario autenticado |
| PUT | `/api/auth/me` | Actualizar nombre, puesto, empresa |
| GET | `/api/shifts` | Listar turnos (opcional `?since=`) |
| POST | `/api/shifts` | Upsert masivo de turnos |
| PUT | `/api/shifts/:id` | Actualizar un turno |
| DELETE | `/api/shifts/:id` | Eliminar un turno |
| GET | `/api/config` | Leer configuración |
| PUT | `/api/config` | Guardar configuración |
| POST | `/api/sync` | Sincronización completa (push + pull) |

Todos salvo `register`, `login` y `health` requieren el header
`Authorization: Bearer <token>`.

### Ejemplo

```bash
# Registro
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ana","email":"ana@ejemplo.com","password":"secreto123"}'

# Sincronización
curl -X POST http://localhost:3000/api/sync \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TU_TOKEN" \
  -d '{"shifts":[{"id":"uuid","entryTime":"2026-03-10T08:00:00.000Z","exitTime":"2026-03-10T16:00:00.000Z","type":0}]}'
```

## Esquema

- **users** — id, name, email (único), password_hash (bcrypt), position, company
- **shifts** — id (UUID del dispositivo), user_id, entry_time, exit_time, type, notes, lat/lng
- **user_configs** — una fila por usuario con salario, recargos, GPS, horarios

## Seguridad

- Contraseñas hasheadas con bcrypt (coste 10)
- Tokens JWT con expiración configurable (30 días por defecto)
- Consultas parametrizadas vía `mysql2` (sin concatenación SQL)
- Claves foráneas con `ON DELETE CASCADE`
