import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/home/home_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import 'routes.dart';

class WakanimeApp extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const WakanimeApp({
    super.key,
    required this.themeModeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        const seedColor = Color(0xFF5C6BC0); // Indigo tone

        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.light,
        );

        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        );

        final lightTheme = ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: lightColorScheme.surfaceContainer,
              systemNavigationBarIconBrightness: Brightness.dark,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: lightColorScheme.surfaceContainer,
            elevation: 0,
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: darkColorScheme.surfaceContainer,
              systemNavigationBarIconBrightness: Brightness.light,
              systemNavigationBarDividerColor: Colors.transparent,
            ),
          ),
          navigationBarTheme: NavigationBarThemeData(
            backgroundColor: darkColorScheme.surfaceContainer,
            elevation: 0,
          ),
        );

        return MaterialApp(
          title: 'Wakanime',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: lightTheme,
          darkTheme: darkTheme,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            final platformBrightness = MediaQuery.platformBrightnessOf(context);
            final isDark = themeMode == ThemeMode.dark ||
                (themeMode == ThemeMode.system &&
                    platformBrightness == Brightness.dark);
            final currentTheme = isDark ? darkTheme : lightTheme;
            final navBarColor = currentTheme.colorScheme.surfaceContainer;

            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: navBarColor,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarDividerColor: Colors.transparent,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: MainNavigationShell(themeModeNotifier: themeModeNotifier),
        );
      },
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const MainNavigationShell({
    super.key,
    required this.themeModeNotifier,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToWatchlist: () => _onTabTapped(1),
      ),
      const WatchlistScreen(),
      SettingsScreen(themeModeNotifier: widget.themeModeNotifier),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_play_outlined),
            selectedIcon: Icon(Icons.playlist_play),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
