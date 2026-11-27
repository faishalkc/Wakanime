import 'package:sqflite/sqflite.dart';
import '../models/anime.dart';
import '../models/anime_import_data.dart';
import '../models/watchlist.dart';
import '../services/image_service.dart';
import 'database.dart';

class ImportBatchEntry {
  final AnimeImportData data;
  final String? stagedImagePath;

  const ImportBatchEntry({
    required this.data,
    this.stagedImagePath,
  });
}

class UpsertSeasonResult {
  final int insertedCount;
  final int updatedCount;
  final int failedImageSaveCount;

  const UpsertSeasonResult({
    required this.insertedCount,
    required this.updatedCount,
    required this.failedImageSaveCount,
  });

  int get totalProcessed => insertedCount + updatedCount;
}

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

  Future<List<WatchlistItem>> getWatchlistItems({
    String? status,
    String? season,
    int? seasonYear,
  }) async {
    final db = await _db;
    final conditions = <String>[];
    final args = <dynamic>[];

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      conditions.add('w.status = ?');
      args.add(status.toLowerCase());
    }
    if (season != null && season.isNotEmpty) {
      conditions.add('a.season = ?');
      args.add(season.toLowerCase());
    }
    if (seasonYear != null) {
      conditions.add('a.season_year = ?');
      args.add(seasonYear);
    }

    final whereClause =
        conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final query = '''
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
        a.source AS a_source,
        a.external_id AS a_external_id,
        a.created_at AS a_created_at,
        a.updated_at AS a_updated_at
      FROM watchlist w
      INNER JOIN anime a ON w.anime_id = a.id
      $whereClause
      ORDER BY a.title COLLATE NOCASE ASC
    ''';

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
        source: row['a_source'] as String?,
        externalId: row['a_external_id']?.toString(),
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
  // Atomic API Season Import Upsert
  // ---------------------------------------------------------------------------

  /// Atomically upserts imported anime in a single SQLite transaction.
  /// Preserves existing local-only fields (`platform`) and never modifies `watchlist`.
  Future<UpsertSeasonResult> upsertImportedSeason(
    List<ImportBatchEntry> entries, {
    Future<String> Function(int animeId, String stagedPath)? saveStagedImage,
    Future<void> Function(String? path)? deleteImage,
  }) async {
    final db = await _db;
    final saveImg = saveStagedImage ?? ImageService.instance.saveImageForAnime;
    final deleteImg = deleteImage ?? ImageService.instance.deleteImage;

    final createdFinalPaths = <String>[];
    final oldImagesToDelete = <String>[];
    int insertedCount = 0;
    int updatedCount = 0;
    int failedImageSaveCount = 0;

    try {
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();

        for (final entry in entries) {
          final data = entry.data;
          final existingRows = await txn.query(
            'anime',
            columns: ['id', 'image_path'],
            where: 'source = ? AND external_id = ?',
            whereArgs: [data.source, data.externalId],
            limit: 1,
          );

          if (existingRows.isNotEmpty) {
            final animeId = existingRows.first['id'] as int;
            final oldImagePath = existingRows.first['image_path'] as String?;

            String? newImagePath;
            if (entry.stagedImagePath != null) {
              try {
                newImagePath = await saveImg(animeId, entry.stagedImagePath!);
                createdFinalPaths.add(newImagePath);
              } catch (_) {
                failedImageSaveCount++;
                newImagePath = null;
              }
            }

            final updateValues = <String, dynamic>{
              'title': data.title,
              'season': data.season.toLowerCase(),
              'season_year': data.seasonYear,
              'release_day': data.releaseDay,
              'release_time': data.releaseTime,
              'updated_at': now,
            };

            // Only replace image_path if new image was saved successfully;
            // otherwise preserve existing image_path.
            if (newImagePath != null) {
              updateValues['image_path'] = newImagePath;
              if (oldImagePath != null &&
                  oldImagePath.isNotEmpty &&
                  oldImagePath != newImagePath) {
                oldImagesToDelete.add(oldImagePath);
              }
            }

            // Never touch `platform` or `watchlist` on re-import.
            await txn.update(
              'anime',
              updateValues,
              where: 'id = ?',
              whereArgs: [animeId],
            );
            updatedCount++;
          } else {
            final animeId = await txn.insert('anime', {
              'title': data.title,
              'image_path': null,
              'season': data.season.toLowerCase(),
              'season_year': data.seasonYear,
              'release_day': data.releaseDay,
              'release_time': data.releaseTime,
              'platform': data.platform,
              'source': data.source,
              'external_id': data.externalId,
              'created_at': now,
              'updated_at': now,
            });

            if (entry.stagedImagePath != null) {
              try {
                final savedPath = await saveImg(animeId, entry.stagedImagePath!);
                createdFinalPaths.add(savedPath);
                await txn.update(
                  'anime',
                  {'image_path': savedPath},
                  where: 'id = ?',
                  whereArgs: [animeId],
                );
              } catch (_) {
                failedImageSaveCount++;
              }
            }

            insertedCount++;
          }
        }
      });

      // Delete old replaced images only after SQLite transaction committed.
      for (final oldPath in oldImagesToDelete) {
        await deleteImg(oldPath);
      }

      return UpsertSeasonResult(
        insertedCount: insertedCount,
        updatedCount: updatedCount,
        failedImageSaveCount: failedImageSaveCount,
      );
    } catch (_) {
      // Roll back filesystem changes if SQLite transaction failed.
      for (final createdPath in createdFinalPaths) {
        await deleteImg(createdPath);
      }
      rethrow;
    }
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
