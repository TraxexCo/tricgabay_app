import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Local tangent-plane distance, in metres, suitable for short municipal routes.
double distanceToRouteMeters(
  double latitude,
  double longitude,
  List<Position> route,
) {
  if (route.isEmpty) return double.infinity;
  const scale = math.pi * 6371000 / 180;
  final xScale = scale * math.cos(latitude * math.pi / 180);
  double distance(Position a, Position b) {
    final ax = (a.lng.toDouble() - longitude) * xScale,
        ay = (a.lat.toDouble() - latitude) * scale;
    final bx = (b.lng.toDouble() - longitude) * xScale,
        by = (b.lat.toDouble() - latitude) * scale;
    final dx = bx - ax, dy = by - ay, length = dx * dx + dy * dy;
    final t = length == 0
        ? 0.0
        : (-(ax * dx + ay * dy) / length).clamp(0.0, 1.0);
    return math.sqrt(math.pow(ax + t * dx, 2) + math.pow(ay + t * dy, 2));
  }

  if (route.length == 1) return distance(route.first, route.first);
  var nearest = double.infinity;
  for (var i = 1; i < route.length; i++) {
    nearest = math.min(nearest, distance(route[i - 1], route[i]));
  }
  return nearest;
}

class RouteRefreshPolicy {
  String? _destinations;
  List<Position> _geometry = const [];
  String _key(List<Position> points) =>
      points.skip(1).map((p) => '${p.lng},${p.lat}').join(';');
  bool canReuse(List<Position> points) =>
      points.length >= 2 &&
      _destinations == _key(points) &&
      distanceToRouteMeters(
            points.first.lat.toDouble(),
            points.first.lng.toDouble(),
            _geometry,
          ) <=
          75;
  void remember(List<Position> points, List<Position> geometry) {
    _destinations = _key(points);
    _geometry = geometry;
  }
}
