import 'dart:math' as math;

class PickupServiceArea {
  final double latitude, longitude, radiusKm;
  const PickupServiceArea(this.latitude, this.longitude, this.radiusKm);
  bool contains(double lat, double lng) {
    if (!lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180 ||
        radiusKm <= 0) {
      return false;
    }
    const radians = math.pi / 180;
    final a =
        math.pow(math.sin((lat - latitude) * radians / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(lat * radians) *
            math.pow(math.sin((lng - longitude) * radians / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1))) <= radiusKm * 1000;
  }
}
