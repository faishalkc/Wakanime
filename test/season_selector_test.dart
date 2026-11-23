import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakanime/widgets/season_selector.dart';

void main() {
  group('SeasonSelector Widget Tests', () {
    testWidgets('Displays current season and year correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonSelector(
              season: 'fall',
              year: 2026,
              onSeasonChanged: (season, year) {},
            ),
          ),
        ),
      );

      expect(find.text('Fall 2026'), findsOneWidget);
    });

    testWidgets('Tapping next on Fall 2026 transitions to Winter 2027', (tester) async {
      String? changedSeason;
      int? changedYear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonSelector(
              season: 'fall',
              year: 2026,
              onSeasonChanged: (season, year) {
                changedSeason = season;
                changedYear = year;
              },
            ),
          ),
        ),
      );

      final nextButton = find.byTooltip('Next Season');
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();

      expect(changedSeason, 'winter');
      expect(changedYear, 2027);
    });

    testWidgets('Tapping previous on Winter 2027 transitions to Fall 2026', (tester) async {
      String? changedSeason;
      int? changedYear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonSelector(
              season: 'winter',
              year: 2027,
              onSeasonChanged: (season, year) {
                changedSeason = season;
                changedYear = year;
              },
            ),
          ),
        ),
      );

      final prevButton = find.byTooltip('Previous Season');
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pump();

      expect(changedSeason, 'fall');
      expect(changedYear, 2026);
    });

    testWidgets('Tapping next on Winter 2027 transitions to Spring 2027', (tester) async {
      String? changedSeason;
      int? changedYear;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeasonSelector(
              season: 'winter',
              year: 2027,
              onSeasonChanged: (season, year) {
                changedSeason = season;
                changedYear = year;
              },
            ),
          ),
        ),
      );

      final nextButton = find.byTooltip('Next Season');
      await tester.tap(nextButton);
      await tester.pump();

      expect(changedSeason, 'spring');
      expect(changedYear, 2027);
    });
  });
}
