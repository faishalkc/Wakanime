import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';

class SettingsScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const SettingsScreen({
    super.key,
    required this.themeModeNotifier,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _animeDao = AnimeDao();

  int _animeCount = 0;
  int _watchlistCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    final totalAnime = await _animeDao.countAnime();
    final totalWatchlist = await _animeDao.countWatchlist();

    if (mounted) {
      setState(() {
        _animeCount = totalAnime;
        _watchlistCount = totalWatchlist;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTheme(ThemeMode mode) async {
    widget.themeModeNotifier.value = mode;

    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }

    await _animeDao.setSetting('theme_mode', modeString);
  }

  Future<void> _confirmClearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all anime and watchlist records? '
          'This will also permanently delete all saved poster images. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _animeDao.clearAllData();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data has been cleared')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentThemeMode = widget.themeModeNotifier.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Appearance Section
                Text(
                  'Appearance',
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
                  child: RadioGroup<ThemeMode>(
                    groupValue: currentThemeMode,
                    onChanged: (val) {
                      if (val != null) _updateTheme(val);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text('System Default'),
                          subtitle: Text('Follow system dark/light mode'),
                          secondary: Icon(Icons.brightness_auto_outlined),
                          value: ThemeMode.system,
                        ),
                        Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: Text('Light Theme'),
                          secondary: Icon(Icons.light_mode_outlined),
                          value: ThemeMode.light,
                        ),
                        Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          title: Text('Dark Theme'),
                          secondary: Icon(Icons.dark_mode_outlined),
                          value: ThemeMode.dark,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Database Statistics
                Text(
                  'Database Statistics',
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
                      ListTile(
                        leading: Icon(Icons.movie_outlined, color: theme.colorScheme.primary),
                        title: const Text('Total Anime Stored'),
                        trailing: Text(
                          '$_animeCount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(Icons.playlist_add_check, color: theme.colorScheme.primary),
                        title: const Text('Watchlist Entries'),
                        trailing: Text(
                          '$_watchlistCount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data Management
                Text(
                  'Data Management',
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
                  child: ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text(
                      'Clear All Data',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Delete all anime records and images'),
                    onTap: _confirmClearData,
                  ),
                ),
                const SizedBox(height: 24),

                // About Wakanime
                Text(
                  'About',
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
                      ListTile(
                        leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        title: const Text('Wakanime'),
                        subtitle: const Text('Offline Anime Watchlist Manager'),
                        trailing: const Text(
                          'v1.0.0',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
