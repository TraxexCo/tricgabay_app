import 'package:flutter/foundation.dart';

import '../../models/booking_model.dart';
import '../../models/notification_item.dart';
import '../../models/tourist_spot_model.dart';
import '../services/cancellation_policy.dart';
import '../services/fare_policy.dart';

/// Feature-owned state containers. `AppSession` remains a transitional
/// command facade while screens are migrated, but it no longer owns one giant
/// collection of unrelated notifiers.
class AuthStateController {
  final currentUserName = ValueNotifier<String>('');
  final revision = ValueNotifier<int>(0);
  final storageError = ValueNotifier<String?>(null);
}

class CatalogStateController {
  final spots = ValueNotifier<List<TouristSpotModel>>(TouristSpotModel.catalog);
  final itinerary = ValueNotifier<List<TouristSpotModel>>([]);
  final favorites = ValueNotifier<Set<String>>({});
  final focusedSpotId = ValueNotifier<String?>(null);
}

class BookingStateController {
  final bookings = ValueNotifier<List<BookingModel>>([]);
  final notifications = ValueNotifier<List<NotificationItem>>([]);
  final userLatitude = ValueNotifier<double?>(null);
  final userLongitude = ValueNotifier<double?>(null);
  final farePolicy = ValueNotifier<FarePolicy>(const FarePolicy());
  final cancellationPolicy = ValueNotifier<CancellationPolicy>(
    const CancellationPolicy(),
  );
  final customPickupAddress = ValueNotifier<String?>(null);
}

class DriverStateController {
  final isOnline = ValueNotifier<bool>(false);
  final currentName = ValueNotifier<String>('');
}

class AdminStateController {
  final drivers = ValueNotifier<List<Map<String, dynamic>>>([]);
  final tourists = ValueNotifier<List<Map<String, dynamic>>>([]);
  final feedback = ValueNotifier<List<Map<String, dynamic>>>([]);
  final capabilities = ValueNotifier<Set<String>>({});
  final operationalAlerts = ValueNotifier<List<Map<String, dynamic>>>([]);
}

class PreferenceStateController {
  final isFilipino = ValueNotifier<bool>(false);
}

class AppFeatureControllers {
  AppFeatureControllers._();

  static final auth = AuthStateController();
  static final catalog = CatalogStateController();
  static final booking = BookingStateController();
  static final driver = DriverStateController();
  static final admin = AdminStateController();
  static final preferences = PreferenceStateController();
}
