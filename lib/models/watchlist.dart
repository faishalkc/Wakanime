import 'anime.dart';

class Watchlist {
  final int? id;
  final int animeId;
  final String status; // 'planned', 'watching', 'completed', 'dropped'
  final String createdAt;
  final String updatedAt;

  const Watchlist({
    this.id,
    required this.animeId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  static const String statusPlanned = 'planned';
  static const String statusWatching = 'watching';
  static const String statusCompleted = 'completed';
  static const String statusDropped = 'dropped';

  static const List<String> validStatuses = [
    statusPlanned,
    statusWatching,
    statusCompleted,
    statusDropped,
  ];

  static String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case statusPlanned:
        return 'Planned';
      case statusWatching:
        return 'Watching';
      case statusCompleted:
        return 'Completed';
      case statusDropped:
        return 'Dropped';
      default:
        return status;
    }
  }

  String get label => statusLabel(status);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'anime_id': animeId,
      'status': status.toLowerCase(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Watchlist.fromMap(Map<String, dynamic> map) {
    return Watchlist(
      id: map['id'] as int?,
      animeId: (map['anime_id'] as num).toInt(),
      status: (map['status'] as String? ?? statusPlanned).toLowerCase(),
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Watchlist copyWith({
    int? id,
    int? animeId,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Watchlist(
      id: id ?? this.id,
      animeId: animeId ?? this.animeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Helper model representing an Anime along with its Watchlist information
class WatchlistItem {
  final Anime anime;
  final Watchlist watchlist;

  const WatchlistItem({
    required this.anime,
    required this.watchlist,
  });
}
