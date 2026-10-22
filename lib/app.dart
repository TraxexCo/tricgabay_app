import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'core/prototype/prototype_session.dart';
import 'models/trip_record.dart';

// Auth screens
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_role_screen.dart';
import 'features/auth/screens/register_tourist_screen.dart';
import 'features/auth/screens/register_driver_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';

// Tourist screens
import 'features/tourist/screens/tourist_shell_screen.dart';
import 'features/tourist/screens/tourist_home_screen.dart';
import 'features/tourist/screens/tourist_search_screen.dart';
import 'features/tourist/screens/tourist_bookings_screen.dart';
import 'features/tourist/screens/tourist_profile_screen.dart';
import 'features/tourist/screens/tourist_spot_info_screen.dart';
import 'features/tourist/screens/photo_gallery_screen.dart';
import 'features/tourist/screens/itinerary_builder_screen.dart';
import 'features/tourist/screens/fare_summary_screen.dart';
import 'features/tourist/screens/booking_confirmation_screen.dart';
import 'features/tourist/screens/find_driver_screen.dart';
import 'features/tourist/screens/driver_tracking_screen.dart';
import 'features/tourist/screens/favorites_screen.dart';
import 'features/tourist/screens/booking_detail_screen.dart';
import 'features/tourist/screens/rate_review_screen.dart';
import 'features/tourist/screens/tourist_notifications_screen.dart';
import 'features/tourist/screens/tourist_edit_profile_screen.dart';
import 'features/tourist/screens/emergency_screen.dart';
import 'features/tourist/screens/feedback_screen.dart';
import 'features/tourist/screens/tour_packages_screen.dart';
import 'features/tourist/screens/tour_package_detail_screen.dart';
import 'features/tourist/screens/location_picker_screen.dart';

// Driver screens
import 'features/driver/screens/driver_shell_screen.dart';
import 'features/driver/screens/driver_home_screen.dart';
import 'features/driver/screens/driver_bookings_screen.dart';
import 'features/driver/screens/driver_earnings_screen.dart';
import 'features/driver/screens/driver_profile_screen.dart';
import 'features/driver/screens/incoming_booking_screen.dart';
import 'features/driver/screens/active_trip_screen.dart';
import 'features/driver/screens/driver_notifications_screen.dart';
import 'features/driver/screens/driver_edit_profile_screen.dart';
import 'features/driver/screens/driver_emergency_screen.dart';

// Admin screens
import 'features/admin/screens/admin_shell_screen.dart';
import 'features/admin/screens/admin_login_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/manage_drivers_screen.dart';
import 'features/admin/screens/driver_detail_admin_screen.dart';
import 'features/admin/screens/manage_tourists_screen.dart';
import 'features/admin/screens/manage_spots_screen.dart';
import 'features/admin/screens/spot_form_screen.dart';
import 'features/admin/screens/monitor_bookings_screen.dart';
import 'features/admin/screens/fare_settings_screen.dart';
import 'features/admin/screens/ratings_feedback_screen.dart';
import 'features/admin/screens/send_announcement_screen.dart';
import 'features/admin/screens/admin_reports_screen.dart';
import 'features/admin/screens/admin_live_map_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _touristNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'tourist');
final _driverNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'driver');
final _adminNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'admin');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: kDebugMode,
  refreshListenable: PrototypeSession.authRevision,
  redirect: (context, state) {
    final path = state.uri.path;
    final role = PrototypeSession.authenticatedRole;
    final protectedRole = path.startsWith('/tourist/')
        ? 'tourist'
        : path.startsWith('/driver/')
        ? 'driver'
        : path.startsWith('/admin/') && path != AppRoutes.adminLogin
        ? 'admin'
        : null;
    if (protectedRole == null || role == protectedRole) return null;
    return protectedRole == 'admin' ? AppRoutes.adminLogin : AppRoutes.login;
  },
  routes: [
    // ─── Auth ───────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerRole,
      builder: (context, state) => const RegisterRoleScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerTourist,
      builder: (context, state) => const RegisterTouristScreen(),
    ),
    GoRoute(
      path: AppRoutes.registerDriver,
      builder: (context, state) => const RegisterDriverScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordScreen(),
    ),

    // ─── Tourist Shell ───────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          TouristShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _touristNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.touristHome,
              builder: (context, state) => const TouristHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.touristSearch,
              builder: (context, state) => const TouristSearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.touristBookings,
              builder: (context, state) => const TouristBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.touristProfile,
              builder: (context, state) => const TouristProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // ─── Tourist Full-Screen Routes ──────────────────────────
    GoRoute(
      path: '/tourist/location-picker',
      builder: (context, state) => const LocationPickerScreen(),
    ),
    GoRoute(
      path: '/tourist/spot/:spotId',
      builder: (context, state) =>
          TouristSpotInfoScreen(spotId: state.pathParameters['spotId']!),
    ),
    GoRoute(
      path: '/tourist/spot/:spotId/gallery',
      builder: (context, state) =>
          PhotoGalleryScreen(spotId: state.pathParameters['spotId']!),
    ),
    GoRoute(
      path: AppRoutes.itineraryBuilder,
      builder: (context, state) => const ItineraryBuilderScreen(),
    ),
    GoRoute(
      path: AppRoutes.fareSummary,
      builder: (context, state) => const FareSummaryScreen(),
    ),
    GoRoute(
      path: AppRoutes.bookingConfirmation,
      builder: (context, state) => const BookingConfirmationScreen(),
    ),
    GoRoute(
      path: AppRoutes.findDriver,
      builder: (context, state) => const FindDriverScreen(),
    ),
    GoRoute(
      path: '/tourist/tracking/:bookingId',
      builder: (context, state) =>
          DriverTrackingScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/tourist/bookings/:bookingId',
      builder: (context, state) =>
          BookingDetailScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/tourist/review/:bookingId',
      builder: (context, state) =>
          RateReviewScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: AppRoutes.touristNotifications,
      builder: (context, state) => const TouristNotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.touristEditProfile,
      builder: (context, state) => const TouristEditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.emergency,
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: AppRoutes.feedback,
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: AppRoutes.tourPackages,
      builder: (context, state) => const TourPackagesScreen(),
    ),
    GoRoute(
      path: '/tourist/tour-packages/:packageId',
      builder: (context, state) => TourPackageDetailScreen(
        packageId: state.pathParameters['packageId']!,
      ),
    ),

    // ─── Driver Shell ─────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          DriverShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _driverNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.driverHome,
              builder: (context, state) => const DriverHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.driverBookings,
              builder: (context, state) => const DriverBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.driverEarnings,
              builder: (context, state) => const DriverEarningsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.driverProfile,
              builder: (context, state) => const DriverProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // ─── Driver Full-Screen Routes ────────────────────────────
    GoRoute(
      path: '/driver/bookings/:bookingId',
      builder: (context, state) => BookingDetailScreen(
        bookingId: state.pathParameters['bookingId']!,
        viewer: TripActor.driver,
      ),
    ),
    GoRoute(
      path: '/admin/booking/:bookingId',
      builder: (context, state) => BookingDetailScreen(
        bookingId: state.pathParameters['bookingId']!,
        viewer: TripActor.admin,
      ),
    ),
    GoRoute(
      path: '/driver/incoming/:bookingId',
      builder: (context, state) =>
          IncomingBookingScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: '/driver/trip/:bookingId',
      builder: (context, state) =>
          ActiveTripScreen(bookingId: state.pathParameters['bookingId']!),
    ),
    GoRoute(
      path: AppRoutes.driverNotifications,
      builder: (context, state) => const DriverNotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverEditProfile,
      builder: (context, state) => const DriverEditProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverEmergency,
      builder: (context, state) => const DriverEmergencyScreen(),
    ),

    // ─── Admin ────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.adminLogin,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AdminShellScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          navigatorKey: _adminNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.manageDrivers,
              builder: (context, state) => const ManageDriversScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.manageTouristSpots,
              builder: (context, state) => const ManageSpotsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.adminReports,
              builder: (context, state) => const AdminReportsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/admin/drivers/:driverId',
      builder: (context, state) =>
          DriverDetailAdminScreen(driverId: state.pathParameters['driverId']!),
    ),
    GoRoute(
      path: AppRoutes.manageTourists,
      builder: (context, state) => const ManageTouristsScreen(),
    ),
    GoRoute(
      path: AppRoutes.spotForm,
      builder: (context, state) => SpotFormScreen(spot: state.extra as dynamic),
    ),
    GoRoute(
      path: AppRoutes.monitorBookings,
      builder: (context, state) => const MonitorBookingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.fareSettings,
      builder: (context, state) => const FareSettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.ratingsAndFeedback,
      builder: (context, state) => const RatingsFeedbackScreen(),
    ),
    GoRoute(
      path: AppRoutes.sendAnnouncements,
      builder: (context, state) => const SendAnnouncementScreen(),
    ),
    GoRoute(
      path: '/admin/live-map',
      builder: (context, state) => const AdminLiveMapScreen(),
    ),
  ],
);
