import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/anime.dart';
import '../models/anime_import_data.dart';

class ImportException implements Exception {
  final String message;

  const ImportException(this.message);

  @override
  String toString() => message;
}

class HttpResponseData {
  final int statusCode;
  final String body;
  final String? retryAfterHeader;

  const HttpResponseData({
    required this.statusCode,
    required this.body,
    this.retryAfterHeader,
  });
}

typedef HttpGetFn = Future<HttpResponseData> Function(Uri uri);

abstract class SeasonAnimeProvider {
  String get sourceName;

  Future<List<AnimeImportData>> fetchSeason({
    required String season,
    required int year,
    void Function(String status)? onProgress,
  });
}

class TenraiProvider implements SeasonAnimeProvider {
  static const String _baseUrl = 'https://api.tenrai.org/v1/seasons';
  static const int _maxRetriesPerPage = 3;
  static const int _maxPagesSafetyLimit = 100;

  final HttpGetFn _httpGet;
  final Future<void> Function(Duration duration) _delay;

  TenraiProvider({
    HttpGetFn? httpGet,
    Future<void> Function(Duration duration)? delay,
  })  : _httpGet = httpGet ?? _defaultHttpGet,
        _delay = delay ?? Future<void>.delayed;

  @override
  String get sourceName => 'tenrai';

  static Future<HttpResponseData> _defaultHttpGet(Uri uri) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(uri).timeout(
        const Duration(seconds: 15),
      );
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'Wakanime/1.0');

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join().timeout(
        const Duration(seconds: 20),
      );

      return HttpResponseData(
        statusCode: response.statusCode,
        body: body,
        retryAfterHeader: response.headers.value(HttpHeaders.retryAfterHeader),
      );
    } on SocketException {
      throw const ImportException(
        'No internet connection. Existing data was not changed.',
      );
    } on TimeoutException {
      throw const ImportException(
        'Connection timed out while fetching anime data. Existing data was not changed.',
      );
    } on HttpException {
      throw const ImportException(
        'Network error while contacting Tenrai API. Existing data was not changed.',
      );
    } on HandshakeException {
      throw const ImportException(
        'Secure connection to Tenrai API failed. Existing data was not changed.',
      );
    } finally {
      client.close();
    }
  }

  @override
  Future<List<AnimeImportData>> fetchSeason({
    required String season,
    required int year,
    void Function(String status)? onProgress,
  }) async {
    final normalizedSeason = season.trim().toLowerCase();
    if (!Anime.validSeasons.contains(normalizedSeason)) {
      throw ImportException('Invalid season "$season".');
    }

    final results = <AnimeImportData>[];
    int currentPage = 1;
    bool hasNextPage = true;

    while (hasNextPage && currentPage <= _maxPagesSafetyLimit) {
      onProgress?.call('Fetching page $currentPage...');

      final uri = Uri.parse('$_baseUrl/$year/$normalizedSeason').replace(
        queryParameters: {
          'type': 'tv',
          'filter': 'tv',
          'page': currentPage.toString(),
        },
      );

      final response = await _fetchPageWithRetry(uri);

      final Map<String, dynamic> jsonMap;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Root JSON is not an object');
        }
        jsonMap = decoded;
      } on FormatException {
        throw const ImportException(
          'Received an unexpected response from Tenrai API. Existing data was not changed.',
        );
      }

      final rawData = jsonMap['data'];
      if (rawData is! List) {
        throw const ImportException(
          'Malformed season data from Tenrai API. Existing data was not changed.',
        );
      }

      final pagination = jsonMap['pagination'];
      int? lastVisiblePage;
      int? reportedPage;
      if (pagination is Map<String, dynamic>) {
        hasNextPage = pagination['has_next_page'] == true;
        lastVisiblePage = (pagination['last_visible_page'] as num?)?.toInt();
        reportedPage = (pagination['current_page'] as num?)?.toInt();
      } else {
        hasNextPage = false;
      }

      final displayPage = reportedPage ?? currentPage;
      if (lastVisiblePage != null && lastVisiblePage > 0) {
        onProgress?.call('Fetching page $displayPage of $lastVisiblePage...');
      }

      for (final entry in rawData) {
        if (entry is! Map<String, dynamic>) continue;
        final mapped = _mapItem(
          entry,
          fallbackSeason: normalizedSeason,
          fallbackYear: year,
        );
        if (mapped != null) {
          results.add(mapped);
        }
      }

      if (lastVisiblePage != null && displayPage >= lastVisiblePage) {
        hasNextPage = false;
      }

      if (hasNextPage) {
        currentPage = displayPage + 1;
        // Polite delay between sequential page requests
        await _delay(const Duration(milliseconds: 300));
      }
    }

    return results;
  }

  Future<HttpResponseData> _fetchPageWithRetry(Uri uri) async {
    int attempt = 0;

    while (true) {
      final response = await _httpGet(uri);

      if (response.statusCode == 200) {
        return response;
      }

      if (response.statusCode == 429) {
        attempt++;
        if (attempt > _maxRetriesPerPage) {
          throw const ImportException(
            'Rate limit reached on Tenrai API. Please try again shortly. Existing data was not changed.',
          );
        }

        final retrySeconds = _parseRetryAfterSeconds(response.retryAfterHeader);
        await _delay(Duration(seconds: retrySeconds));
        continue;
      }

      if (response.statusCode >= 500 && attempt < 1) {
        attempt++;
        await _delay(const Duration(seconds: 2));
        continue;
      }

      throw ImportException(
        'Import failed (HTTP ${response.statusCode}). Existing data was not changed.',
      );
    }
  }

  int _parseRetryAfterSeconds(String? headerValue) {
    if (headerValue == null || headerValue.trim().isEmpty) return 2;
    final parsed = int.tryParse(headerValue.trim());
    if (parsed == null || parsed <= 0) return 2;
    return parsed > 30 ? 30 : parsed;
  }

  AnimeImportData? _mapItem(
    Map<String, dynamic> item, {
    required String fallbackSeason,
    required int fallbackYear,
  }) {
    final rawType = item['type'];
    if (rawType is String &&
        rawType.trim().isNotEmpty &&
        rawType.trim().toLowerCase() != 'tv') {
      return null;
    }

    final rawId = item['mal_id'];
    if (rawId == null) return null;
    final externalId = rawId.toString().trim();
    if (externalId.isEmpty) return null;

    final rawTitle = item['title'];
    if (rawTitle is! String || rawTitle.trim().isEmpty) return null;
    final title = rawTitle.trim();

    String? imageUrl;
    final images = item['images'];
    if (images is Map<String, dynamic>) {
      final jpg = images['jpg'];
      if (jpg is Map<String, dynamic>) {
        final rawUrl = jpg['image_url'];
        if (rawUrl is String && rawUrl.trim().isNotEmpty) {
          imageUrl = rawUrl.trim();
        }
      }
    }

    final rawSeason = (item['season'] as String?)?.trim().toLowerCase();
    final season = (rawSeason != null && Anime.validSeasons.contains(rawSeason))
        ? rawSeason
        : fallbackSeason;

    final rawYear = (item['year'] as num?)?.toInt();
    final seasonYear =
        (rawYear != null && rawYear >= 1900 && rawYear <= 2100)
            ? rawYear
            : fallbackYear;

    String? releaseDay;
    String? releaseTime;
    final broadcast = item['broadcast'];
    if (broadcast is Map<String, dynamic>) {
      releaseDay = normalizeBroadcastDay(broadcast['day'] as String?);
      releaseTime = _normalizeBroadcastTime(broadcast['time'] as String?);
    }

    return AnimeImportData(
      source: sourceName,
      externalId: externalId,
      title: title,
      imageUrl: imageUrl,
      season: season,
      seasonYear: seasonYear,
      releaseDay: releaseDay,
      releaseTime: releaseTime,
      platform: null, // Platform must remain empty from API import
    );
  }

  /// Normalizes API day names (e.g. "Mondays") to Wakanime's canonical format ("Monday").
  static String? normalizeBroadcastDay(String? rawDay) {
    if (rawDay == null) return null;
    final cleaned = rawDay.trim().toLowerCase();
    if (cleaned.isEmpty || cleaned == 'unknown') return null;

    const dayMap = <String, String>{
      'monday': 'Monday',
      'mondays': 'Monday',
      'tuesday': 'Tuesday',
      'tuesdays': 'Tuesday',
      'wednesday': 'Wednesday',
      'wednesdays': 'Wednesday',
      'thursday': 'Thursday',
      'thursdays': 'Thursday',
      'friday': 'Friday',
      'fridays': 'Friday',
      'saturday': 'Saturday',
      'saturdays': 'Saturday',
      'sunday': 'Sunday',
      'sundays': 'Sunday',
    };

    return dayMap[cleaned];
  }

  static String? _normalizeBroadcastTime(String? rawTime) {
    if (rawTime == null) return null;
    final cleaned = rawTime.trim();
    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}
