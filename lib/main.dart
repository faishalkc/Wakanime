import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'database/anime_dao.dart';
import 'database/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay defaults
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Initialize SQLite database
  await AppDatabase.instance.database;

  // Retrieve saved theme preference
  final animeDao = AnimeDao();
  final savedTheme = await animeDao.getSetting('theme_mode');

  ThemeMode initialThemeMode = ThemeMode.system;
  if (savedTheme == 'light') {
    initialThemeMode = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    initialThemeMode = ThemeMode.dark;
  }

  final themeModeNotifier = ValueNotifier<ThemeMode>(initialThemeMode);

  runApp(WakanimeApp(themeModeNotifier: themeModeNotifier));
}
