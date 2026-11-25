import '../../core/constants/app_routes.dart';
import '../../core/services/auth_service.dart';

/// Where a signed-in profile lands: the login screen and the sign-up screens
/// both use this, so a new account reaches the same place a returning one does.
String routeForProfile(SignedInProfile profile) => profile.applicationPending
    ? '/driver/application-pending'
    : switch (profile.role) {
        AppRole.admin => AppRoutes.adminDashboard,
        AppRole.driver => '/driver/home',
        _ => '/tourist/home',
      };
