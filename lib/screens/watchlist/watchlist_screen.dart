import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/watchlist.dart';
import '../../widgets/anime_card.dart';
import '../../widgets/empty_state.dart';
import '../anime/anime_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final _animeDao = AnimeDao();

  // Selected filter: null / 'all', 'planned', 'watching', 'completed', 'dropped'
  String _selectedFilter = 'all';
  List<WatchlistItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchlist();
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
          'Watchlist',
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
                              child: EmptyState(
                                icon: Icons.filter_list_off_outlined,
                                title: 'No Anime Found',
                                message: _selectedFilter == 'all'
                                    ? 'Your watchlist is empty. Add anime from Home to track them here.'
                                    : 'No anime with status "${_selectedFilter[0].toUpperCase()}${_selectedFilter.substring(1)}".',
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
