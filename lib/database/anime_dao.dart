import 'package:sqflite/sqflite.dart';
import '../models/anime.dart';
import '../models/watchlist.dart';
import '../services/image_service.dart';
import 'database.dart';

class AnimeDao {
  final AppDatabase _dbProvider;

  AnimeDao({AppDatabase? dbProvider})
      : _dbProvider = dbProvider ?? AppDatabase.instance;

  Future<Database> get _db async => await _dbProvider.database;

  // ---------------------------------------------------------------------------
  // Anime CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertAnime(Anime anime) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final data = anime.toMap();
    data['created_at'] = now;
    data['updated_at'] = now;
    return await db.insert('anime', data);
  }

  Future<int> updateAnime(Anime anime) async {
    if (anime.id == null) return 0;
    final db = await _db;
    final data = anime.toMap();
    data['updated_at'] = DateTime.now().toIso8601String();
    return await db.update(
      'anime',
      data,
      where: 'id = ?',
      whereArgs: [anime.id],
    );
  }

  Future<int> deleteAnime(int id) async {
    final db = await _db;

    // 1. Fetch current anime record to retrieve its image_path if any
    final existing = await getAnimeById(id);
    final imagePath = existing?.imagePath;

    // 2. Explicitly remove watchlist record to guarantee no orphans
    await db.delete('watchlist', where: 'anime_id = ?', whereArgs: [id]);

    // 3. Delete anime record
    final count = await db.delete('anime', where: 'id = ?', whereArgs: [id]);

    // 4. Delete the stored image file from storage if present
    if (imagePath != null && imagePath.isNotEmpty) {
      await ImageService.instance.deleteImage(imagePath);
    }

    return count;
  }

  Future<Anime?> getAnimeById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'anime',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Anime.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Anime>> getAnimeBySeason(String season, int seasonYear) async {
    final db = await _db;
    final maps = await db.query(
      'anime',
      where: 'season = ? AND season_year = ?',
      whereArgs: [season.toLowerCase(), seasonYear],
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return maps.map((map) => Anime.fromMap(map)).toList();
  }

  Future<List<Anime>> getAllAnime() async {
    final db = await _db;
    final maps = await db.query(
      'anime',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return maps.map((map) => Anime.fromMap(map)).toList();
  }

  Future<int> countAnime() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM anime');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Watchlist Operations
  // ---------------------------------------------------------------------------

  Future<Watchlist?> getWatchlistByAnimeId(int animeId) async {
    final db = await _db;
    final maps = await db.query(
      'watchlist',
      where: 'anime_id = ?',
      whereArgs: [animeId],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Watchlist.fromMap(maps.first);
    }
    return null;
  }

  Future<int> setWatchlistStatus(int animeId, String status) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final existing = await getWatchlistByAnimeId(animeId);

    if (existing != null) {
      // Update existing record, preserve anime_id & id, do not create duplicate
      return await db.update(
        'watchlist',
        {
          'status': status.toLowerCase(),
          'updated_at': now,
        },
        where: 'anime_id = ?',
        whereArgs: [animeId],
      );
    } else {
      // Insert new record
      return await db.insert('watchlist', {
        'anime_id': animeId,
        'status': status.toLowerCase(),
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  Future<int> removeFromWatchlist(int animeId) async {
    final db = await _db;
    // Remove from watchlist only, keep anime and image intact
    return await db.delete(
      'watchlist',
      where: 'anime_id = ?',
      whereArgs: [animeId],
    );
  }

  Future<List<WatchlistItem>> getWatchlistItems({String? status}) async {
    final db = await _db;
    final String query;
    final List<dynamic> args;

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      query = '''
        SELECT 
          w.id AS w_id,
          w.anime_id AS w_anime_id,
          w.status AS w_status,
          w.created_at AS w_created_at,
          w.updated_at AS w_updated_at,
          a.id AS a_id,
          a.title AS a_title,
          a.image_path AS a_image_path,
          a.season AS a_season,
          a.season_year AS a_season_year,
          a.release_day AS a_release_day,
          a.release_time AS a_release_time,
          a.platform AS a_platform,
          a.created_at AS a_created_at,
          a.updated_at AS a_updated_at
        FROM watchlist w
        INNER JOIN anime a ON w.anime_id = a.id
        WHERE w.status = ?
        ORDER BY w.updated_at DESC
      ''';
      args = [status.toLowerCase()];
    } else {
      query = '''
        SELECT 
          w.id AS w_id,
          w.anime_id AS w_anime_id,
          w.status AS w_status,
          w.created_at AS w_created_at,
          w.updated_at AS w_updated_at,
          a.id AS a_id,
          a.title AS a_title,
          a.image_path AS a_image_path,
          a.season AS a_season,
          a.season_year AS a_season_year,
          a.release_day AS a_release_day,
          a.release_time AS a_release_time,
          a.platform AS a_platform,
          a.created_at AS a_created_at,
          a.updated_at AS a_updated_at
        FROM watchlist w
        INNER JOIN anime a ON w.anime_id = a.id
        ORDER BY w.updated_at DESC
      ''';
      args = [];
    }

    final rows = await db.rawQuery(query, args);

    return rows.map((row) {
      final anime = Anime(
        id: row['a_id'] as int?,
        title: row['a_title'] as String? ?? '',
        imagePath: row['a_image_path'] as String?,
        season: row['a_season'] as String? ?? 'winter',
        seasonYear: (row['a_season_year'] as num?)?.toInt() ?? DateTime.now().year,
        releaseDay: row['a_release_day'] as String?,
        releaseTime: row['a_release_time'] as String?,
        platform: row['a_platform'] as String?,
        createdAt: row['a_created_at'] as String? ?? '',
        updatedAt: row['a_updated_at'] as String? ?? '',
      );

      final watchlist = Watchlist(
        id: row['w_id'] as int?,
        animeId: (row['w_anime_id'] as num).toInt(),
        status: row['w_status'] as String? ?? 'planned',
        createdAt: row['w_created_at'] as String? ?? '',
        updatedAt: row['w_updated_at'] as String? ?? '',
      );

      return WatchlistItem(anime: anime, watchlist: watchlist);
    }).toList();
  }

  Future<int> countWatchlist() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM watchlist');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Settings Operations
  // ---------------------------------------------------------------------------

  Future<String?> getSetting(String key) async {
    final db = await _db;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await _db;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearAllData() async {
    final db = await _db;
    // 1. Delete all saved anime image files
    final allAnime = await getAllAnime();
    for (final anime in allAnime) {
      if (anime.imagePath != null && anime.imagePath!.isNotEmpty) {
        await ImageService.instance.deleteImage(anime.imagePath);
      }
    }

    // 2. Clear tables
    await db.delete('watchlist');
    await db.delete('anime');
    await db.delete('settings');
  }
}
