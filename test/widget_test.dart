import 'package:flutter_test/flutter_test.dart';
import 'package:wakanime/models/anime.dart';
import 'package:wakanime/models/watchlist.dart';

void main() {
  group('Anime Model Tests', () {
    test('Anime model serialization and deserialization', () {
      final now = DateTime.now().toIso8601String();
      final anime = Anime(
        id: 1,
        title: 'Sousou no Frieren',
        imagePath: '/path/to/anime_1.jpg',
        season: 'fall',
        seasonYear: 2023,
        releaseDay: 'Friday',
        releaseTime: '23:00',
        platform: 'Crunchyroll',
        createdAt: now,
        updatedAt: now,
      );

      final map = anime.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Sousou no Frieren');
      expect(map['image_path'], '/path/to/anime_1.jpg');
      expect(map['season'], 'fall');
      expect(map['season_year'], 2023);
      expect(map['release_day'], 'Friday');
      expect(map['release_time'], '23:00');
      expect(map['platform'], 'Crunchyroll');

      final fromMap = Anime.fromMap(map);
      expect(fromMap.id, anime.id);
      expect(fromMap.title, anime.title);
      expect(fromMap.imagePath, anime.imagePath);
      expect(fromMap.season, anime.season);
      expect(fromMap.seasonYear, anime.seasonYear);
      expect(fromMap.seasonDisplay, 'Fall 2023');
    });

    test('Anime copyWith works correctly', () {
      const anime = Anime(
        id: 1,
        title: 'Original Title',
        imagePath: '/path/1.jpg',
        season: 'winter',
        seasonYear: 2024,
        createdAt: '2024-01-01',
        updatedAt: '2024-01-01',
      );

      final updated = anime.copyWith(
        title: 'Updated Title',
        clearImagePath: true,
      );

      expect(updated.id, 1);
      expect(updated.title, 'Updated Title');
      expect(updated.imagePath, isNull);
      expect(updated.season, 'winter');
    });
  });

  group('Watchlist Model Tests', () {
    test('Watchlist model serialization and deserialization', () {
      const watchlist = Watchlist(
        id: 1,
        animeId: 10,
        status: 'watching',
        createdAt: '2024-01-01',
        updatedAt: '2024-01-02',
      );

      final map = watchlist.toMap();
      expect(map['id'], 1);
      expect(map['anime_id'], 10);
      expect(map['status'], 'watching');

      final fromMap = Watchlist.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.animeId, 10);
      expect(fromMap.status, 'watching');
      expect(fromMap.label, 'Watching');
    });

    test('Watchlist status labels are formatted properly', () {
      expect(Watchlist.statusLabel('planned'), 'Planned');
      expect(Watchlist.statusLabel('watching'), 'Watching');
      expect(Watchlist.statusLabel('completed'), 'Completed');
      expect(Watchlist.statusLabel('dropped'), 'Dropped');
    });
  });
}
