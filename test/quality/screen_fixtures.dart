import 'package:tricgabay_app/core/session/app_session.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import '../trip_rules_test.dart' show accepted;

void seedScreen(String role, String name) {
  AppSession.setAuthenticatedUser(
    id: role == 'driver' ? 'd1' : 'u1',
    name: role == 'driver' ? 'Alejandro dela Cruz' : 'María Victoria dela Cruz',
    role: role,
    email: 'fixture.profile@example.test',
  );
  AppSession.currentUserName.value = 'María Victoria dela Cruz';
  AppSession.currentDriverName.value = 'Alejandro dela Cruz';
  AppSession.isDriverOnline.value = false;
  AppSession.allSpots.value = TouristSpotModel.catalog;
  AppSession.tourPackages.value = TourPackageModel.catalog;
  AppSession.favorites.value = {TouristSpotModel.catalog.first.id};
  AppSession.adminCapabilities.value = {
    'super_admin',
    'operations',
    'finance',
    'content',
    'support',
    'driver_compliance',
  };
  final b = accepted().copyWith(
    id: 'test',
    touristName: 'María Victoria dela Cruz',
    driverName: 'Alejandro dela Cruz',
    pickupAddress: 'Bustos Municipal Hall, Poblacion, Bustos, Bulacan',
    baseFareCents: 1234567,
    totalFareCents: 1234567,
    status: name.contains('Incoming')
        ? BookingStatus.pending
        : BookingStatus.accepted,
  );
  AppSession.bookings.value = [
    b,
    // Ended trips, so history and earnings lists show several records.
    if (name.startsWith('DriverBookings') || name.startsWith('DriverEarnings'))
      for (final (i, status) in [
        BookingStatus.completed,
        BookingStatus.completed,
        BookingStatus.cancelled,
      ].indexed)
        b.copyWith(
          id: 'ended$i',
          status: status,
          paymentStatus: status == BookingStatus.completed
              ? PaymentStatus.paid
              : PaymentStatus.unpaid,
          totalFareCents: 70000 + i * 15000,
          completedAt: DateTime.now().subtract(Duration(hours: i + 1)),
        ),
  ];
  AppSession.activeBookingId = b.id;
  AppSession.activeDriverBookingId = b.id;
  // Tours are booked only as packages: the review screen shows TRIC LAKBAY.
  AppSession.selectPackage(TourPackageModel.catalog.first);
  AppSession.userLatitude.value = 14.9571;
  AppSession.userLongitude.value = 120.9188;
  AppSession.draft.pickupAddress.value = 'Bustos Municipal Hall, Bulacan';
  AppSession.adminDrivers.value = [
    {
      'id': 'd1',
      'name': 'Alejandro dela Cruz',
      'email': 'driver@example.test',
      'phone': '+639171234567',
      'plate': 'ABC 123',
      'franchise': 'FR-123456',
      'status': 'active',
      'isOnline': false,
      'rating': 4.8,
      'trips': 120,
      'earnings': 12345.5,
      'passengerCapacity': 3,
      'acceptsAccessibilityRequests': true,
      'licenseExpiresOn': '2027-12-31',
      'franchiseExpiresOn': '2027-12-31',
      'vehicleInspectionExpiresOn': '2027-12-31',
      'serviceAreaName': 'Bustos, Bulacan',
      'serviceAreaLatitude': 14.9571,
      'serviceAreaLongitude': 120.9188,
      'serviceAreaRadiusKm': 15.0,
      'lat': 14.9571,
      'lng': 120.9188,
      'balance': 1234.5,
      'reliability': 98,
      'updatedAt': '2026-11-01T00:00:00Z',
    },
  ];
  AppSession.adminTourists.value = [
    {
      'id': 'u1',
      'name': 'María Victoria dela Cruz',
      'email': 'tourist@example.test',
      'phone': '+639171234568',
      'status': 'active',
      'bookings': 2,
    },
  ];
  AppSession.adminFeedbacks.value = [];
  AppSession.notifications.value = [];
  AppSession.operationalAlerts.value = [];
}
