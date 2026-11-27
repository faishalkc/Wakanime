import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakanime/database/anime_dao.dart';
import 'package:wakanime/models/anime.dart';
import 'package:wakanime/models/watchlist.dart';
import 'package:wakanime/screens/schedule/schedule_screen.dart';
import 'package:wakanime/services/season_import_service.dart';
import 'package:wakanime/services/tenrai_provider.dart';

class _InMemoryAnimeDao extends AnimeDao {
  int _nextId = 1;
  final List<Anime> animeTable = [];
  final Map<int, Watchlist> watchlistTable = {};
  final List<String> deletedImagePaths = [];
  bool simulateDbFailure = false;

  @override
  Future<UpsertSeasonResult> upsertImportedSeason(
    List<ImportBatchEntry> entries, {
    Future<String> Function(int animeId, String stagedPath)? saveStagedImage,
    Future<void> Function(String? path)? deleteImage,
  }) async {
    // Snapshot state to simulate SQLite transaction rollback
    final snapshotAnime = List<Anime>.from(animeTable);
    final snapshotNextId = _nextId;
    final createdPaths = <String>[];
    final oldToDelete = <String>[];

    int inserted = 0;
    int updated = 0;
    int failedImg = 0;

    try {
      final now = DateTime.now().toIso8601String();
      for (final entry in entries) {
        if (simulateDbFailure && inserted == 1) {
          throw Exception('Simulated SQLite constraint/write failure');
        }

        final data = entry.data;
        final existingIdx = animeTable.indexWhere(
          (a) => a.source == data.source && a.externalId == data.externalId,
        );

        if (existingIdx != -1) {
          final existing = animeTable[existingIdx];
          final animeId = existing.id!;
          String? newImagePath;

          if (entry.stagedImagePath != null) {
            try {
              newImagePath = saveStagedImage != null
                  ? await saveStagedImage(animeId, entry.stagedImagePath!)
                  : '/local/anime_$animeId.jpg';
              createdPaths.add(newImagePath);
            } catch (_) {
              failedImg++;
            }
          }

          if (newImagePath != null &&
              existing.imagePath != null &&
              existing.imagePath != newImagePath) {
            oldToDelete.add(existing.imagePath!);
          }

          animeTable[existingIdx] = existing.copyWith(
            title: data.title,
            imagePath: newImagePath ?? existing.imagePath,
            season: data.season,
            seasonYear: data.seasonYear,
            releaseDay: data.releaseDay,
            releaseTime: data.releaseTime,
            // Preserve existing platform!
            updatedAt: now,
          );
          updated++;
        } else {
          final animeId = _nextId++;
          String? savedPath;
          if (entry.stagedImagePath != null) {
            try {
              savedPath = saveStagedImage != null
                  ? await saveStagedImage(animeId, entry.stagedImagePath!)
                  : '/local/anime_$animeId.jpg';
              createdPaths.add(savedPath);
            } catch (_) {
              failedImg++;
            }
          }

          animeTable.add(
            Anime(
              id: animeId,
              title: data.title,
              imagePath: savedPath,
              season: data.season,
              seasonYear: data.seasonYear,
              releaseDay: data.releaseDay,
              releaseTime: data.releaseTime,
              platform: data.platform,
              source: data.source,
              externalId: data.externalId,
              createdAt: now,
              updatedAt: now,
            ),
          );
          inserted++;
        }
      }

      for (final oldPath in oldToDelete) {
        deletedImagePaths.add(oldPath);
        if (deleteImage != null) await deleteImage(oldPath);
      }

      return UpsertSeasonResult(
        insertedCount: inserted,
        updatedCount: updated,
        failedImageSaveCount: failedImg,
      );
    } catch (_) {
      // Rollback in-memory DB & delete newly created images
      animeTable
        ..clear()
        ..addAll(snapshotAnime);
      _nextId = snapshotNextId;
      for (final p in createdPaths) {
        deletedImagePaths.add(p);
        if (deleteImage != null) await deleteImage(p);
      }
      rethrow;
    }
  }
}

Map<String, dynamic> _tenraiAnimeJson({
  required int malId,
  required String title,
  String? season = 'fall',
  int? year = 2026,
  String? day = 'Fridays',
  String? time = '23:00',
  String? imageUrl = 'https://cdn.example.com/poster.jpg',
}) {
  return {
    'mal_id': malId,
    'title': title,
    'season': season,
    'year': year,
    'images': {
      'jpg': {
        'image_url': imageUrl,
      },
    },
    'broadcast': {
      'day': day,
      'time': time,
      'timezone': 'Asia/Tokyo',
    },
  };
}

String _pagePayload({
  required int currentPage,
  required int lastVisiblePage,
  required bool hasNextPage,
  required List<Map<String, dynamic>> items,
}) {
  return jsonEncode({
    'pagination': {
      'current_page': currentPage,
      'last_visible_page': lastVisiblePage,
      'has_next_page': hasNextPage,
      'items': {
        'count': items.length,
        'total': items.length,
        'per_page': 25,
      },
    },
    'data': items,
  });
}

void main() {
  group('TenraiProvider Tests', () {
    test('Fetches all pages sequentially and normalizes fields', () async {
      final requestedPages = <String>[];
      final progressMessages = <String>[];

      final provider = TenraiProvider(
        delay: (_) async {},
        httpGet: (uri) async {
          final page = uri.queryParameters['page'] ?? '1';
          requestedPages.add(page);
          if (page == '1') {
            return HttpResponseData(
              statusCode: 200,
              body: _pagePayload(
                currentPage: 1,
                lastVisiblePage: 3,
                hasNextPage: true,
                items: [
                  _tenraiAnimeJson(
                    malId: 101,
                    title: 'Anime One',
                    day: 'Mondays',
                    time: '23:00',
                  ),
                ],
              ),
            );
          } else if (page == '2') {
            return HttpResponseData(
              statusCode: 200,
              body: _pagePayload(
                currentPage: 2,
                lastVisiblePage: 3,
                hasNextPage: true,
                items: [
                  _tenraiAnimeJson(
                    malId: 102,
                    title: 'Anime Two (No Broadcast)',
                    day: null,
                    time: null,
                  ),
                ],
              ),
            );
          } else {
            return HttpResponseData(
              statusCode: 200,
              body: _pagePayload(
                currentPage: 3,
                lastVisiblePage: 3,
                hasNextPage: false,
                items: [
                  _tenraiAnimeJson(
                    malId: 103,
                    title: 'Anime Three',
                    season: null,
                    year: null,
                    day: 'Sundays',
                    time: '01:30',
                  ),
                ],
              ),
            );
          }
        },
      );

      final items = await provider.fetchSeason(
        season: 'fall',
        year: 2026,
        onProgress: progressMessages.add,
      );

      expect(requestedPages, ['1', '2', '3']);
      expect(items.length, 3);
      expect(progressMessages, contains('Fetching page 1 of 3...'));
      expect(progressMessages, contains('Fetching page 2 of 3...'));
      expect(progressMessages, contains('Fetching page 3 of 3...'));

      expect(items[0].source, 'tenrai');
      expect(items[0].externalId, '101');
      expect(items[0].releaseDay, 'Monday');
      expect(items[0].releaseTime, '23:00');
      expect(items[0].platform, isNull);

      expect(items[1].releaseDay, isNull);
      expect(items[1].releaseTime, isNull);

      // Fallback to requested season/year when API item omits them
      expect(items[2].season, 'fall');
      expect(items[2].seasonYear, 2026);
      expect(items[2].releaseDay, 'Sunday');
      expect(items[2].releaseTime, '01:30');
    });

    test('Handles HTTP 429 with Retry-After delay and retries', () async {
      int calls = 0;
      final recordedDelays = <Duration>[];

      final provider = TenraiProvider(
        delay: (d) async => recordedDelays.add(d),
        httpGet: (uri) async {
          calls++;
          if (calls == 1) {
            return const HttpResponseData(
              statusCode: 429,
              body: '{"error": "Too Many Requests"}',
              retryAfterHeader: '4',
            );
          }
          return HttpResponseData(
            statusCode: 200,
            body: _pagePayload(
              currentPage: 1,
              lastVisiblePage: 1,
              hasNextPage: false,
              items: [_tenraiAnimeJson(malId: 201, title: 'Recovered Anime')],
            ),
          );
        },
      );

      final items = await provider.fetchSeason(season: 'fall', year: 2026);

      expect(calls, 2);
      expect(recordedDelays, contains(const Duration(seconds: 4)));
      expect(items.length, 1);
      expect(items.first.title, 'Recovered Anime');
    });

    test('Throws ImportException on malformed JSON', () async {
      final provider = TenraiProvider(
        delay: (_) async {},
        httpGet: (_) async => const HttpResponseData(
          statusCode: 200,
          body: 'not valid json',
        ),
      );

      expect(
        () => provider.fetchSeason(season: 'fall', year: 2026),
        throwsA(isA<ImportException>()),
      );
    });
  });

  group('SeasonImportService End-to-End Cases', () {
    late Directory tempRoot;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('wakanime_import_test_');
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('Upsert, preserves platform & watchlist, allows manual anime, handles image failure & rollback', () async {
      final dao = _InMemoryAnimeDao();

      // Seed a manual anime with the exact same title as an API anime
      dao.animeTable.add(
        const Anime(
          id: 1,
          title: 'Frieren',
          imagePath: null,
          season: 'fall',
          seasonYear: 2026,
          platform: 'Netflix',
          source: null,
          externalId: null,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      );
      dao.animeTable[0] = dao.animeTable[0];
      // Adjust _nextId via initial import simulation
      dao.watchlistTable[1] = const Watchlist(
        id: 1,
        animeId: 1,
        status: Watchlist.statusWatching,
        createdAt: '2026-01-01',
        updatedAt: '2026-01-01',
      );

      final provider = TenraiProvider(
        delay: (_) async {},
        httpGet: (uri) async {
          return HttpResponseData(
            statusCode: 200,
            body: _pagePayload(
              currentPage: 1,
              lastVisiblePage: 1,
              hasNextPage: false,
              items: [
                _tenraiAnimeJson(
                  malId: 52991,
                  title: 'Frieren',
                  day: 'Fridays',
                  time: '23:00',
                  imageUrl: 'https://cdn.example.com/ok.jpg',
                ),
                _tenraiAnimeJson(
                  malId: 99999,
                  title: 'Movie Without Broadcast',
                  day: null,
                  time: null,
                  imageUrl: 'https://cdn.example.com/fail.jpg',
                ),
              ],
            ),
          );
        },
      );

      bool failImageDownload = false;
      final service = SeasonImportService(
        provider: provider,
        animeDao: dao,
        getTempDir: () async => tempRoot,
        downloadToStaging: ({
          required String imageUrl,
          required Directory stagingDir,
          required String fileKey,
        }) async {
          if (failImageDownload || imageUrl.contains('fail.jpg')) {
            return null; // Simulate image download failure
          }
          final f = File('${stagingDir.path}/$fileKey.jpg');
          await f.writeAsString('img');
          return f.path;
        },
      );

      // 1. Initial import
      final res1 = await service.importSeason(
        season: 'fall',
        year: 2026,
        saveStagedImage: (id, path) async => '/perm/anime_${id}_v1.jpg',
        deleteImage: (_) async {},
      );

      expect(res1.totalProcessed, 2);
      expect(res1.insertedCount, 2);
      expect(res1.updatedCount, 0);
      expect(res1.failedImageCount, 1);
      // 1 manual + 2 imported = 3 records (no duplicate collision with manual)
      expect(dao.animeTable.length, 3);

      final apiFrieren = dao.animeTable.firstWhere(
        (a) => a.source == 'tenrai' && a.externalId == '52991',
      );
      expect(apiFrieren.imagePath, '/perm/anime_${apiFrieren.id}_v1.jpg');
      expect(apiFrieren.platform, isNull);

      final movie = dao.animeTable.firstWhere(
        (a) => a.externalId == '99999',
      );
      // Image failed on new anime -> imported with null imagePath
      expect(movie.imagePath, isNull);
      expect(movie.releaseDay, isNull);
      expect(movie.releaseTime, isNull);

      // Verify Schedule compatibility for null broadcast anime
      final schedule = buildWeeklySchedule([
        WatchlistItem(
          anime: movie,
          watchlist: const Watchlist(
            id: 2,
            animeId: 3,
            status: Watchlist.statusPlanned,
            createdAt: '2026-01-01',
            updatedAt: '2026-01-01',
          ),
        ),
      ]);
      expect(schedule, isEmpty);

      // 2. User sets platform manually and adds API Frieren to Watchlist
      final frierenIdx = dao.animeTable.indexOf(apiFrieren);
      dao.animeTable[frierenIdx] = apiFrieren.copyWith(platform: 'Crunchyroll');
      dao.watchlistTable[apiFrieren.id!] = Watchlist(
        id: 2,
        animeId: apiFrieren.id!,
        status: Watchlist.statusWatching,
        createdAt: '2026-10-01',
        updatedAt: '2026-10-01',
      );

      // 3. Re-import with image download failure -> must preserve old imagePath, platform, watchlist!
      failImageDownload = true;
      final res2 = await service.importSeason(
        season: 'fall',
        year: 2026,
        saveStagedImage: (id, path) async => '/perm/anime_${id}_v2.jpg',
        deleteImage: (_) async {},
      );

      expect(res2.insertedCount, 0);
      expect(res2.updatedCount, 2);
      expect(dao.animeTable.length, 3);

      final updatedFrieren = dao.animeTable.firstWhere(
        (a) => a.source == 'tenrai' && a.externalId == '52991',
      );
      expect(updatedFrieren.platform, 'Crunchyroll');
      expect(updatedFrieren.imagePath, '/perm/anime_${apiFrieren.id}_v1.jpg');
      expect(dao.watchlistTable[apiFrieren.id!]?.status, Watchlist.statusWatching);

      // 4. Re-import with image download success -> replaces image and deletes old image
      failImageDownload = false;
      await service.importSeason(
        season: 'fall',
        year: 2026,
        saveStagedImage: (id, path) async => '/perm/anime_${id}_v2.jpg',
        deleteImage: (_) async {},
      );

      final reUpdatedFrieren = dao.animeTable.firstWhere(
        (a) => a.source == 'tenrai' && a.externalId == '52991',
      );
      expect(reUpdatedFrieren.imagePath, '/perm/anime_${apiFrieren.id}_v2.jpg');
      expect(dao.deletedImagePaths, contains('/perm/anime_${apiFrieren.id}_v1.jpg'));
    });

    test('Critical pagination failure aborts atomically without modifying DB', () async {
      final dao = _InMemoryAnimeDao();
      dao.animeTable.add(
        const Anime(
          id: 1,
          title: 'Existing Anime',
          season: 'fall',
          seasonYear: 2026,
          createdAt: '2026-01-01',
          updatedAt: '2026-01-01',
        ),
      );

      final failingProvider = TenraiProvider(
        delay: (_) async {},
        httpGet: (uri) async {
          final page = uri.queryParameters['page'] ?? '1';
          if (page == '1') {
            return HttpResponseData(
              statusCode: 200,
              body: _pagePayload(
                currentPage: 1,
                lastVisiblePage: 3,
                hasNextPage: true,
                items: [_tenraiAnimeJson(malId: 101, title: 'Page 1 Anime')],
              ),
            );
          } else if (page == '2') {
            return HttpResponseData(
              statusCode: 200,
              body: _pagePayload(
                currentPage: 2,
                lastVisiblePage: 3,
                hasNextPage: true,
                items: [_tenraiAnimeJson(malId: 102, title: 'Page 2 Anime')],
              ),
            );
          } else {
            // Page 3 fails
            return const HttpResponseData(
              statusCode: 503,
              body: 'Service Unavailable',
            );
          }
        },
      );

      final service = SeasonImportService(
        provider: failingProvider,
        animeDao: dao,
        getTempDir: () async => tempRoot,
      );

      await expectLater(
        () => service.importSeason(season: 'fall', year: 2026),
        throwsA(isA<ImportException>()),
      );

      // Existing data must remain completely untouched
      expect(dao.animeTable.length, 1);
      expect(dao.animeTable.first.title, 'Existing Anime');
    });
  });
}
