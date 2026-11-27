import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/anime.dart';
import '../../models/watchlist.dart';
import '../../services/season_import_service.dart';
import '../../services/tenrai_provider.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/anime_search_field.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/season_selector.dart';
import '../anime/add_anime_screen.dart';
import '../anime/anime_detail_screen.dart';

class SeasonsScreen extends StatefulWidget {
  final int refreshTick;

  const SeasonsScreen({
    super.key,
    this.refreshTick = 0,
  });

  @override
  State<SeasonsScreen> createState() => _SeasonsScreenState();
}

class _SeasonsScreenState extends State<SeasonsScreen> {
  final _animeDao = AnimeDao();
  final _importService = SeasonImportService();
  final _searchController = TextEditingController();

  late String _currentSeason;
  late int _currentYear;

  String _searchQuery = '';
  List<Anime> _seasonalAnime = [];
  Map<int, Watchlist> _watchlistMap = {};
  bool _isLoading = true;
  bool _isImporting = false;
  String _importStatus = '';

  @override
  void initState() {
    super.initState();
    final current = Anime.currentSeasonYear();
    _currentYear = current.year;
    _currentSeason = current.season;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SeasonsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _loadData();
    }
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
        _watchlistMap = map;
        _isLoading = false;
      });
    }
  }

  void _onSeasonChanged(String newSeason, int newYear) {
    if (_isImporting) return;
    setState(() {
      _currentSeason = newSeason;
      _currentYear = newYear;
    });
    _loadData();
  }

  String _formatSeasonLabel(String season, int year) {
    final cap = season[0].toUpperCase() + season.substring(1).toLowerCase();
    return '$cap $year';
  }

  Future<void> _importFromApi() async {
    if (_isImporting) return;

    final targetSeason = _currentSeason;
    final targetYear = _currentYear;
    final seasonLabel = _formatSeasonLabel(targetSeason, targetYear);

    setState(() {
      _isImporting = true;
      _importStatus = 'Importing $seasonLabel...';
    });

    try {
      final result = await _importService.importSeason(
        season: targetSeason,
        year: targetYear,
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _importStatus = status;
            });
          }
        },
      );

      if (!mounted) return;
      await _loadData();
      if (!mounted) return;

      final String message;
      if (result.totalProcessed == 0) {
        message = 'No anime found for $seasonLabel.';
      } else if (result.failedImageCount > 0) {
        message =
            'Imported ${result.totalProcessed} anime (${result.insertedCount} new, ${result.updatedCount} updated), but ${result.failedImageCount} image(s) are unavailable.';
      } else {
        message =
            'Imported ${result.totalProcessed} anime for $seasonLabel (${result.insertedCount} new, ${result.updatedCount} updated).';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on ImportException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import failed. Existing data was not changed.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
          _importStatus = '';
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
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

    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedQuery = _searchQuery.trim().toLowerCase();
    final filteredAnime = trimmedQuery.isEmpty
        ? _seasonalAnime
        : _seasonalAnime
            .where((anime) => anime.title.toLowerCase().contains(trimmedQuery))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Seasons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Season Navigation Selector (← Season Year →)
                Opacity(
                  opacity: _isImporting ? 0.6 : 1.0,
                  child: AbsorbPointer(
                    absorbing: _isImporting,
                    child: SeasonSelector(
                      season: _currentSeason,
                      year: _currentYear,
                      onSeasonChanged: _onSeasonChanged,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Action Buttons: Add Anime & Import from API
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _isImporting ? null : _navigateToAddAnime,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Anime'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isImporting ? null : _importFromApi,
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(
                          _isImporting ? 'Importing...' : 'Import from API',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isImporting) ...[
                  const SizedBox(height: 10),
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Importing ${_formatSeasonLabel(_currentSeason, _currentYear)}...',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_importStatus.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _importStatus,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                // Search Field
                AnimeSearchField(
                  controller: _searchController,
                  query: _searchQuery,
                  hintText: 'Search seasonal anime...',
                  onChanged: _onSearchChanged,
                  onClear: _clearSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      children: [
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
                              '${filteredAnime.length} Titles',
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
                        else if (filteredAnime.isEmpty)
                          EmptyState(
                            icon: Icons.search_off_outlined,
                            title: 'No Anime Found',
                            message:
                                'No anime in this season matches "${_searchQuery.trim()}".',
                            actionLabel: 'Clear Search',
                            onAction: _clearSearch,
                          )
                        else
                          ...filteredAnime.map((anime) {
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

                        const SizedBox(height: 80), // spacing for FAB
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isImporting ? null : _navigateToAddAnime,
        tooltip: 'Add Anime',
        child: const Icon(Icons.add),
      ),
    );
  }
}
