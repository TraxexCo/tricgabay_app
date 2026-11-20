import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/realtime_refresh_policy.dart';

void main() {
  test('heartbeat-only driver events do not invalidate the directory', () {
    final previous = <String, dynamic>{
      'profile_id': 'driver',
      'is_online': true,
      'last_seen_at': 'old',
      'updated_at': 'old',
      'approval_status': 'approved',
    };
    expect(
      driverProfileNeedsRefresh(previous, {
        ...previous,
        'last_seen_at': 'new',
        'updated_at': 'new',
      }),
      isFalse,
    );
    expect(
      driverProfileNeedsRefresh(previous, {...previous, 'is_online': false}),
      isTrue,
    );
    expect(
      driverProfileNeedsRefresh(previous, {
        ...previous,
        'approval_status': 'suspended',
      }),
      isTrue,
    );
    expect(driverProfileNeedsRefresh(null, previous), isTrue);
    expect(driverProfileNeedsRefresh(previous, {}), isTrue);
  });
  final drivers = <Map<String, dynamic>>[
    {
      'id': 'assigned',
      'name': 'Driver',
      'lat': 14.9,
      'locationUpdatedAt': '2026-11-03T01:00:00Z',
    },
    {'id': 'other', 'lat': 15.0},
  ];
  test('location events preserve profile data and unrelated drivers', () {
    final result = patchDriverLocation(drivers, {
      'driver_id': 'assigned',
      'latitude': 14.95,
      'longitude': 120.92,
      'recorded_at': '2026-11-03T01:00:05Z',
    });
    expect(result.first['name'], 'Driver');
    expect(result.first['lat'], 14.95);
    expect(identical(result.last, drivers.last), isTrue);
    expect(drivers.first['lat'], 14.9);
  });
  test('delayed events cannot roll back a newer coordinate', () {
    final result = patchDriverLocation(drivers, {
      'driver_id': 'assigned',
      'latitude': 1,
      'recorded_at': '2026-11-03T00:59:59Z',
    });
    expect(identical(result.first, drivers.first), isTrue);
  });
  test('unknown drivers are never inserted from a location payload', () {
    expect(
      patchDriverLocation(drivers, {'driver_id': 'hidden', 'latitude': 1}),
      drivers,
    );
  });
  test(
    'location deletion clears coordinates without removing driver identity',
    () {
      final result = patchDriverLocation(drivers, {'driver_id': 'assigned'});
      expect(result.first['lat'], isNull);
      expect(result.first['name'], 'Driver');
    },
  );
}
