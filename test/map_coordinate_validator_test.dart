import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/utils/map_coordinate_validator.dart';

void main() {
  group('MapCoordinateValidator', () {
    test('accepts valid coordinates and inclusive global boundaries', () {
      expect(
        MapCoordinateValidator.isValid(latitude: 14.95, longitude: 120.92),
        isTrue,
      );
      expect(
        MapCoordinateValidator.isValid(latitude: -90, longitude: -180),
        isTrue,
      );
      expect(
        MapCoordinateValidator.isValid(latitude: 90, longitude: 180),
        isTrue,
      );
    });

    test('rejects missing, malformed, non-finite, and out-of-range values', () {
      for (final pair in <(Object?, Object?)>[
        (null, 120.92),
        (14.95, null),
        ('not-a-number', 120.92),
        (double.nan, 120.92),
        (14.95, double.infinity),
        (90.0001, 120.92),
        (14.95, -180.0001),
      ]) {
        expect(
          MapCoordinateValidator.isValid(latitude: pair.$1, longitude: pair.$2),
          isFalse,
        );
      }
    });

    test('parses finite numeric strings without inventing defaults', () {
      expect(MapCoordinateValidator.finiteNumber(' 14.95 '), 14.95);
      expect(MapCoordinateValidator.finiteNumber(''), isNull);
      expect(MapCoordinateValidator.finiteNumber('NaN'), isNull);
    });
  });
}
