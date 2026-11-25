import 'dart:async';

import 'package:dio/dio.dart';

import '../config/mapbox_config.dart';

/// Turns a GPS fix into a town name ("Baliuag") with Mapbox
/// reverse geocoding, so labels show where the user really is.
///
/// Results are cached per ~1 km cell; failures return null and the caller
/// falls back to a distance label.
class PlaceNameService {
  PlaceNameService._();

  static final _cache = <String, String?>{};
  static final _inFlight = <String, Future<String?>>{};
  static Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  static void configureForTesting(Dio client) {
    _dio = client;
    _cache.clear();
    _inFlight.clear();
  }

  static String _cell(double lat, double lng) =>
      '${(lat * 100).round()},${(lng * 100).round()}';

  /// The cached name for this spot, if one was already looked up.
  static String? cached(double lat, double lng) => _cache[_cell(lat, lng)];

  static Future<String?> townName(double lat, double lng) {
    if (MapboxConfig.publicToken.isEmpty) return Future.value();
    final key = _cell(lat, lng);
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _inFlight[key] ??= _fetch(lat, lng)
        .then((name) {
          _cache[key] = name;
          return name;
        })
        .whenComplete(() => _inFlight.remove(key));
  }

  static Future<String?> _fetch(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': lng,
          'latitude': lat,
          'types': 'place,locality',
          'limit': 1,
          'language': 'en',
          'access_token': MapboxConfig.publicToken,
        },
      );
      final features = response.data?['features'];
      if (features is! List || features.isEmpty) return null;
      final properties = (features.first as Map)['properties'];
      if (properties is! Map) return null;
      final name = properties['name']?.toString().trim();
      if (name == null || name.isEmpty) return null;
      return name;
    } catch (_) {
      return null;
    }
  }
}
