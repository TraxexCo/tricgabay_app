import 'package:dio/dio.dart';

import '../config/mapbox_config.dart';

/// One search result or picked point.
class PlaceHit {
  const PlaceHit({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

/// Finds places by name and turns a map point into a street address, with
/// the Mapbox Search Box and Geocoding APIs. Results lean towards Bustos.
class PlaceSearchService {
  PlaceSearchService._();

  static Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static void configureForTesting(Dio client) => _dio = client;

  static bool get available => MapboxConfig.publicToken.isNotEmpty;

  /// Places and addresses matching [query], nearest to Bustos first.
  static Future<List<PlaceHit>> search(String query) async {
    final text = query.trim();
    if (!available || text.length < 2) return const [];
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.mapbox.com/search/searchbox/v1/forward',
      queryParameters: {
        'q': text,
        'proximity': '${MapboxConfig.bustosLng},${MapboxConfig.bustosLat}',
        'country': 'ph',
        'language': 'en',
        'limit': 8,
        'access_token': MapboxConfig.publicToken,
      },
    );
    final features = response.data?['features'];
    if (features is! List) return const [];
    final hits = <PlaceHit>[];
    for (final feature in features.whereType<Map>()) {
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map || geometry is! Map) continue;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;
      final name = properties['name']?.toString().trim() ?? '';
      final address =
          (properties['full_address'] ?? properties['place_formatted'])
              ?.toString()
              .trim() ??
          '';
      if (name.isEmpty) continue;
      hits.add(
        PlaceHit(
          name: name,
          address: address,
          latitude: (coordinates[1] as num).toDouble(),
          longitude: (coordinates[0] as num).toDouble(),
        ),
      );
    }
    return hits;
  }

  /// The street address at a point, or null when none is known.
  static Future<String?> addressAt(double latitude, double longitude) async {
    if (!available) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.mapbox.com/search/geocode/v6/reverse',
        queryParameters: {
          'longitude': longitude,
          'latitude': latitude,
          'types': 'address,street,neighborhood,locality,place',
          'limit': 1,
          'language': 'en',
          'access_token': MapboxConfig.publicToken,
        },
      );
      final features = response.data?['features'];
      if (features is! List || features.isEmpty) return null;
      final properties = (features.first as Map)['properties'];
      if (properties is! Map) return null;
      final full = properties['full_address']?.toString().trim();
      if (full != null && full.isNotEmpty) return full;
      final name = properties['name']?.toString().trim() ?? '';
      final place = properties['place_formatted']?.toString().trim() ?? '';
      final joined = [name, place].where((p) => p.isNotEmpty).join(', ');
      return joined.isEmpty ? null : joined;
    } catch (_) {
      return null;
    }
  }
}
