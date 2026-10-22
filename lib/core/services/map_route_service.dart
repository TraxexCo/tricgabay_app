import 'package:dio/dio.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Response;

import '../config/mapbox_config.dart';

class MapRoutePlan {
  final List<Position> geometry;
  final double distanceMeters;
  final double durationSeconds;
  final String? nextInstruction;
  final bool restrictionViolation;

  const MapRoutePlan({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.nextInstruction,
    required this.restrictionViolation,
  });

  int get etaMinutes => (durationSeconds / 60).ceil().clamp(1, 999);

  String get distanceLabel => distanceMeters < 1000
      ? '${distanceMeters.round()} m'
      : '${(distanceMeters / 1000).toStringAsFixed(1)} km';
}

class MapRouteService {
  MapRouteService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// Returns a road route that prefers local roads suitable for a tricycle.
  ///
  /// Mapbox has no tricycle profile. Motorway and toll exclusions are
  /// best-effort, so the UI must still tell drivers to follow local signs and
  /// their approved TODA/LGU route.
  static Future<MapRoutePlan> tricyclePreferred(
    List<Position> waypoints,
  ) async {
    if (waypoints.length < 2) {
      throw ArgumentError('At least two route points are required.');
    }
    final coordinates = waypoints
        .map((point) => '${point.lng},${point.lat}')
        .join(';');
    Response<Map<String, dynamic>>? response;
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        response = await _dio.get<Map<String, dynamic>>(
          'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$coordinates',
          queryParameters: {
            'access_token': MapboxConfig.publicToken,
            'geometries': 'geojson',
            'overview': 'full',
            'steps': 'true',
            'language': 'en',
            if (waypoints.length == 2) 'alternatives': 'true',
            'exclude': 'motorway,toll',
          },
        );
        break;
      } catch (error) {
        lastError = error;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 700));
        }
      }
    }
    if (response == null) throw StateError('Route unavailable: $lastError');
    final routes = response.data?['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw StateError('No local-road route was returned.');
    }

    final plans =
        routes
            .map((raw) => _parseRoute(Map<String, dynamic>.from(raw as Map)))
            .toList()
          ..sort((a, b) {
            if (a.restrictionViolation != b.restrictionViolation) {
              return a.restrictionViolation ? 1 : -1;
            }
            return a.durationSeconds.compareTo(b.durationSeconds);
          });
    return plans.first;
  }

  static MapRoutePlan _parseRoute(Map<String, dynamic> route) {
    final geometry = Map<String, dynamic>.from(route['geometry'] as Map);
    final rawCoordinates = geometry['coordinates'] as List<dynamic>;
    final legs = (route['legs'] as List<dynamic>? ?? const []);
    final notices = <dynamic>[
      ...(route['notifications'] as List<dynamic>? ?? const []),
      for (final leg in legs)
        ...(Map<String, dynamic>.from(leg as Map)['notifications']
                as List<dynamic>? ??
            const []),
    ];
    final restrictionViolation = notices.any(
      (notice) => notice.toString().toLowerCase().contains('violation'),
    );

    String? nextInstruction;
    if (legs.isNotEmpty) {
      final firstLeg = Map<String, dynamic>.from(legs.first as Map);
      final steps = firstLeg['steps'] as List<dynamic>? ?? const [];
      if (steps.isNotEmpty) {
        final firstStep = Map<String, dynamic>.from(steps.first as Map);
        final maneuver = Map<String, dynamic>.from(
          firstStep['maneuver'] as Map? ?? const {},
        );
        nextInstruction = maneuver['instruction'] as String?;
      }
    }

    return MapRoutePlan(
      geometry: rawCoordinates.map((coordinate) {
        final pair = coordinate as List<dynamic>;
        return Position(
          (pair[0] as num).toDouble(),
          (pair[1] as num).toDouble(),
        );
      }).toList(),
      distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      nextInstruction: nextInstruction,
      restrictionViolation: restrictionViolation,
    );
  }
}
