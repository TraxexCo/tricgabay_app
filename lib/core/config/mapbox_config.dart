/// Central configuration for Mapbox Maps SDK.
/// Public token is safe to ship in source code.
class MapboxConfig {
  MapboxConfig._();

  // ── Tokens ──────────────────────────────────────────────────────────────
  static const String publicToken =
      'REDACTED';

  // ── Map Style ────────────────────────────────────────────────────────────
  /// Mapbox Streets v12 — clean, detailed, great for a tourist guide.
  static const String mapStyle = 'mapbox://styles/mapbox/streets-v12';

  // ── Bustos, Bulacan defaults ─────────────────────────────────────────────
  /// Approximate geographic center of Bustos municipality.
  static const double bustosLat = 14.9480;
  static const double bustosLng = 120.9180;

  /// Default zoom shows the whole town with enough detail to read street names.
  static const double defaultZoom = 12.8;

  /// Zoom level used when flying to a selected tourist spot.
  static const double spotZoom = 16.5;
}
