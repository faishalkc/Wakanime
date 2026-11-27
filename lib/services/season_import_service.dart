import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/anime_dao.dart';
import '../models/anime_import_data.dart';
import 'image_service.dart';
import 'tenrai_provider.dart';

class SeasonImportResult {
  final int totalProcessed;
  final int insertedCount;
  final int updatedCount;
  final int failedImageCount;

  const SeasonImportResult({
    required this.totalProcessed,
    required this.insertedCount,
    required this.updatedCount,
    required this.failedImageCount,
  });
}

class SeasonImportService {
  final SeasonAnimeProvider _provider;
  final AnimeDao _animeDao;
  final Future<Directory> Function() _getTempDir;
  final Future<String?> Function({
    required String imageUrl,
    required Directory stagingDir,
    required String fileKey,
  }) _downloadToStaging;

  SeasonImportService({
    SeasonAnimeProvider? provider,
    AnimeDao? animeDao,
    Future<Directory> Function()? getTempDir,
    Future<String?> Function({
      required String imageUrl,
      required Directory stagingDir,
      required String fileKey,
    })? downloadToStaging,
  })  : _provider = provider ?? TenraiProvider(),
        _animeDao = animeDao ?? AnimeDao(),
        _getTempDir = getTempDir ?? getTemporaryDirectory,
        _downloadToStaging =
            downloadToStaging ?? ImageService.instance.downloadToStaging;

  Future<SeasonImportResult> importSeason({
    required String season,
    required int year,
    void Function(String status)? onProgress,
    Future<String> Function(int animeId, String stagedPath)? saveStagedImage,
    Future<void> Function(String? path)? deleteImage,
  }) async {
    // 1. Fetch ALL pages sequentially before touching local DB or storage.
    final rawItems = await _provider.fetchSeason(
      season: season,
      year: year,
      onProgress: onProgress,
    );

    // Deduplicate by (source, externalId) in case API pagination shifts across requests.
    final uniqueByKey = <String, AnimeImportData>{};
    for (final item in rawItems) {
      if (item.title.trim().isEmpty || item.externalId.trim().isEmpty) continue;
      final key = '${item.source}::${item.externalId}';
      uniqueByKey[key] = item;
    }
    final items = uniqueByKey.values.toList();

    if (items.isEmpty) {
      return const SeasonImportResult(
        totalProcessed: 0,
        insertedCount: 0,
        updatedCount: 0,
        failedImageCount: 0,
      );
    }

    // 2. Download images to an isolated staging directory.
    // Failure to download individual images must never abort the season import.
    final tempRoot = await _getTempDir();
    final stagingDir = Directory(
      p.join(
        tempRoot.path,
        'wakanime_import_${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
    await stagingDir.create(recursive: true);

    int failedDownloads = 0;

    try {
      onProgress?.call('Preparing images (0/${items.length})...');
      final stagedPaths = List<String?>.filled(items.length, null);

      const batchSize = 4;
      for (int start = 0; start < items.length; start += batchSize) {
        final end = (start + batchSize > items.length)
            ? items.length
            : start + batchSize;

        final futures = <Future<void>>[];
        for (int i = start; i < end; i++) {
          final imageUrl = items[i].imageUrl;
          if (imageUrl == null || imageUrl.isEmpty) continue;

          futures.add(() async {
            final staged = await _downloadToStaging(
              imageUrl: imageUrl,
              stagingDir: stagingDir,
              fileKey: 'staged_$i',
            );
            if (staged == null) {
              failedDownloads++;
            } else {
              stagedPaths[i] = staged;
            }
          }());
        }

        await Future.wait(futures);
        onProgress?.call('Preparing images ($end/${items.length})...');
      }

      // 3. Commit all records inside a single SQLite transaction.
      onProgress?.call('Saving to local database...');
      final batchEntries = <ImportBatchEntry>[
        for (int i = 0; i < items.length; i++)
          ImportBatchEntry(
            data: items[i],
            stagedImagePath: stagedPaths[i],
          ),
      ];

      final UpsertSeasonResult upsertResult;
      try {
        upsertResult = await _animeDao.upsertImportedSeason(
          batchEntries,
          saveStagedImage: saveStagedImage,
          deleteImage: deleteImage,
        );
      } on ImportException {
        rethrow;
      } catch (_) {
        throw const ImportException(
          'Failed to save imported anime to local database. Existing data was not changed.',
        );
      }

      return SeasonImportResult(
        totalProcessed: upsertResult.totalProcessed,
        insertedCount: upsertResult.insertedCount,
        updatedCount: upsertResult.updatedCount,
        failedImageCount: failedDownloads + upsertResult.failedImageSaveCount,
      );
    } finally {
      // Always clean up temporary staging files.
      try {
        if (await stagingDir.exists()) {
          await stagingDir.delete(recursive: true);
        }
      } catch (_) {
        // Ignore temp cleanup errors.
      }
    }
  }
}
