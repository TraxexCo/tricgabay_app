import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:async';
import 'error_messages.dart';
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
      ? MessageCode.distanceMeters(distanceMeters.round().toString())
      : MessageCode.distanceKilometers(
          (distanceMeters / 1000).toStringAsFixed(1),
        );
}

class MapRouteService {
  MapRouteService._();

  static final _cache = <String, ({DateTime at, MapRoutePlan plan})>{};
  static final _inFlight = <String, Future<MapRoutePlan>>{};
  static Duration _routeDeadline = const Duration(seconds: 10);
  static Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  static void configureForTesting(
    Dio client, {
    Duration deadline = const Duration(seconds: 10),
  }) {
    _dio = client;
    _routeDeadline = deadline;
    _cache.clear();
    _inFlight.clear();
  }

  /// Returns a road route that prefers local roads suitable for a tricycle.
  ///
  /// Mapbox has no tricycle profile. Motorway and toll exclusions are
  /// best-effort, so the UI must still tell drivers to follow local signs and
  /// their approved TODA/LGU route.
  static Future<MapRoutePlan> tricyclePreferred(
    List<Position> waypoints,
  ) async {
    if (waypoints.length < 2 || waypoints.length > 25) {
      throw ArgumentError(
        MessageCode.directionsRequireBetween2And25Coordinates,
      );
    }
    final coordinates = waypoints
        .map((point) => '${point.lng},${point.lat}')
        .join(';');
    final cached = _cache[coordinates];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 5)) {
      return cached.plan;
    }
    final existing = _inFlight[coordinates];
    if (existing != null) return existing;
    final request = _fetchRoute(
      coordinates,
      alternatives: waypoints.length == 2,
    );
    _inFlight[coordinates] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[coordinates], request)) {
        _inFlight.remove(coordinates);
      }
    }
  }

  static Future<MapRoutePlan> _fetchRoute(
    String coordinates, {
    required bool alternatives,
  }) async {
    final budget = Stopwatch()..start();
    final deadline = _routeDeadline;
    Response<Map<String, dynamic>>? response;
    for (var attempt = 0; attempt < 2; attempt++) {
      final remaining = deadline - budget.elapsed;
      if (remaining <= Duration.zero) break;
      final token = CancelToken();
      try {
        response = await _dio
            .get<Map<String, dynamic>>(
              'https://api.mapbox.com/directions/v5/mapbox/driving-traffic/$coordinates',
              queryParameters: {
                'access_token': MapboxConfig.publicToken,
                'geometries': 'geojson',
                'overview': 'full',
                'steps': 'true',
                'language': 'en',
                if (alternatives) 'alternatives': 'true',
                'exclude': 'motorway,toll',
              },
              cancelToken: token,
            )
            .timeout(
              remaining,
              onTimeout: () {
                token.cancel();
                throw TimeoutException(null, deadline);
              },
            );
        break;
      } catch (error) {
        ErrorMessages.forError(error);
        final status = error is DioException
            ? error.response?.statusCode
            : null;
        if (status != null && status < 500) break;
        const backoff = Duration(milliseconds: 350);
        if (attempt != 0 || budget.elapsed + backoff >= deadline) break;
        await Future<void>.delayed(backoff);
      }
    }
    if (response == null) {
      throw const ClientOperationException(ClientFailure.routeUnavailable);
    }
    final routes = response.data?['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) {
      throw StateError(MessageCode.noLocalRoadRouteWasReturned);
    }

    final candidates = routes.map((raw) => _parseRoute(raw as Map)).iterator;
    candidates.moveNext();
    var best = candidates.current;
    while (candidates.moveNext()) {
      final candidate = candidates.current;
      final preferred =
          candidate.restrictionViolation != best.restrictionViolation
          ? !candidate.restrictionViolation
          : candidate.durationSeconds.compareTo(best.durationSeconds) < 0;
      if (preferred) best = candidate;
    }
    _cache.remove(coordinates);
    if (_cache.length >= 32) _cache.remove(_cache.keys.first);
    _cache[coordinates] = (at: DateTime.now(), plan: best);
    return best;
  }

  static MapRoutePlan _parseRoute(Map<dynamic, dynamic> route) {
    final geometry = route['geometry'] as Map;
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
