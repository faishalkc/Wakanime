class AnimeImportData {
  final String source;
  final String externalId;
  final String title;
  final String? imageUrl;
  final String season;
  final int seasonYear;
  final String? releaseDay;
  final String? releaseTime;
  final String? platform;

  const AnimeImportData({
    required this.source,
    required this.externalId,
    required this.title,
    this.imageUrl,
    required this.season,
    required this.seasonYear,
    this.releaseDay,
    this.releaseTime,
    this.platform,
  });
}
