import 'package:flutter/material.dart';

class SeasonSelector extends StatelessWidget {
  final String season;
  final int year;
  final void Function(String newSeason, int newYear) onSeasonChanged;

  const SeasonSelector({
    super.key,
    required this.season,
    required this.year,
    required this.onSeasonChanged,
  });

  static const List<String> _seasons = ['winter', 'spring', 'summer', 'fall'];

  void _onPrevious() {
    final currentIndex = _seasons.indexOf(season.toLowerCase());
    if (currentIndex == -1) return;

    if (currentIndex == 0) {
      // Winter -> Fall of previous year
      onSeasonChanged('fall', year - 1);
    } else {
      onSeasonChanged(_seasons[currentIndex - 1], year);
    }
  }

  void _onNext() {
    final currentIndex = _seasons.indexOf(season.toLowerCase());
    if (currentIndex == -1) return;

    if (currentIndex == _seasons.length - 1) {
      // Fall -> Winter of next year
      onSeasonChanged('winter', year + 1);
    } else {
      onSeasonChanged(_seasons[currentIndex + 1], year);
    }
  }

  String _formatSeason(String s) {
    if (s.isEmpty) return '';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = '${_formatSeason(season)} $year';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Season',
            onPressed: _onPrevious,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month, size: 20),
              const SizedBox(width: 8),
              Text(
                displayText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Season',
            onPressed: _onNext,
          ),
        ],
      ),
    );
  }
}
