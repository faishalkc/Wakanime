class Anime {
  final int? id;
  final String title;
  final String? imagePath;
  final String season; // 'winter', 'spring', 'summer', 'fall'
  final int seasonYear;
  final String? releaseDay;
  final String? releaseTime;
  final String? platform;
  final String createdAt;
  final String updatedAt;

  const Anime({
    this.id,
    required this.title,
    this.imagePath,
    required this.season,
    required this.seasonYear,
    this.releaseDay,
    this.releaseTime,
    this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  static const List<String> validSeasons = [
    'winter',
    'spring',
    'summer',
    'fall',
  ];

  static const List<String> validDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get seasonNameCapitalized {
    if (season.isEmpty) return '';
    return season[0].toUpperCase() + season.substring(1).toLowerCase();
  }

  String get seasonDisplay => '$seasonNameCapitalized $seasonYear';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'image_path': imagePath,
      'season': season.toLowerCase(),
      'season_year': seasonYear,
      'release_day': releaseDay,
      'release_time': releaseTime,
      'platform': platform,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Anime.fromMap(Map<String, dynamic> map) {
    return Anime(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      imagePath: map['image_path'] as String?,
      season: (map['season'] as String? ?? 'winter').toLowerCase(),
      seasonYear: (map['season_year'] as num?)?.toInt() ?? DateTime.now().year,
      releaseDay: map['release_day'] as String?,
      releaseTime: map['release_time'] as String?,
      platform: map['platform'] as String?,
      createdAt: map['created_at'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Anime copyWith({
    int? id,
    String? title,
    String? imagePath,
    bool clearImagePath = false,
    String? season,
    int? seasonYear,
    String? releaseDay,
    String? releaseTime,
    String? platform,
    String? createdAt,
    String? updatedAt,
  }) {
    return Anime(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      season: season ?? this.season,
      seasonYear: seasonYear ?? this.seasonYear,
      releaseDay: releaseDay ?? this.releaseDay,
      releaseTime: releaseTime ?? this.releaseTime,
      platform: platform ?? this.platform,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
