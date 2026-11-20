import 'package:tricgabay_app/core/prototype/prototype_session.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/models/booking_model.dart';
import '../trip_rules_test.dart' show accepted;

void seedScreen(String role, String name) {
  PrototypeSession.setAuthenticatedUser(
    id: role == 'driver' ? 'd1' : 'u1',
    name: role == 'driver' ? 'Alejandro dela Cruz' : 'María Victoria dela Cruz',
    role: role,
    email: 'fixture.profile@example.test',
  );
  PrototypeSession.currentUserName.value = 'María Victoria dela Cruz';
  PrototypeSession.currentDriverName.value = 'Alejandro dela Cruz';
  PrototypeSession.isDriverOnline.value = false;
  PrototypeSession.allSpots.value = TouristSpotModel.catalog;
  PrototypeSession.itinerary.value = TouristSpotModel.catalog.take(3).toList();
  PrototypeSession.favorites.value = {TouristSpotModel.catalog.first.id};
  PrototypeSession.adminCapabilities.value = {
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
  PrototypeSession.bookings.value = [b];
  PrototypeSession.activeBookingId = b.id;
  PrototypeSession.activeDriverBookingId = b.id;
  PrototypeSession.activePackageId = null;
  PrototypeSession.userLatitude.value = 14.9571;
  PrototypeSession.userLongitude.value = 120.9188;
  PrototypeSession.customPickupAddress.value = 'Bustos Municipal Hall, Bulacan';
  PrototypeSession.adminDrivers.value = [
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
  PrototypeSession.adminTourists.value = [
    {
      'id': 'u1',
      'name': 'María Victoria dela Cruz',
      'email': 'tourist@example.test',
      'phone': '+639171234568',
      'status': 'active',
      'bookings': 2,
    },
  ];
  PrototypeSession.adminFeedbacks.value = [];
  PrototypeSession.notifications.value = [];
  PrototypeSession.operationalAlerts.value = [];
}
