import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('wakanime.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        // Enable SQLite foreign keys cascade
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Anime table
    await db.execute('''
      CREATE TABLE anime (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image_path TEXT,
        season TEXT NOT NULL,
        season_year INTEGER NOT NULL,
        release_day TEXT,
        release_time TEXT,
        platform TEXT,
        source TEXT,
        external_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_anime_source_external_id
      ON anime (source, external_id)
      WHERE source IS NOT NULL AND external_id IS NOT NULL;
    ''');

    // Watchlist table (anime_id is UNIQUE, single record per anime)
    await db.execute('''
      CREATE TABLE watchlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        anime_id INTEGER NOT NULL UNIQUE,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (anime_id) REFERENCES anime (id) ON DELETE CASCADE
      );
    ''');

    // Generic key/value settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE anime ADD COLUMN source TEXT;');
      await db.execute('ALTER TABLE anime ADD COLUMN external_id TEXT;');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_anime_source_external_id
        ON anime (source, external_id)
        WHERE source IS NOT NULL AND external_id IS NOT NULL;
      ''');
    }
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
