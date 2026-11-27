import 'package:flutter_test/flutter_test.dart';
import 'package:wakanime/models/anime.dart';
import 'package:wakanime/models/watchlist.dart';
import 'package:wakanime/screens/schedule/schedule_screen.dart';

WatchlistItem _makeItem({
  required int id,
  required String title,
  String season = 'fall',
  int seasonYear = 2026,
  String? releaseDay,
  String? releaseTime,
  String status = Watchlist.statusWatching,
}) {
  return WatchlistItem(
    anime: Anime(
      id: id,
      title: title,
      season: season,
      seasonYear: seasonYear,
      releaseDay: releaseDay,
      releaseTime: releaseTime,
      createdAt: '2026-10-01',
      updatedAt: '2026-10-01',
    ),
    watchlist: Watchlist(
      id: id,
      animeId: id,
      status: status,
      createdAt: '2026-10-01',
      updatedAt: '2026-10-01',
    ),
  );
}

void main() {
  group('Schedule Sorting & Grouping Tests', () {
    test('parseReleaseTimeMinutes parses valid and invalid times safely', () {
      expect(parseReleaseTimeMinutes('00:30'), 30);
      expect(parseReleaseTimeMinutes('9:15'), 9 * 60 + 15);
      expect(parseReleaseTimeMinutes('18:00'), 18 * 60);
      expect(parseReleaseTimeMinutes('23:30'), 23 * 60 + 30);

      // Missing or invalid times should return a large sentinel value without throwing
      expect(parseReleaseTimeMinutes(null), greaterThan(24 * 60));
      expect(parseReleaseTimeMinutes(''), greaterThan(24 * 60));
      expect(parseReleaseTimeMinutes('invalid'), greaterThan(24 * 60));
    });

    test('buildWeeklySchedule orders days Monday to Sunday, not alphabetically', () {
      final items = [
        _makeItem(id: 1, title: 'Sunday Anime', releaseDay: 'Sunday', releaseTime: '10:00'),
        _makeItem(id: 2, title: 'Friday Anime', releaseDay: 'Friday', releaseTime: '22:00'),
        _makeItem(id: 3, title: 'Monday Anime', releaseDay: 'Monday', releaseTime: '18:00'),
        _makeItem(id: 4, title: 'Tuesday Anime', releaseDay: 'Tuesday', releaseTime: '19:00'),
        _makeItem(id: 5, title: 'Thursday Anime', releaseDay: 'Thursday', releaseTime: '21:00'),
        _makeItem(id: 6, title: 'Wednesday Anime', releaseDay: 'Wednesday', releaseTime: '20:00'),
        _makeItem(id: 7, title: 'Saturday Anime', releaseDay: 'Saturday', releaseTime: '23:00'),
      ];

      final schedule = buildWeeklySchedule(items);

      expect(
        schedule.map((d) => d.day).toList(),
        ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      );
    });

    test('buildWeeklySchedule sorts items chronologically within the same day', () {
      final items = [
        _makeItem(id: 1, title: 'Late Night', releaseDay: 'Monday', releaseTime: '23:30'),
        _makeItem(id: 2, title: 'No Time', releaseDay: 'Monday', releaseTime: null),
        _makeItem(id: 3, title: 'Evening', releaseDay: 'Monday', releaseTime: '18:00'),
        _makeItem(id: 4, title: 'Morning Single Digit', releaseDay: 'Monday', releaseTime: '9:05'),
        _makeItem(id: 5, title: 'Midnight', releaseDay: 'Monday', releaseTime: '00:30'),
      ];

      final schedule = buildWeeklySchedule(items);
      expect(schedule.length, 1);
      expect(
        schedule.first.items.map((e) => e.anime.title).toList(),
        ['Midnight', 'Morning Single Digit', 'Evening', 'Late Night', 'No Time'],
      );
    });

    test('buildWeeklySchedule safely ignores items with null or empty releaseDay', () {
      final items = [
        _makeItem(id: 1, title: 'No Day', releaseDay: null, releaseTime: '18:00'),
        _makeItem(id: 2, title: 'Empty Day', releaseDay: '  ', releaseTime: '19:00'),
        _makeItem(id: 3, title: 'Valid Day', releaseDay: 'monday', releaseTime: '20:00'),
      ];

      final schedule = buildWeeklySchedule(items);
      expect(schedule.length, 1);
      expect(schedule.first.day, 'Monday');
      expect(schedule.first.items.length, 1);
      expect(schedule.first.items.first.anime.title, 'Valid Day');
    });

    test('buildWeeklySchedule includes all watchlist statuses and filters by current season/year', () {
      final items = [
        _makeItem(
          id: 1,
          title: 'Planned Fall',
          season: 'fall',
          seasonYear: 2026,
          releaseDay: 'Monday',
          releaseTime: '18:00',
          status: Watchlist.statusPlanned,
        ),
        _makeItem(
          id: 2,
          title: 'Watching Fall',
          season: 'fall',
          seasonYear: 2026,
          releaseDay: 'Monday',
          releaseTime: '19:00',
          status: Watchlist.statusWatching,
        ),
        _makeItem(
          id: 3,
          title: 'Completed Fall',
          season: 'fall',
          seasonYear: 2026,
          releaseDay: 'Monday',
          releaseTime: '20:00',
          status: Watchlist.statusCompleted,
        ),
        _makeItem(
          id: 4,
          title: 'Dropped Fall',
          season: 'fall',
          seasonYear: 2026,
          releaseDay: 'Monday',
          releaseTime: '21:00',
          status: Watchlist.statusDropped,
        ),
        _makeItem(
          id: 5,
          title: 'Other Season Summer',
          season: 'summer',
          seasonYear: 2026,
          releaseDay: 'Monday',
          releaseTime: '17:00',
          status: Watchlist.statusWatching,
        ),
        _makeItem(
          id: 6,
          title: 'Other Year Fall',
          season: 'fall',
          seasonYear: 2025,
          releaseDay: 'Monday',
          releaseTime: '16:00',
          status: Watchlist.statusCompleted,
        ),
      ];

      final schedule = buildWeeklySchedule(
        items,
        season: 'fall',
        seasonYear: 2026,
      );

      expect(schedule.length, 1);
      expect(
        schedule.first.items.map((e) => e.anime.title).toList(),
        ['Planned Fall', 'Watching Fall', 'Completed Fall', 'Dropped Fall'],
      );
    });

    test('Anime.currentSeasonYear maps device dates consistently', () {
      expect(
        Anime.currentSeasonYear(DateTime(2026, 11, 27)),
        (season: 'fall', year: 2026),
      );
      expect(
        Anime.currentSeasonYear(DateTime(2027, 1, 15)),
        (season: 'winter', year: 2027),
      );
      expect(
        Anime.currentSeasonYear(DateTime(2027, 4, 1)),
        (season: 'spring', year: 2027),
      );
      expect(
        Anime.currentSeasonYear(DateTime(2027, 7, 10)),
        (season: 'summer', year: 2027),
      );
      expect(
        Anime.currentSeasonYear(DateTime(2027, 10, 5)),
        (season: 'fall', year: 2027),
      );
    });
  });
}
