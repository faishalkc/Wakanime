import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/anime.dart';
import '../../models/watchlist.dart';
import '../../services/image_service.dart';
import '../../widgets/empty_state.dart';
import '../anime/anime_detail_screen.dart';

/// Represents a single day section in the weekly schedule.
class DaySchedule {
  final String day;
  final List<WatchlistItem> items;

  const DaySchedule({
    required this.day,
    required this.items,
  });
}

/// Parses an HH:mm time string into minutes since midnight for chronological sorting.
/// Returns a sentinel large value for null, empty, or malformed values so they sort last.
int parseReleaseTimeMinutes(String? time) {
  if (time == null) return 1 << 30;
  final trimmed = time.trim();
  if (trimmed.isEmpty) return 1 << 30;

  final parts = trimmed.split(':');
  if (parts.length < 2) return 1 << 30;

  final hour = int.tryParse(parts[0].trim());
  final minutePart = parts[1].trim().split(RegExp(r'\s+')).first;
  final minute = int.tryParse(minutePart);
  if (hour == null || minute == null) return 1 << 30;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return 1 << 30;

  return hour * 60 + minute;
}

/// Groups watchlist anime by release day (Monday -> Sunday) and sorts each day
/// chronologically by release time, using title as a deterministic tie-breaker.
/// When [season] and [seasonYear] are provided, only items matching that season
/// and year are included.
List<DaySchedule> buildWeeklySchedule(
  List<WatchlistItem> watchlistItems, {
  String? season,
  int? seasonYear,
}) {
  final grouped = <String, List<WatchlistItem>>{};
  final targetSeason = season?.trim().toLowerCase();

  for (final item in watchlistItems) {
    if (targetSeason != null &&
        item.anime.season.toLowerCase() != targetSeason) {
      continue;
    }
    if (seasonYear != null && item.anime.seasonYear != seasonYear) {
      continue;
    }

    final rawDay = item.anime.releaseDay?.trim();
    if (rawDay == null || rawDay.isEmpty) continue;

    final matchedDay = Anime.validDays.cast<String?>().firstWhere(
          (d) => d!.toLowerCase() == rawDay.toLowerCase(),
          orElse: () => null,
        );
    if (matchedDay == null) continue;

    grouped.putIfAbsent(matchedDay, () => []).add(item);
  }

  final schedule = <DaySchedule>[];
  for (final day in Anime.validDays) {
    final dayItems = grouped[day];
    if (dayItems == null || dayItems.isEmpty) continue;

    dayItems.sort((a, b) {
      final timeCmp = parseReleaseTimeMinutes(a.anime.releaseTime)
          .compareTo(parseReleaseTimeMinutes(b.anime.releaseTime));
      if (timeCmp != 0) return timeCmp;
      return a.anime.title.toLowerCase().compareTo(b.anime.title.toLowerCase());
    });

    schedule.add(DaySchedule(day: day, items: dayItems));
  }

  return schedule;
}

class ScheduleScreen extends StatefulWidget {
  final int refreshTick;

  const ScheduleScreen({
    super.key,
    this.refreshTick = 0,
  });

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _animeDao = AnimeDao();

  bool _isLoading = true;
  bool _hasWatchlistItems = false;
  List<DaySchedule> _daySchedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  @override
  void didUpdateWidget(covariant ScheduleScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _loadSchedule();
    }
  }

  Future<void> _loadSchedule() async {
    setState(() {
      _isLoading = true;
    });

    final current = Anime.currentSeasonYear();
    final watchlistItems = await _animeDao.getWatchlistItems(
      season: current.season,
      seasonYear: current.year,
    );
    final schedules = buildWeeklySchedule(
      watchlistItems,
      season: current.season,
      seasonYear: current.year,
    );

    if (mounted) {
      setState(() {
        _hasWatchlistItems = watchlistItems.isNotEmpty;
        _daySchedules = schedules;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToDetail(int animeId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(animeId: animeId),
      ),
    );
    _loadSchedule();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _daySchedules.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadSchedule,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.55,
                        child: _hasWatchlistItems
                            ? const EmptyState(
                                icon: Icons.schedule_outlined,
                                title: 'No Scheduled Anime',
                                message:
                                    'None of your current season watchlist anime have a release day set yet.',
                              )
                            : const EmptyState(
                                icon: Icons.event_busy_outlined,
                                title: 'No Watchlist Anime This Season',
                                message:
                                    'Add current season anime to your watchlist from Seasons to see their weekly release schedule.',
                              ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSchedule,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _daySchedules.length,
                    itemBuilder: (context, index) {
                      final dayGroup = _daySchedules[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day Header
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dayGroup.day,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    '${dayGroup.items.length}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Anime rows for this day
                            ...dayGroup.items.map(
                              (item) => _ScheduleAnimeTile(
                                item: item,
                                onTap: () => _navigateToDetail(item.anime.id!),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _ScheduleAnimeTile extends StatelessWidget {
  final WatchlistItem item;
  final VoidCallback onTap;

  const _ScheduleAnimeTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anime = item.anime;
    final rawTime = anime.releaseTime?.trim();
    final timeDisplay =
        (rawTime != null && rawTime.isNotEmpty) ? rawTime : '--:--';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Release Time
              SizedBox(
                width: 56,
                child: Text(
                  timeDisplay,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (rawTime != null && rawTime.isNotEmpty)
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Small Poster
              ImageService.instance.buildImage(
                imagePath: anime.imagePath,
                width: 44,
                height: 60,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              // Title, Platform & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        item.watchlist.label,
                        if (anime.platform != null &&
                            anime.platform!.trim().isNotEmpty)
                          anime.platform!.trim(),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
