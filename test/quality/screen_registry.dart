import 'package:go_router/go_router.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_shell_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_shell_screen.dart';
import 'package:tricgabay_app/features/admin/screens/admin_shell_screen.dart';
import 'package:tricgabay_app/core/widgets/data_rights_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tricgabay_app/models/tourist_spot_model.dart';
import 'package:tricgabay_app/features/tourist/screens/tour_package_detail_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tour_packages_screen.dart';
import 'package:tricgabay_app/features/admin/screens/manage_packages_screen.dart';
import 'package:tricgabay_app/features/admin/screens/package_form_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_spot_info_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_search_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_profile_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_notifications_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_home_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_edit_profile_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/tourist_bookings_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/rate_review_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/photo_gallery_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/find_driver_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/feedback_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/favorites_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/fare_summary_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/emergency_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/driver_tracking_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/booking_detail_screen.dart';
import 'package:tricgabay_app/features/tourist/screens/booking_confirmation_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_application_pending_screen.dart';
import 'package:tricgabay_app/features/driver/screens/active_trip_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_bookings_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_earnings_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_edit_profile_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_gcash_settings_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_emergency_screen.dart';
import 'package:tricgabay_app/features/driver/screens/incoming_booking_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_profile_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_notifications_screen.dart';
import 'package:tricgabay_app/features/driver/screens/driver_home_screen.dart';
import 'package:tricgabay_app/features/auth/screens/forgot_password_screen.dart';
import 'package:tricgabay_app/features/auth/screens/splash_screen.dart';
import 'package:tricgabay_app/features/auth/screens/reset_password_screen.dart';
import 'package:tricgabay_app/features/auth/screens/register_tourist_screen.dart';
import 'package:tricgabay_app/features/auth/screens/register_role_screen.dart';
import 'package:tricgabay_app/features/auth/screens/register_driver_screen.dart';
import 'package:tricgabay_app/features/auth/screens/onboarding_screen.dart';
import 'package:tricgabay_app/features/auth/screens/login_screen.dart';
import 'package:tricgabay_app/features/admin/screens/admin_live_map_screen.dart';
import 'package:tricgabay_app/features/admin/screens/admin_dashboard_screen.dart';
import 'package:tricgabay_app/features/admin/screens/admin_reports_screen.dart';
import 'package:tricgabay_app/features/admin/screens/spot_form_screen.dart';
import 'package:tricgabay_app/features/admin/screens/admin_location_picker_screen.dart';
import 'package:tricgabay_app/features/admin/screens/send_announcement_screen.dart';
import 'package:tricgabay_app/features/admin/screens/ratings_feedback_screen.dart';
import 'package:tricgabay_app/features/admin/screens/gcash_disputes_screen.dart';
import 'package:tricgabay_app/core/services/gcash_repository.dart';
import 'package:tricgabay_app/features/admin/screens/monitor_bookings_screen.dart';
import 'package:tricgabay_app/features/admin/screens/manage_tourists_screen.dart';
import 'package:tricgabay_app/features/admin/screens/manage_spots_screen.dart';
import 'package:tricgabay_app/features/admin/screens/manage_drivers_screen.dart';
import 'package:tricgabay_app/features/admin/screens/fare_settings_screen.dart';
import 'package:tricgabay_app/features/admin/screens/emergency_contacts_admin_screen.dart';
import 'package:tricgabay_app/features/admin/screens/driver_detail_admin_screen.dart';
import 'package:tricgabay_app/features/admin/screens/data_requests_admin_screen.dart';

class ScreenCase {
  final String name, role;
  final Widget Function() create;
  const ScreenCase(this.name, this.role, this.create);
}

final screenCases = <ScreenCase>[
  ScreenCase('ManagePackagesScreen', 'admin', () => ManagePackagesScreen()),
  ScreenCase(
    'PackageFormScreen',
    'admin',
    () => PackageFormScreen(package: TourPackageModel.catalog.last),
  ),
  ScreenCase('TouristShellScreen', 'tourist', () => const TouristHomeScreen()),
  ScreenCase('DriverShellScreen', 'driver', () => const DriverHomeScreen()),
  ScreenCase('AdminShellScreen', 'admin', () => const AdminDashboardScreen()),
  ScreenCase(
    'DataRightsScreen',
    'tourist',
    () => DataRightsScreen(loader: () => dataRequestFixtures),
  ),
  ScreenCase(
    'SpotFormEditScreen',
    'admin',
    () => SpotFormScreen(spot: TouristSpotModel.catalog.first),
  ),
  ScreenCase(
    'TourPackageDetailScreen',
    'tourist',
    () => TourPackageDetailScreen(packageId: TourPackageModel.catalog.first.id),
  ),
  ScreenCase('TourPackagesScreen', 'tourist', () => TourPackagesScreen()),
  ScreenCase(
    'TouristSpotInfoScreen',
    'tourist',
    () => TouristSpotInfoScreen(spotId: TouristSpotModel.catalog.first.id),
  ),
  ScreenCase('TouristSearchScreen', 'tourist', () => TouristSearchScreen()),
  ScreenCase('TouristProfileScreen', 'tourist', () => TouristProfileScreen()),
  ScreenCase(
    'TouristNotificationsScreen',
    'tourist',
    () => TouristNotificationsScreen(),
  ),
  ScreenCase('TouristHomeScreen', 'tourist', () => TouristHomeScreen()),
  ScreenCase(
    'TouristEditProfileScreen',
    'tourist',
    () => TouristEditProfileScreen(),
  ),
  ScreenCase('TouristBookingsScreen', 'tourist', () => TouristBookingsScreen()),
  ScreenCase(
    'RateReviewScreen',
    'tourist',
    () => RateReviewScreen(bookingId: 'test'),
  ),
  ScreenCase(
    'PhotoGalleryScreen',
    'tourist',
    () => PhotoGalleryScreen(spotId: TouristSpotModel.catalog.first.id),
  ),
  ScreenCase('FindDriverScreen', 'tourist', () => FindDriverScreen()),
  ScreenCase('FeedbackScreen', 'tourist', () => FeedbackScreen()),
  ScreenCase('FavoritesScreen', 'tourist', () => FavoritesScreen()),
  ScreenCase('FareSummaryScreen', 'tourist', () => FareSummaryScreen()),
  ScreenCase('EmergencyScreen', 'tourist', () => EmergencyScreen()),
  ScreenCase(
    'DriverTrackingScreen',
    'tourist',
    () => DriverTrackingScreen(bookingId: 'test'),
  ),
  ScreenCase(
    'BookingDetailScreen',
    'tourist',
    () => BookingDetailScreen(bookingId: 'test'),
  ),
  ScreenCase(
    'BookingConfirmationScreen',
    'tourist',
    () => BookingConfirmationScreen(),
  ),
  ScreenCase(
    'DriverApplicationPendingScreen',
    'driver',
    () => DriverApplicationPendingScreen(
      loader: () async => {'role': 'driver', 'status': 'pending'},
    ),
  ),
  ScreenCase(
    'ActiveTripScreen',
    'driver',
    () => ActiveTripScreen(bookingId: 'test'),
  ),
  ScreenCase('DriverBookingsScreen', 'driver', () => DriverBookingsScreen()),
  ScreenCase('DriverEarningsScreen', 'driver', () => DriverEarningsScreen()),
  ScreenCase(
    'DriverEditProfileScreen',
    'driver',
    () => DriverEditProfileScreen(),
  ),
  ScreenCase('DriverEmergencyScreen', 'driver', () => DriverEmergencyScreen()),
  ScreenCase(
    'DriverGcashSettingsScreen',
    'driver',
    () => DriverGcashSettingsScreen(
      driverId: 'd1',
      loader: (_) async => {
        'gcash_number': '09171234567',
        'gcash_account_name': 'Alejandro dela Cruz',
        'is_active': true,
      },
    ),
  ),
  ScreenCase(
    'IncomingBookingScreen',
    'driver',
    () => IncomingBookingScreen(bookingId: 'test'),
  ),
  ScreenCase('DriverProfileScreen', 'driver', () => DriverProfileScreen()),
  ScreenCase(
    'DriverNotificationsScreen',
    'driver',
    () => DriverNotificationsScreen(),
  ),
  ScreenCase('DriverHomeScreen', 'driver', () => DriverHomeScreen()),
  ScreenCase('ForgotPasswordScreen', 'auth', () => ForgotPasswordScreen()),
  ScreenCase(
    'SplashScreen',
    'auth',
    () => SplashScreen(restoreProfile: () => Completer<Never>().future),
  ),
  ScreenCase('ResetPasswordScreen', 'auth', () => ResetPasswordScreen()),
  ScreenCase('RegisterTouristScreen', 'auth', () => RegisterTouristScreen()),
  ScreenCase('RegisterRoleScreen', 'auth', () => RegisterRoleScreen()),
  ScreenCase('RegisterDriverScreen', 'auth', () => RegisterDriverScreen()),
  ScreenCase('OnboardingScreen', 'auth', () => OnboardingScreen()),
  ScreenCase('LoginScreen', 'auth', () => LoginScreen()),
  ScreenCase('AdminLiveMapScreen', 'admin', () => AdminLiveMapScreen()),
  ScreenCase('AdminDashboardScreen', 'admin', () => AdminDashboardScreen()),
  ScreenCase('AdminReportsScreen', 'admin', () => AdminReportsScreen()),
  ScreenCase('SpotFormScreen', 'admin', () => SpotFormScreen()),
  ScreenCase(
    'AdminLocationPickerScreen',
    'admin',
    () => const AdminLocationPickerScreen(),
  ),
  ScreenCase('SendAnnouncementScreen', 'admin', () => SendAnnouncementScreen()),
  ScreenCase('RatingsFeedbackScreen', 'admin', () => RatingsFeedbackScreen()),
  ScreenCase('MonitorBookingsScreen', 'admin', () => MonitorBookingsScreen()),
  ScreenCase('ManageTouristsScreen', 'admin', () => ManageTouristsScreen()),
  ScreenCase('ManageSpotsScreen', 'admin', () => ManageSpotsScreen()),
  ScreenCase('ManageDriversScreen', 'admin', () => ManageDriversScreen()),
  ScreenCase('FareSettingsScreen', 'admin', () => FareSettingsScreen()),
  ScreenCase(
    'EmergencyContactsAdminScreen',
    'admin',
    () => EmergencyContactsAdminScreen(loader: () => emergencyContactFixtures),
  ),
  ScreenCase(
    'GcashDisputesScreen',
    'admin',
    () => GcashDisputesScreen(
      loader: () async => [
        GcashDispute(
          bookingId: 'b1',
          referenceLabel: 'TRIC-0F3A9C21B7D4E8F1',
          touristName: 'Maria Clara Santos',
          driverName: 'Alejandro dela Cruz',
          fareCents: 25000,
          disputedAt: DateTime(2026, 11, 19, 15),
          escalatedAt: DateTime(2026, 11, 20, 15),
          hasProof: true,
          ruling: null,
        ),
      ],
    ),
  ),
  ScreenCase(
    'GcashDisputeDetailScreen',
    'admin',
    () => GcashDisputeDetailScreen(
      bookingId: 'b1',
      loader: (_) async => const GcashDisputeDetail(
        fareCents: 25000,
        referenceNo: '1009876543210',
        disputeNote: 'Not in my GCash history yet',
        escalationNote: 'I sent it right after the tour.',
      ),
    ),
  ),
  ScreenCase(
    'DriverDetailAdminScreen',
    'admin',
    () => DriverDetailAdminScreen(driverId: 'd1'),
  ),
  ScreenCase(
    'DataRequestsAdminScreen',
    'admin',
    () => DataRequestsAdminScreen(loader: () => dataRequestFixtures),
  ),
];

Future<List<Map<String, dynamic>>> get dataRequestFixtures async => [
  {
    'id': 'fixture-export-abc',
    'status': 'pending',
    'requested_at': '2026-11-03T12:45:00Z',
    'notice_language': 'fil',
  },
  {
    'id': 'fixture-export-def',
    'status': 'fulfilled',
    'requested_at': '2026-10-31T09:00:00Z',
    'notice_language': 'en',
  },
];
Future<List<Map<String, dynamic>>> get emergencyContactFixtures async => [
  {
    'id': 'fixture-emergency',
    'name_en':
        'Municipal emergency response and disaster risk reduction office',
    'name_fil':
        'Tanggapan ng munisipyo para sa pagtugon sa sakuna at pagbawas ng panganib',
    'phone': null,
    'priority': 1,
    'is_placeholder': true,
  },
];

GoRouter fixtureRouter(ScreenCase screen) {
  if (!screen.name.endsWith('ShellScreen')) {
    return GoRouter(
      initialLocation: '/screen',
      routes: [
        GoRoute(path: '/screen', builder: (context, state) => screen.create()),
      ],
    );
  }
  return GoRouter(
    initialLocation: '/branch0',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => switch (screen.role) {
          'tourist' => TouristShellScreen(navigationShell: shell),
          'driver' => DriverShellScreen(navigationShell: shell),
          _ => AdminShellScreen(navigationShell: shell),
        },
        branches: [
          for (var i = 0; i < 4; i++)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/branch$i',
                  builder: (context, state) => screen.create(),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
