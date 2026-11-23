import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/anime.dart';
import '../../models/watchlist.dart';
import '../../services/image_service.dart';
import 'edit_anime_screen.dart';

class AnimeDetailScreen extends StatefulWidget {
  final int animeId;

  const AnimeDetailScreen({
    super.key,
    required this.animeId,
  });

  @override
  State<AnimeDetailScreen> createState() => _AnimeDetailScreenState();
}

class _AnimeDetailScreenState extends State<AnimeDetailScreen> {
  final _animeDao = AnimeDao();
  Anime? _anime;
  Watchlist? _watchlist;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final anime = await _animeDao.getAnimeById(widget.animeId);
    final watchlist = await _animeDao.getWatchlistByAnimeId(widget.animeId);

    if (mounted) {
      setState(() {
        _anime = anime;
        _watchlist = watchlist;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case Watchlist.statusPlanned:
        return Colors.blue;
      case Watchlist.statusWatching:
        return Colors.orange;
      case Watchlist.statusCompleted:
        return Colors.green;
      case Watchlist.statusDropped:
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }

  Future<void> _changeWatchlistStatus(String newStatus) async {
    await _animeDao.setWatchlistStatus(widget.animeId, newStatus);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Watchlist status updated to ${Watchlist.statusLabel(newStatus)}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _removeFromWatchlist() async {
    await _animeDao.removeFromWatchlist(widget.animeId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from Watchlist'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWatchlistBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _watchlist == null ? 'Add to Watchlist' : 'Change Watchlist Status',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ...Watchlist.validStatuses.map((status) {
                  final isSelected = _watchlist?.status == status;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? Theme.of(ctx).colorScheme.primary
                          : null,
                    ),
                    title: Text(Watchlist.statusLabel(status)),
                    trailing: isSelected
                        ? const Chip(label: Text('Current'))
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _changeWatchlistStatus(status);
                    },
                  );
                }),
                if (_watchlist != null) ...[
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.playlist_remove, color: Colors.red),
                    title: const Text(
                      'Remove from Watchlist',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removeFromWatchlist();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Anime'),
        content: Text(
          'Are you sure you want to delete "${_anime?.title}"? '
          'This will also remove it from your watchlist and delete its image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _animeDao.deleteAnime(widget.animeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anime deleted')),
        );
        Navigator.pop(context, true); // true indicates anime was deleted
      }
    }
  }

  Future<void> _editAnime() async {
    if (_anime == null) return;
    final result = await Navigator.push<Anime>(
      context,
      MaterialPageRoute(
        builder: (_) => EditAnimeScreen(anime: _anime!),
      ),
    );
    if (result != null) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_anime == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Anime not found')),
      );
    }

    final anime = _anime!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Anime',
            onPressed: _editAnime,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Anime',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Poster Image
          Center(
            child: Container(
              width: 180,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ImageService.instance.buildImage(
                imagePath: anime.imagePath,
                width: 180,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            anime.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Watchlist Status Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Watchlist Status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_watchlist != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(
                              _watchlist!.status,
                              theme.colorScheme,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getStatusColor(
                                _watchlist!.status,
                                theme.colorScheme,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            _watchlist!.label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: _getStatusColor(
                                _watchlist!.status,
                                theme.colorScheme,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Text(
                          'Not in Watchlist',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _showWatchlistBottomSheet,
                      icon: Icon(
                        _watchlist == null
                            ? Icons.playlist_add
                            : Icons.edit_note,
                      ),
                      label: Text(
                        _watchlist == null
                            ? 'Add to Watchlist'
                            : 'Update Watchlist Status',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Details List
          Text(
            'Information',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.calendar_month,
                  label: 'Season',
                  value: anime.seasonDisplay,
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  context,
                  icon: Icons.date_range,
                  label: 'Release Day',
                  value: anime.releaseDay ?? 'Not specified',
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  context,
                  icon: Icons.access_time,
                  label: 'Release Time',
                  value: anime.releaseTime ?? 'Not specified',
                ),
                const Divider(height: 1, indent: 56),
                _buildInfoTile(
                  context,
                  icon: Icons.tv,
                  label: 'Platform',
                  value: anime.platform ?? 'Not specified',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
