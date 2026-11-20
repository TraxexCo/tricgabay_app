import 'package:geolocator/geolocator.dart' as geo;

/// Small platform boundary that keeps permission and location behavior
/// deterministic in unit tests while the production adapter still delegates
/// directly to Geolocator.
abstract interface class LocationGateway {
  Future<bool> isServiceEnabled();

  Future<geo.LocationPermission> checkPermission();

  Future<geo.LocationPermission> requestPermission();

  Future<geo.Position> currentPosition({
    required geo.LocationSettings settings,
  });

  Stream<geo.Position> positionStream({required geo.LocationSettings settings});
}

class GeolocatorLocationGateway implements LocationGateway {
  const GeolocatorLocationGateway();

  @override
  Future<bool> isServiceEnabled() => geo.Geolocator.isLocationServiceEnabled();

  @override
  Future<geo.LocationPermission> checkPermission() =>
      geo.Geolocator.checkPermission();

  @override
  Future<geo.LocationPermission> requestPermission() =>
      geo.Geolocator.requestPermission();

  @override
  Future<geo.Position> currentPosition({
    required geo.LocationSettings settings,
  }) => geo.Geolocator.getCurrentPosition(locationSettings: settings);

  @override
  Stream<geo.Position> positionStream({
    required geo.LocationSettings settings,
  }) => geo.Geolocator.getPositionStream(locationSettings: settings);
}

bool isUsableLocationSample(
  geo.Position position, {
  DateTime? newerThan,
  DateTime? now,
}) {
  final observedAt = now ?? DateTime.now();
  return position.latitude.isFinite &&
      position.longitude.isFinite &&
      position.latitude >= -90 &&
      position.latitude <= 90 &&
      position.longitude >= -180 &&
      position.longitude <= 180 &&
      position.accuracy.isFinite &&
      position.accuracy >= 0 &&
      position.accuracy <= 200 &&
      !position.timestamp.isBefore(
        observedAt.subtract(const Duration(minutes: 2)),
      ) &&
      !position.timestamp.isAfter(
        observedAt.add(const Duration(seconds: 30)),
      ) &&
      (newerThan == null || position.timestamp.isAfter(newerThan));
}
