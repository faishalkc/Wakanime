import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakanime/widgets/anime_search_field.dart';

void main() {
  group('AnimeSearchField Widget Tests', () {
    testWidgets('Updates query on typing and clears when clear button tapped',
        (tester) async {
      final controller = TextEditingController();
      String query = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimeSearchField(
                  controller: controller,
                  query: query,
                  hintText: 'Search watchlist...',
                  onChanged: (val) => setState(() => query = val),
                  onClear: () {
                    controller.clear();
                    setState(() => query = '');
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byTooltip('Clear Search'), findsNothing);

      await tester.enterText(find.byType(TextField), 'fri');
      await tester.pump();

      expect(query, 'fri');
      expect(find.byTooltip('Clear Search'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear Search'));
      await tester.pump();

      expect(query, '');
      expect(controller.text, '');
      expect(find.byTooltip('Clear Search'), findsNothing);

      controller.dispose();
    });
  });
}
