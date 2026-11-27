import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/watchlist.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../anime/anime_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToSeasons;
  final int refreshTick;

  const HomeScreen({
    super.key,
    this.onNavigateToSeasons,
    this.refreshTick = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _animeDao = AnimeDao();

  // Selected filter: 'all', 'planned', 'watching', 'completed', 'dropped'
  String _selectedFilter = 'all';
  List<WatchlistItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshTick != oldWidget.refreshTick) {
      _loadWatchlist();
    }
  }

  Future<void> _loadWatchlist() async {
    setState(() {
      _isLoading = true;
    });

    final items = await _animeDao.getWatchlistItems(
      status: _selectedFilter == 'all' ? null : _selectedFilter,
    );

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _onFilterSelected(String filter) {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    _loadWatchlist();
  }

  Future<void> _navigateToDetail(int animeId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnimeDetailScreen(animeId: animeId),
      ),
    );
    _loadWatchlist();
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = [
      {'key': 'all', 'label': 'All'},
      {'key': Watchlist.statusPlanned, 'label': 'Planned'},
      {'key': Watchlist.statusWatching, 'label': 'Watching'},
      {'key': Watchlist.statusCompleted, 'label': 'Completed'},
      {'key': Watchlist.statusDropped, 'label': 'Dropped'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Wakanime',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Horizontal Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = _selectedFilter == opt['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(opt['label']!),
                    selected: isSelected,
                    onSelected: (_) => _onFilterSelected(opt['key']!),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadWatchlist,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: _selectedFilter == 'all'
                                  ? EmptyState(
                                      icon: Icons.playlist_add_check_outlined,
                                      title: 'No Anime in Watchlist',
                                      message:
                                          'Your watchlist is empty. Add anime from Seasons to track them here.',
                                      actionLabel:
                                          widget.onNavigateToSeasons != null
                                              ? 'Browse Seasons'
                                              : null,
                                      onAction: widget.onNavigateToSeasons,
                                    )
                                  : EmptyState(
                                      icon: Icons.filter_list_off_outlined,
                                      title: 'No Anime Found',
                                      message:
                                          'No anime with status "${Watchlist.statusLabel(_selectedFilter)}".',
                                    ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadWatchlist,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AnimeCard(
                                anime: item.anime,
                                watchlist: item.watchlist,
                                onTap: () => _navigateToDetail(item.anime.id!),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
