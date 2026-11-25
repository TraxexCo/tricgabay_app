import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/models/booking_model.dart';

void main() {
  test('centavo amounts are read as integers', () {
    expect(
      readCents(
        {'totalFareCents': 25050},
        'totalFareCents',
        legacyPesosKey: 'totalFare',
      ),
      25050,
    );
  });

  test('legacy peso snapshots convert without float drift', () {
    // 0.1 + 0.2 style values must still land on the exact centavo.
    expect(
      readCents(
        {'totalFare': 250.5},
        'totalFareCents',
        legacyPesosKey: 'totalFare',
      ),
      25050,
    );
    expect(
      readCents(
        {'totalFare': 0.3},
        'totalFareCents',
        legacyPesosKey: 'totalFare',
      ),
      30,
    );
    expect(
      readCents(
        {'totalFare': 12345.67},
        'totalFareCents',
        legacyPesosKey: 'totalFare',
      ),
      1234567,
    );
  });

  test('missing amounts default to zero', () {
    expect(readCents({}, 'totalFareCents', legacyPesosKey: 'totalFare'), 0);
  });

  test('a stop round-trips its fare in centavos', () {
    final stop = BookingStop(
      spotId: 's1',
      spotName: 'Bustos Dam Eco Park',
      latitude: 14.95,
      longitude: 120.92,
      fareCents: 4550,
    );
    final map = stop.toMap();
    expect(map['fareCents'], 4550);
    expect(map.containsKey('fare'), isFalse);
    expect(BookingStop.fromMap(map).fareCents, 4550);
    expect(
      BookingStop.fromMap({
        ...map..remove('fareCents'),
        'fare': 45.5,
      }).fareCents,
      4550,
    );
  });
}
