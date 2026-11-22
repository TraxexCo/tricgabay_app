class AppRoutes {
  AppRoutes._();

  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String registerRole = '/register/role';
  static const String registerTourist = '/register/tourist';
  static const String registerDriver = '/register/driver';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Tourist shell
  static const String touristShell = '/tourist';
  static const String touristHome = '/tourist/home';
  static const String touristSearch = '/tourist/search';
  static const String touristBookings = '/tourist/bookings';
  static const String touristProfile = '/tourist/profile';

  // Tourist detail screens (full-screen, not tab)
  static const String spotInfo = '/tourist/spot/:spotId';
  static const String photoGallery = '/tourist/spot/:spotId/gallery';
  static const String itineraryBuilder = '/tourist/itinerary';
  static const String fareSummary = '/tourist/fare-summary';
  static const String bookingConfirmation = '/tourist/booking-confirmation';
  static const String findDriver = '/tourist/find-driver';
  static const String driverTracking = '/tourist/tracking/:bookingId';
  static const String favorites = '/tourist/favorites';
  static const String bookingDetail = '/tourist/bookings/:bookingId';
  static const String rateReview = '/tourist/review/:bookingId';
  static const String touristNotifications = '/tourist/notifications';
  static const String touristEditProfile = '/tourist/profile/edit';
  static const String emergency = '/tourist/emergency';
  static const String feedback = '/tourist/feedback';
  static const String tourPackages = '/tourist/tour-packages';
  static const String tourPackageDetail = '/tourist/tour-packages/:packageId';

  // Driver shell
  static const String driverShell = '/driver';
  static const String driverHome = '/driver/home';
  static const String driverBookings = '/driver/bookings';
  static const String driverEarnings = '/driver/earnings';
  static const String driverProfile = '/driver/profile';

  // Driver detail screens
  static const String incomingBooking = '/driver/incoming/:bookingId';
  static const String activeTrip = '/driver/trip/:bookingId';
  static const String driverBookingDetail = '/driver/bookings/:bookingId';
  static const String driverNotifications = '/driver/notifications';
  static const String driverEditProfile = '/driver/profile/edit';
  static const String driverEmergency = '/driver/emergency';
  static const String driverFeedback = '/driver/feedback';

  // Admin shell
  static const String adminShell = '/admin';
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String manageDrivers = '/admin/drivers';
  static const String driverDetailAdmin = '/admin/drivers/:driverId';
  static const String manageTourists = '/admin/tourists';
  static const String manageTouristSpots = '/admin/spots';
  static const String spotForm = '/admin/spots/form';
  static const String managePackages = '/admin/packages';
  static const String packageForm = '/admin/packages/form';
  static const String monitorBookings = '/admin/bookings';
  static const String fareSettings = '/admin/fare-settings';
  static const String ratingsAndFeedback = '/admin/ratings';
  static const String sendAnnouncements = '/admin/announcements';
  static const String adminReports = '/admin/reports';
  static const String activeDriverMap = '/admin/active-drivers';
}
