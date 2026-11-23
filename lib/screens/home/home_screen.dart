import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/anime.dart';
import '../../models/watchlist.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/season_selector.dart';
import '../anime/add_anime_screen.dart';
import '../anime/anime_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToWatchlist;

  const HomeScreen({
    super.key,
    this.onNavigateToWatchlist,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _animeDao = AnimeDao();

  late String _currentSeason;
  late int _currentYear;

  List<Anime> _seasonalAnime = [];
  Map<int, Watchlist> _watchlistMap = {};
  List<WatchlistItem> _watchlistSummary = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentYear = now.year;
    _currentSeason = _getSeasonFromMonth(now.month);
    _loadData();
  }

  String _getSeasonFromMonth(int month) {
    if (month >= 1 && month <= 3) return 'winter';
    if (month >= 4 && month <= 6) return 'spring';
    if (month >= 7 && month <= 9) return 'summer';
    return 'fall';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final seasonalList = await _animeDao.getAnimeBySeason(
      _currentSeason,
      _currentYear,
    );
    final watchlistItems = await _animeDao.getWatchlistItems();

    final map = <int, Watchlist>{};
    for (final item in watchlistItems) {
      if (item.anime.id != null) {
        map[item.anime.id!] = item.watchlist;
      }
    }

    if (mounted) {
      setState(() {
        _seasonalAnime = seasonalList;
        _watchlistSummary = watchlistItems;
        _watchlistMap = map;
        _isLoading = false;
      });
    }
  }

  void _onSeasonChanged(String newSeason, int newYear) {
    setState(() {
      _currentSeason = newSeason;
      _currentYear = newYear;
    });
    _loadData();
  }

  Future<void> _navigateToAddAnime() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddAnimeScreen(
          initialSeason: _currentSeason,
          initialYear: _currentYear,
        ),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToDetail(int animeId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(animeId: animeId),
      ),
    );

    // Refresh regardless (might have been edited, deleted, or watchlist changed)
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wakanime',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Season Navigation Selector (← Season Year →)
                  SeasonSelector(
                    season: _currentSeason,
                    year: _currentYear,
                    onSeasonChanged: _onSeasonChanged,
                  ),
                  const SizedBox(height: 16),

                  // Seasonal Anime Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Seasonal Anime',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_seasonalAnime.length} Titles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Seasonal Anime List or Empty State
                  if (_seasonalAnime.isEmpty)
                    EmptyState(
                      icon: Icons.movie_filter_outlined,
                      title: 'No Anime for This Season',
                      message:
                          'There is no anime recorded for ${_currentSeason[0].toUpperCase()}${_currentSeason.substring(1)} $_currentYear yet.',
                      actionLabel: 'Add Anime',
                      onAction: _navigateToAddAnime,
                    )
                  else
                    ..._seasonalAnime.map((anime) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimeCard(
                          anime: anime,
                          watchlist: anime.id != null
                              ? _watchlistMap[anime.id!]
                              : null,
                          onTap: () => _navigateToDetail(anime.id!),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Watchlist Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Watchlist Overview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.onNavigateToWatchlist != null &&
                          _watchlistSummary.isNotEmpty)
                        TextButton(
                          onPressed: widget.onNavigateToWatchlist,
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Watchlist Section Content
                  if (_watchlistSummary.isEmpty)
                    const EmptyState(
                      icon: Icons.playlist_add_check_outlined,
                      title: 'Watchlist is Empty',
                      message:
                          'Anime you add to your watchlist will appear here.',
                    )
                  else
                    ..._watchlistSummary.take(5).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AnimeCard(
                          anime: item.anime,
                          watchlist: item.watchlist,
                          onTap: () => _navigateToDetail(item.anime.id!),
                        ),
                      );
                    }),
                  const SizedBox(height: 80), // spacing for FAB
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAnime,
        tooltip: 'Add Anime',
        child: const Icon(Icons.add),
      ),
    );
  }
}
