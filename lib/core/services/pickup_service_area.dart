import 'dart:math' as math;

class PickupServiceArea {
  final double latitude, longitude, radiusKm;
  const PickupServiceArea(this.latitude, this.longitude, this.radiusKm);

  /// Great-circle distance from the area's centre, or null for an invalid
  /// coordinate.
  double? distanceKmTo(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite || lat.abs() > 90 || lng.abs() > 180) {
      return null;
    }
    const radians = math.pi / 180;
    final a =
        math.pow(math.sin((lat - latitude) * radians / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(lat * radians) *
            math.pow(math.sin((lng - longitude) * radians / 2), 2);
    return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }

  bool contains(double lat, double lng) {
    if (radiusKm <= 0) return false;
    final distance = distanceKmTo(lat, lng);
    return distance != null && distance * 1000 <= radiusKm * 1000;
  }
}
