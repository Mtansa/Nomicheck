import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/shift.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'nomicheck.db';
  static const int _dbVersion = 2;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), _dbName);
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await _ensureUserIdColumn(db);
    return db;
  }

  /// Instalaciones anteriores a la v2 se quedaron con la tabla creada sin la
  /// columna userId pero ya registradas como version 2, por lo que onUpgrade
  /// no llega a ejecutarse. Esta comprobacion cubre ese caso.
  static Future<void> _ensureUserIdColumn(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(shifts)');
    if (columns.any((c) => c['name'] == 'userId')) return;

    try {
      await db.execute('ALTER TABLE shifts ADD COLUMN userId TEXT');
    } on DatabaseException catch (e) {
      // onUpgrade pudo añadirla entre la comprobacion y el ALTER
      if (!e.toString().contains('duplicate column name')) rethrow;
    }

    final rows = await db.query('shifts');
    for (final row in rows) {
      if (row['userId'] == null) {
        await db.update(
          'shifts',
          {'userId': ''},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE shifts (
        id TEXT PRIMARY KEY,
        entryTime TEXT NOT NULL,
        exitTime TEXT,
        type INTEGER NOT NULL,
        notes TEXT,
        latitude REAL,
        longitude REAL,
        userId TEXT
      )
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // La columna userId la garantiza _ensureUserIdColumn al abrir la base.
  }

  // CRUD Operations for Shifts
  static Future<void> insertShift(Shift shift, {String? userId}) async {
    final db = await database;
    await db.insert('shifts', {...shift.toMap(), 'userId': userId});
  }

  static Future<void> updateShift(Shift shift, {String? userId}) async {
    final db = await database;
    await db.update(
      'shifts',
      {...shift.toMap(), if (userId != null) 'userId': userId},
      where: 'id = ?',
      whereArgs: [shift.id],
    );
  }

  static Future<void> deleteShift(String id) async {
    final db = await database;
    await db.delete(
      'shifts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Borra los turnos de un usuario al cerrar sesión, para que no se
  /// mezclen con los de otra cuenta en el mismo dispositivo.
  static Future<void> deleteShiftsForUser(String userId) async {
    final db = await database;
    await db.delete('shifts', where: 'userId = ?', whereArgs: [userId]);
  }

  static Future<List<Shift>> getAllShifts({String? userId}) async {
    if (userId == null) return const [];
    final db = await database;
    final maps = await db.query(
      'shifts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'entryTime DESC',
    );
    return maps.map((map) => Shift.fromMap(map)).toList();
  }

  static Future<List<Shift>> getShiftsByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    if (userId == null) return const [];
    final db = await database;
    final maps = await db.query(
      'shifts',
      where: 'entryTime >= ? AND entryTime <= ? AND userId = ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String(), userId],
      orderBy: 'entryTime DESC',
    );
    return maps.map((map) => Shift.fromMap(map)).toList();
  }

  static Future<List<Shift>> getShiftsByMonth(int year, int month, {String? userId}) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getShiftsByDateRange(start, end, userId: userId);
  }

  static Future<Shift?> getOpenShift({String? userId}) async {
    if (userId == null) return null;
    final db = await database;
    final maps = await db.query(
      'shifts',
      where: 'exitTime IS NULL AND userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Shift.fromMap(maps.first);
  }

  static Future<Map<String, dynamic>> getShiftsStats(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    final shifts = await getShiftsByDateRange(start, end, userId: userId);

    double totalMinutes = 0;
    double normalMinutes = 0;
    double extraMinutes = 0;
    double nightMinutes = 0;
    double sundayMinutes = 0;

    for (final shift in shifts) {
      totalMinutes += shift.duration.inMinutes;
      normalMinutes += shift.normalHours.inMinutes;
      extraMinutes += shift.extraHours.inMinutes;
      nightMinutes += shift.nightHours.inMinutes;
      if (shift.isSundayOrHoliday) {
        sundayMinutes += shift.duration.inMinutes;
      }
    }

    return {
      'totalShifts': shifts.length,
      'totalHours': totalMinutes / 60,
      'normalHours': normalMinutes / 60,
      'extraHours': extraMinutes / 60,
      'nightHours': nightMinutes / 60,
      'sundayHours': sundayMinutes / 60,
    };
  }
}
