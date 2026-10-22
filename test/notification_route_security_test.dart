import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/push_notification_service.dart';

void main() {
  const bookingId = '123e4567-e89b-42d3-a456-426614174000';

  test('accepts only supported internal notification routes', () {
    expect(
      PushNotificationService.validateNotificationRoute(
        '/tourist/bookings/$bookingId',
      ),
      '/tourist/bookings/$bookingId',
    );
    expect(
      PushNotificationService.validateNotificationRoute(
        '/driver/trip/$bookingId',
      ),
      '/driver/trip/$bookingId',
    );
    expect(
      PushNotificationService.validateNotificationRoute('/driver/account'),
      '/driver/account',
    );
  });

  test('rejects external, malformed, and privileged notification routes', () {
    for (final route in <String?>[
      null,
      'https://example.com/tourist/bookings/$bookingId',
      '//example.com/tourist/bookings/$bookingId',
      '/tourist/bookings/not-a-uuid',
      '/tourist/bookings/$bookingId?redirect=https://example.com',
      '/admin/booking/$bookingId',
      '/tourist/../admin/dashboard',
    ]) {
      expect(
        PushNotificationService.validateNotificationRoute(route),
        isNull,
        reason: 'Unexpectedly accepted $route',
      );
    }
  });
}
