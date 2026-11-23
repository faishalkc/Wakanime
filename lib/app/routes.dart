import 'package:flutter/material.dart';
import '../models/anime.dart';
import '../screens/anime/add_anime_screen.dart';
import '../screens/anime/anime_detail_screen.dart';
import '../screens/anime/edit_anime_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String addAnime = '/add-anime';
  static const String animeDetail = '/anime-detail';
  static const String editAnime = '/edit-anime';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case addAnime:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddAnimeScreen(
            initialSeason: args?['season'] as String?,
            initialYear: args?['year'] as int?,
          ),
          settings: settings,
        );

      case animeDetail:
        final animeId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => AnimeDetailScreen(animeId: animeId),
          settings: settings,
        );

      case editAnime:
        final anime = settings.arguments as Anime;
        return MaterialPageRoute(
          builder: (_) => EditAnimeScreen(anime: anime),
          settings: settings,
        );

      default:
        return null;
    }
  }
}
