import 'dart:math' as math;

/// Shared by foreground and active-trip streams. Failed writes remain retryable.
class LocationUploadGate {
  String? _owner;
  int _generation = 0;
  bool _busy = false;
  DateTime? _lastAt;
  double? _latitude;
  double? _longitude;

  void reset() {
    _generation++;
    _owner = null;
    _busy = false;
    _lastAt = null;
    _latitude = null;
    _longitude = null;
  }

  Future<bool> publish({
    required String owner,
    required double latitude,
    required double longitude,
    required DateTime now,
    required Future<void> Function() write,
  }) async {
    if (_owner != owner) {
      reset();
      _owner = owner;
    }
    if (_busy) return false;
    final previous = _lastAt;
    if (previous != null) {
      final elapsed = now.difference(previous);
      if (elapsed < const Duration(seconds: 5)) return false;
      if (elapsed < const Duration(seconds: 30) &&
          _distance(_latitude!, _longitude!, latitude, longitude) < 15) {
        return false;
      }
    }
    final generation = _generation;
    _busy = true;
    try {
      await write();
      if (generation == _generation) {
        _lastAt = now;
        _latitude = latitude;
        _longitude = longitude;
      }
      return true;
    } finally {
      if (generation == _generation) _busy = false;
    }
  }

  static double _distance(double lat1, double lng1, double lat2, double lng2) {
    const radians = math.pi / 180;
    final dLat = (lat2 - lat1) * radians;
    final dLng = (lng2 - lng1) * radians;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1 * radians) *
            math.cos(lat2 * radians) *
            math.pow(math.sin(dLng / 2), 2);
    return 6371000 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}
