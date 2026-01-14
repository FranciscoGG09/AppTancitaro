import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/report.dart';

class DatabaseService {
  static const String _dbName = 'municipal_reports.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Tabla de reportes offline
    await db.execute('''
      CREATE TABLE offline_reports (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        imagePath TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        syncedAt TEXT,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Tabla de configuración
    await db.execute('''
      CREATE TABLE app_config (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // Guardar reporte offline
  Future<void> saveOfflineReport(Report report) async {
    final db = await database;
    await db.insert(
      'offline_reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener reportes pendientes de sincronización
  Future<List<Report>> getPendingReports() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'offline_reports',
      where: 'isSynced = ?',
      whereArgs: [0],
    );

    return List.generate(maps.length, (i) => Report.fromMap(maps[i]));
  }

  // Marcar reporte como sincronizado
  Future<void> markReportAsSynced(String reportId) async {
    final db = await database;
    await db.update(
      'offline_reports',
      {
        'isSynced': 1,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  // Eliminar reportes sincronizados antiguos
  Future<void> deleteOldSyncedReports() async {
    final db = await database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    await db.delete(
      'offline_reports',
      where: 'isSynced = ? AND createdAt < ?',
      whereArgs: [1, weekAgo.toIso8601String()],
    );
  }

  // Obtener configuración
  Future<String?> getConfig(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_config',
      where: 'key = ?',
      whereArgs: [key],
    );

    return maps.isNotEmpty ? maps.first['value'] : null;
  }

  // Guardar configuración
  Future<void> setConfig(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_config',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Inicializar servicio
  Future<void> init() async {
    await database;
  }
}
