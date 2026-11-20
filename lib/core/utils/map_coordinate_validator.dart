class MapCoordinateValidator {
  MapCoordinateValidator._();

  static double? finiteNumber(Object? value) {
    final number = switch (value) {
      num value => value.toDouble(),
      String value => double.tryParse(value.trim()),
      _ => null,
    };
    return number != null && number.isFinite ? number : null;
  }

  static bool isValid({required Object? latitude, required Object? longitude}) {
    final lat = finiteNumber(latitude);
    final lng = finiteNumber(longitude);
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }
}
