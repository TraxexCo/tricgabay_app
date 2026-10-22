import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../models/trip_record.dart';
import '../services/fare_policy.dart';
import '../services/cancellation_policy.dart';
import '../services/trip_rules.dart';
import '../services/backend_repository.dart';
import '../config/backend_config.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../../models/tourist_spot_model.dart';
import '../../models/booking_model.dart';

// ---------------------------------------------------------------------------
// Notification Model
// ---------------------------------------------------------------------------

enum NotificationType { booking, driver, promo, system }

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final NotificationType type;
  bool isRead;
  final String? routePath; // Where to navigate on tap

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.isRead = false,
    this.routePath,
  });
}

// ---------------------------------------------------------------------------
// Application session
// ---------------------------------------------------------------------------

/// Local app state with persisted bookings and fare policies.
/// Cross-device synchronization and trusted authorization need a backend.
class PrototypeSession {
  PrototypeSession._();

  static final itinerary = ValueNotifier<List<TouristSpotModel>>([]);
  static final favorites = ValueNotifier<Set<String>>({});

  static final bookings = ValueNotifier<List<BookingModel>>([]);
  static final notifications = ValueNotifier<List<NotificationItem>>([]);
  static final currentUserName = ValueNotifier<String>('');
  static String? authenticatedUserId;
  static String? authenticatedRole;

  static String? activeBookingId;
  static String? activePackageId;
  static final userLatitude = ValueNotifier<double?>(null);
  static final userLongitude = ValueNotifier<double?>(null);
  static final adminFeedbacks = ValueNotifier<List<Map<String, dynamic>>>([]);
  static final focusedSpotId = ValueNotifier<String?>(null);

  // Authentication State
  static final customPickupAddress = ValueNotifier<String?>(null);
  static double? customPickupLat;
  static double? customPickupLng;
  static int passengerCount = 1;
  static String luggageNotes = '';
  static String accessibilityNeeds = '';
  static DateTime? scheduledAt;

  // ── Fare ────────────────────────────────────────────────────────────────

  static final farePolicy = ValueNotifier<FarePolicy>(const FarePolicy());
  static final cancellationPolicy = ValueNotifier<CancellationPolicy>(
    const CancellationPolicy(),
  );
  static double get estimatedFare => itinerary.value.isEmpty
      ? 0
      : farePolicy.value.quote(activePackageId) / 100;
  static double packageFare(TourPackageModel package) =>
      farePolicy.value.quote(package.id) / 100;

  // ── Active Package ───────────────────────────────────────────────────────

  static TourPackageModel? get activePackage {
    final id = activePackageId;
    if (id == null) return null;
    for (final package in TourPackageModel.catalog) {
      if (package.id == id) return package;
    }
    return null;
  }

  // ── Itinerary ────────────────────────────────────────────────────────────

  static void startCustomItinerary() {
    activePackageId = null;
    itinerary.value = [];
  }

  static void selectPackage(TourPackageModel package) {
    final selected = package.spotIds
        .map(
          (id) => allSpots.value.firstWhere(
            (spot) =>
                spot.id == id && spot.isActive && !spot.isTemporarilyClosed,
            orElse: () => throw const TripRuleException(
              'A package stop is unavailable. Please choose another route.',
            ),
          ),
        )
        .toList();
    activePackageId = package.id;
    itinerary.value = selected;
  }

  static void clearTripPlan() {
    activePackageId = null;
    itinerary.value = [];
  }

  static void toggleItinerary(TouristSpotModel spot) {
    activePackageId = null;
    final next = [...itinerary.value];
    final index = next.indexWhere((item) => item.id == spot.id);
    if (index == -1) {
      TripRules.require(
        !spot.isTemporarilyClosed,
        '${spot.name} is temporarily closed and cannot be added right now.',
      );
      next.add(spot);
    } else {
      next.removeAt(index);
    }
    itinerary.value = next;
  }

  static bool isInItinerary(String spotId) =>
      itinerary.value.any((s) => s.id == spotId);

  // ── Favorites ─────────────────────────────────────────────────────────────

  static void toggleFavorite(String spotId) {
    final next = {...favorites.value};
    next.contains(spotId) ? next.remove(spotId) : next.add(spotId);
    favorites.value = next;
  }

  static bool isFavorite(String spotId) => favorites.value.contains(spotId);

  // ── Bookings ──────────────────────────────────────────────────────────────

  static String get currentTouristId => authenticatedUserId ?? '';
  static final storageError = ValueNotifier<String?>(null);
  static SharedPreferences? _preferences;
  static Future<void> _queue = Future.value();
  static const _storageKey = 'tric_gabay_transactions_v1';

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preferences = prefs;
      if (BackendConfig.isConfigured) {
        bookings.value = [];
        activeBookingId = null;
        activeDriverBookingId = null;
        storageError.value = null;
        return;
      }
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        final restored = (saved['bookings'] as List)
            .map(
              (b) =>
                  BookingModel.fromMap(Map<String, dynamic>.from(b), b['id']),
            )
            .toList();
        final restoredPolicy = FarePolicy.fromMap(
          Map<String, dynamic>.from(saved['fares']),
        );
        bookings.value = restored;
        farePolicy.value = restoredPolicy;
      }
      _restoreActiveIds();
      storageError.value = null;
    } catch (_) {
      _preferences = null;
      storageError.value =
          'Saved trip data could not be read. Booking changes are paused to protect your records. Retry storage or restart the app.';
    }
  }

  static Future<void> syncRemoteState() async {
    if (!BackendConfig.isConfigured || authenticatedUserId == null) return;
    try {
      await BackendRepository.rpc('activate_due_scheduled_bookings', const {});
      final results = await Future.wait([
        BackendRepository.loadFarePolicy(),
        BackendRepository.loadCancellationPolicy(),
        BackendRepository.loadSpots(),
        BackendRepository.loadBookings(),
        BackendRepository.loadDirectory(),
        BackendRepository.loadNotifications(),
        if (authenticatedRole == 'admin')
          BackendRepository.loadFeedback()
        else
          Future.value(<Map<String, dynamic>>[]),
      ]);
      farePolicy.value = results[0] as FarePolicy;
      cancellationPolicy.value = results[1] as CancellationPolicy;
      allSpots.value = results[2] as List<TouristSpotModel>;
      bookings.value = results[3] as List<BookingModel>;
      final directory =
          results[4]
              as ({
                List<Map<String, dynamic>> drivers,
                List<Map<String, dynamic>> tourists,
              });
      adminDrivers.value = directory.drivers;
      adminTourists.value = directory.tourists;
      final remoteNotifications = results[5] as List<Map<String, dynamic>>;
      notifications.value = remoteNotifications
          .map(
            (item) => NotificationItem(
              id: item['id'],
              title: item['title'],
              subtitle: item['body'],
              time: DateTime.parse(item['created_at']),
              type: _notificationType(item['category'] as String?),
              isRead: item['read_at'] != null,
              routePath: item['route_path'],
            ),
          )
          .toList();
      adminFeedbacks.value = results[6] as List<Map<String, dynamic>>;
      _restoreActiveIds();
      storageError.value = null;
      BackendRepository.subscribe(() {
        unawaited(syncRemoteState());
      });
    } catch (error) {
      storageError.value = 'Could not synchronize with the server: $error';
      rethrow;
    }
  }

  static void _restoreActiveIds() {
    activeBookingId = bookings.value
        .where((b) => b.touristId == currentTouristId && b.isActive)
        .firstOrNull
        ?.id;
    activeDriverBookingId = bookings.value
        .where((b) => ownsDriverBooking(b) && b.isActive)
        .firstOrNull
        ?.id;
  }

  static NotificationType _notificationType(String? category) =>
      switch (category) {
        'booking' ||
        'cancellation' ||
        'trip_completed' => NotificationType.booking,
        'driver' || 'dispatch' => NotificationType.driver,
        'promotion' => NotificationType.promo,
        _ => NotificationType.system,
      };

  static Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>(
      (_) {},
      onError: (Object error, StackTrace trace) {},
    );
    return result;
  }

  static Future<void> _persist(
    List<BookingModel> next,
    FarePolicy policy,
  ) async {
    final prefs = _preferences;
    TripRules.require(
      prefs != null,
      'Storage is unavailable. Retry storage before making changes.',
    );
    final encoded = jsonEncode({
      'fares': policy.toMap(),
      'bookings': next.map((b) => {'id': b.id, ...b.toMap()}).toList(),
    });
    try {
      final saved = await prefs!.setString(_storageKey, encoded);
      if (!saved) throw StateError('Save failed');
      storageError.value = null;
    } catch (_) {
      storageError.value =
          'Could not save this change. Please retry; the previous trip state has been kept.';
      throw const TripRuleException(
        'Could not save. No booking or payment state was changed.',
      );
    }
  }

  static Future<void> saveFares({
    required int customCents,
    required Map<String, int> packages,
    required int expectedRevision,
    String reason = 'Administrator updated fixed fares.',
  }) => _serial(() async {
    final old = farePolicy.value;
    TripRules.require(
      old.revision == expectedRevision,
      'Prices changed while you were editing. Reopen this page and review the latest rates.',
    );
    TripRules.require(
      customCents > 0 &&
          customCents <= 10000000 &&
          packages.values.every((v) => v > 0 && v <= 10000000) &&
          TourPackageModel.catalog.every((p) => packages.containsKey(p.id)),
      'Enter valid fixed fares for every route.',
    );
    final next = FarePolicy(
      revision: old.revision + 1,
      customFareCents: customCents,
      packageFares: Map.unmodifiable(packages),
      history: [
        ...old.history,
        '${DateTime.now().toIso8601String()} • Admin • ${reason.trim()} • v${old.revision + 1}: custom ₱${(customCents / 100).toStringAsFixed(2)}; ${packages.entries.map((e) => "${e.key} ₱${(e.value / 100).toStringAsFixed(2)}").join(", ")}',
      ],
    );
    if (BackendConfig.isConfigured) {
      await BackendRepository.saveFares(
        customCents: customCents,
        packageFares: packages,
        reason: reason.trim(),
      );
      await syncRemoteState();
      return;
    }
    await _persist(bookings.value, next);
    farePolicy.value = next;
  });

  static Future<void> saveCancellationPolicy({
    required int expectedVersion,
    required int freeCancellationMinutes,
    required int acceptedTripFeePercent,
    required int driverWaitMinutes,
    required int noShowFeePercent,
    required String terms,
    required String reason,
  }) async {
    TripRules.require(
      BackendConfig.isConfigured && authenticatedRole == 'admin',
      'A configured server and administrator account are required.',
    );
    TripRules.require(
      cancellationPolicy.value.version == expectedVersion,
      'The policy changed while you were editing. Reopen this page.',
    );
    await BackendRepository.saveCancellationPolicy(
      expectedVersion: expectedVersion,
      freeCancellationMinutes: freeCancellationMinutes,
      acceptedTripFeePercent: acceptedTripFeePercent,
      driverWaitMinutes: driverWaitMinutes,
      noShowFeePercent: noShowFeePercent,
      terms: terms,
      reason: reason,
    );
    await syncRemoteState();
  }

  static Future<BookingModel> createBooking({
    required PaymentMethod paymentMethod,
    required int expectedFareRevision,
  }) => _serial(() async {
    TripRules.require(
      paymentMethod == PaymentMethod.cash || BackendConfig.isConfigured,
      'Online payment requires the configured server.',
    );
    TripRules.require(
      !bookings.value.any((b) => b.touristId == currentTouristId && b.isActive),
      'You already have an active booking. Open Trips to continue or cancel it.',
    );
    TripRules.require(
      adminTourists.value.any(
        (u) => u['id'] == currentTouristId && u['status'] == 'active',
      ),
      'This tourist account cannot book right now. Contact the administrator.',
    );
    TripRules.require(
      farePolicy.value.revision == expectedFareRevision,
      'The price changed. Review the updated fare and confirm again.',
    );
    final spots = List<TouristSpotModel>.from(itinerary.value);
    TripRules.require(
      spots.isNotEmpty && spots.length <= 12,
      'Select between 1 and 12 destinations.',
    );
    TripRules.require(
      spots.map((s) => s.id).toSet().length == spots.length,
      'Remove duplicate destinations.',
    );
    TripRules.require(
      spots.every(
        (s) => allSpots.value.any(
          (live) =>
              live.id == s.id && live.isActive && !live.isTemporarilyClosed,
        ),
      ),
      'A destination is no longer available. Update your itinerary.',
    );
    final lat = customPickupLat ?? userLatitude.value;
    final lng = customPickupLng ?? userLongitude.value;
    TripRules.require(
      lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180,
      'Choose a pickup point on the map or enable location first.',
    );
    final pkg = activePackage;
    if (pkg != null) {
      TripRules.require(
        listEquals(pkg.spotIds, spots.map((s) => s.id).toList()),
        'Package stops changed. Select the package again.',
      );
    }
    final cents = farePolicy.value.quote(activePackageId);
    if (BackendConfig.isConfigured) {
      final created = await BackendRepository.createBooking(
        packageId: activePackageId,
        paymentMethod: paymentMethod,
        pickupAddress: customPickupAddress.value ?? 'Current GPS pickup',
        pickupLatitude: lat!,
        pickupLongitude: lng!,
        stops: spots,
        passengerCount: passengerCount,
        luggageNotes: luggageNotes,
        accessibilityNeeds: accessibilityNeeds,
        scheduledAt: scheduledAt,
      );
      await syncRemoteState();
      activeBookingId = created.booking.id;
      return created.booking;
    }
    var booking = BookingModel(
      id: 'TRIC-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      touristId: currentTouristId,
      touristName: currentUserName.value,
      stops: List.unmodifiable(
        spots.map(
          (s) => BookingStop(
            spotId: s.id,
            spotName: s.name,
            latitude: s.latitude,
            longitude: s.longitude,
            fare: 0,
          ),
        ),
      ),
      pickupLat: lat!,
      pickupLng: lng!,
      pickupAddress: customPickupAddress.value ?? 'Current GPS pickup',
      passengerCount: passengerCount,
      luggageNotes: luggageNotes,
      accessibilityNeeds: accessibilityNeeds,
      baseFare: cents / 100,
      totalFare: cents / 100,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime.now(),
      scheduledAt: scheduledAt,
      status: scheduledAt == null
          ? BookingStatus.pending
          : BookingStatus.scheduled,
      dispatchExpiresAt: scheduledAt == null
          ? DateTime.now().add(const Duration(minutes: 10))
          : scheduledAt!.subtract(const Duration(minutes: 20)),
      trip: TripRecord(
        fareRevision: farePolicy.value.revision,
        packageId: activePackageId,
        packageName: pkg?.name,
        pickupCode: (1000 + Random.secure().nextInt(9000)).toString(),
      ),
    );
    booking = TripRules.record(
      booking,
      TripActor.tourist,
      'Fixed fare ₱${booking.totalFare.toStringAsFixed(2)} accepted; cancellation/payment policy v1 accepted.',
    );
    await _persist([booking, ...bookings.value], farePolicy.value);
    bookings.value = [booking, ...bookings.value];
    activeBookingId = booking.id;
    return booking;
  });

  static BookingModel bookingById(String id) {
    final b = bookings.value.where((b) => b.id == id).firstOrNull;
    TripRules.require(b != null, 'This booking could not be found.');
    return b!;
  }

  static String? get currentDriverId =>
      authenticatedRole == 'driver' ? authenticatedUserId : null;
  static bool ownsDriverBooking(BookingModel b) =>
      currentDriverId != null && b.driverId == currentDriverId;
  static void _requireParticipant(BookingModel b, TripActor actor) {
    if (actor == TripActor.tourist) {
      TripRules.require(
        b.touristId == currentTouristId,
        'This booking belongs to another tourist.',
      );
    }
    if (actor == TripActor.driver) {
      TripRules.require(
        ownsDriverBooking(b),
        'This booking is assigned to another driver.',
      );
    }
    TripRules.require(
      actor != TripActor.system,
      'System actions are unavailable here.',
    );
  }

  static Future<BookingModel> _change(
    String id,
    TripActor actor,
    BookingModel Function(BookingModel) action,
  ) => _serial(() async {
    final old = bookingById(id);
    _requireParticipant(old, actor);
    final updated = action(old);
    final next = bookings.value.map((b) => b.id == id ? updated : b).toList();
    await _persist(next, farePolicy.value);
    bookings.value = next;
    _restoreActiveIds();
    return updated;
  });

  static Future<BookingModel> cancelBooking(
    String id, {
    required TripActor actor,
    required String reason,
  }) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('cancel_booking', {
        'p_booking_id': id,
        'p_reason': reason,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, actor, (b) => TripRules.cancel(b, actor, reason));
  }

  static Future<BookingModel> retryDriverSearch(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('retry_booking_dispatch', {
        'p_booking_id': id,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.tourist, (booking) {
      TripRules.require(
        booking.status == BookingStatus.pending && booking.isDispatchExpired,
        'This booking request is not ready to retry.',
      );
      return TripRules.record(
        booking.copyWith(
          dispatchExpiresAt: DateTime.now().add(const Duration(minutes: 10)),
        ),
        TripActor.tourist,
        'Driver search retried for another 10 minutes.',
      );
    });
  }

  static Future<void> refreshDriverOffers(String id) async {
    if (!BackendConfig.isConfigured) return;
    await BackendRepository.rpc('refresh_booking_offers', {'p_booking_id': id});
    await syncRemoteState();
  }

  static Future<void> declineDriverOffer(String id) async {
    TripRules.require(
      BackendConfig.isConfigured,
      'Declining matched offers requires the configured server.',
    );
    await BackendRepository.rpc('decline_booking_offer', {'p_booking_id': id});
    await syncRemoteState();
  }

  static Future<BookingModel> requestDriverReplacement(
    String id,
    String reason,
  ) async {
    TripRules.require(
      BackendConfig.isConfigured,
      'Driver replacement requires the configured server.',
    );
    await BackendRepository.rpc('request_driver_replacement', {
      'p_booking_id': id,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> decideDriverReplacement(
    String id, {
    required bool findReplacement,
  }) async {
    TripRules.require(
      BackendConfig.isConfigured,
      'Driver replacement requires the configured server.',
    );
    await BackendRepository.rpc('decide_driver_replacement', {
      'p_booking_id': id,
      'p_find_replacement': findReplacement,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> reportPickupArrival(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('report_pickup_arrival', {
        'p_booking_id': id,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(
      id,
      TripActor.driver,
      (booking) => TripRules.reportPickupArrival(
        booking,
        waitTime: Duration(minutes: booking.driverWaitMinutes),
      ),
    );
  }

  static Future<BookingModel> declareTouristNoShow(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('declare_tourist_no_show', {
        'p_booking_id': id,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.driver, TripRules.declareTouristNoShow);
  }

  static Future<BookingModel> startTrip(String id, String code) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('start_trip', {
        'p_booking_id': id,
        'p_pickup_code': code,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.driver, (b) => TripRules.start(b, code));
  }

  static Future<BookingModel> reportArrival(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('report_stop_arrival', {'p_booking_id': id});
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.driver, TripRules.proposeArrival);
  }

  static Future<BookingModel> confirmArrival(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('confirm_stop_arrival', {'p_booking_id': id});
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.tourist, TripRules.confirmArrival);
  }

  static Future<BookingModel> proposeRouteChange(
    String id, {
    required String type,
    String? targetStopId,
    List<String>? proposedOrder,
    required String reason,
  }) async {
    TripRules.require(
      BackendConfig.isConfigured,
      'Audited route changes require the configured server.',
    );
    await BackendRepository.rpc('propose_route_change', {
      'p_booking_id': id,
      'p_change_type': type,
      'p_target_stop_id': targetStopId,
      'p_proposed_order': proposedOrder,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> decideRouteChange(
    String id,
    String requestId, {
    required bool approve,
  }) async {
    await BackendRepository.rpc('decide_route_change', {
      'p_route_change_id': requestId,
      'p_approve': approve,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> reportVehicleBreakdown(
    String id,
    String reason,
  ) async {
    await BackendRepository.rpc('report_vehicle_breakdown', {
      'p_booking_id': id,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> decideBreakdownWait(
    String id, {
    required bool wait,
  }) async {
    await BackendRepository.rpc('decide_breakdown_wait', {
      'p_booking_id': id,
      'p_wait': wait,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> resumeAfterBreakdown(String id) async {
    await BackendRepository.rpc('resume_after_breakdown', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<void> reportRouteDeviation(
    String id,
    double distanceMeters,
  ) async {
    if (!BackendConfig.isConfigured) return;
    await BackendRepository.rpc('report_route_deviation', {
      'p_booking_id': id,
      'p_distance_meters': distanceMeters,
    });
  }

  static Future<BookingModel> completeTrip(String id) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('complete_trip', {'p_booking_id': id});
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.driver, TripRules.complete);
  }

  static Future<BookingModel> disputeBooking(
    String id,
    TripActor actor,
    String reason,
  ) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('open_dispute', {
        'p_booking_id': id,
        'p_reason': reason,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, actor, (b) => TripRules.dispute(b, actor, reason));
  }

  static Future<BookingModel> addCaseStatement(
    String id,
    TripActor actor,
    String text,
  ) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('add_dispute_statement', {
        'p_booking_id': id,
        'p_statement': text,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, actor, (b) => TripRules.statement(b, actor, text));
  }

  static Future<BookingModel> resolveSettlement(
    String id,
    int cents,
    String reason,
  ) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('resolve_booking_charge', {
        'p_booking_id': id,
        'p_charge_centavos': cents,
        'p_reason': reason,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(
      id,
      TripActor.admin,
      (b) => TripRules.resolve(b, cents, reason),
    );
  }

  static Future<BookingModel> confirmCash(
    String id,
    TripActor actor, {
    bool refund = false,
  }) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('confirm_cash', {
        'p_booking_id': id,
        'p_direction': refund ? 'refund' : 'payment',
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(
      id,
      actor,
      (b) => TripRules.confirmCash(b, actor, refund: refund),
    );
  }

  static Future<String> processPayMongoRefund(
    String id,
    int amountCents,
    String reason,
  ) async {
    TripRules.require(
      BackendConfig.isConfigured && authenticatedRole == 'admin',
      'An authenticated administrator and configured server are required.',
    );
    final message = await BackendRepository.processPayMongoRefund(
      bookingId: id,
      amountCents: amountCents,
      reason: reason,
    );
    await syncRemoteState();
    return message;
  }

  static Future<String> reconcilePayMongoPayment(String id) async {
    TripRules.require(
      BackendConfig.isConfigured,
      'Payment verification requires the configured server.',
    );
    final result = await BackendRepository.reconcilePayMongoPayment(id);
    await syncRemoteState();
    return result;
  }

  static Future<String> completePayMongoTestRefund(
    String id,
    int amountCents,
    String reason,
  ) async {
    TripRules.require(
      BackendConfig.isConfigured && authenticatedRole == 'admin',
      'An authenticated administrator is required.',
    );
    final result = await BackendRepository.completePayMongoTestRefund(
      bookingId: id,
      amountCents: amountCents,
      reason: reason,
    );
    await syncRemoteState();
    return result;
  }

  static Future<List<Map<String, dynamic>>> financialLedger(String id) {
    TripRules.require(
      BackendConfig.isConfigured,
      'The financial record requires the configured server.',
    );
    return BackendRepository.loadFinancialLedger(id);
  }

  static Future<BookingModel> markBookingRated(
    String id,
    double rating, {
    String review = '',
  }) async {
    if (BackendConfig.isConfigured) {
      await BackendRepository.rpc('submit_driver_review', {
        'p_booking_id': id,
        'p_rating': rating.round(),
        'p_review': review,
      });
      await syncRemoteState();
      return bookingById(id);
    }
    return _change(id, TripActor.tourist, (b) {
      TripRules.require(
        b.status == BookingStatus.completed && b.driverRating == null,
        'Only a completed, unrated trip can be reviewed.',
      );
      TripRules.require(
        rating.isFinite && rating >= 1 && rating <= 5,
        'Select a rating between 1 and 5.',
      );
      return TripRules.record(
        b.copyWith(driverRating: rating, driverReview: review.trim()),
        TripActor.tourist,
        'Driver review submitted.',
      );
    });
  }

  static final isDriverOnline = ValueNotifier<bool>(false);
  static final currentDriverName = ValueNotifier<String>('');
  static String? activeDriverBookingId;

  static double get driverEarnings => bookings.value
      .where(
        (b) =>
            ownsDriverBooking(b) &&
            !b.trip.reviewRequired &&
            b.refundDueCents == 0,
      )
      .fold(0.0, (sum, b) => sum + b.trip.receivedCents / 100);
  static int get driverTripsCompleted => bookings.value
      .where((b) => ownsDriverBooking(b) && b.status == BookingStatus.completed)
      .length;

  static Future<BookingModel> acceptBooking(String id) {
    final acceptingDriverId = currentDriverId;
    return _serial(() async {
      if (BackendConfig.isConfigured) {
        await BackendRepository.rpc('accept_booking', {'p_booking_id': id});
        await syncRemoteState();
        return bookingById(id);
      }
      final b = bookingById(id);
      final driver = adminDrivers.value
          .where((d) => d['id'] == acceptingDriverId)
          .firstOrNull;
      TripRules.require(
        driver != null && driver['status'] == 'active' && isDriverOnline.value,
        'Go online with an approved driver account first.',
      );
      TripRules.require(
        b.status == BookingStatus.pending,
        'This request is no longer available.',
      );
      TripRules.require(
        adminTourists.value.any(
          (u) => u['id'] == b.touristId && u['status'] == 'active',
        ),
        'This tourist account is currently unavailable.',
      );
      TripRules.require(
        !bookings.value.any(
          (other) => other.driverId == acceptingDriverId && other.isActive,
        ),
        'Finish your current trip before accepting another.',
      );
      final updated = TripRules.record(
        b.copyWith(
          status: BookingStatus.accepted,
          driverId: acceptingDriverId,
          driverName: driver!['name'],
          driverPlate: driver['plate'],
          acceptedAt: DateTime.now(),
        ),
        TripActor.driver,
        'Driver accepted the fixed fare and pickup.',
      );
      final next = bookings.value
          .map((item) => item.id == id ? updated : item)
          .toList();
      await _persist(next, farePolicy.value);
      bookings.value = next;
      _restoreActiveIds();
      return updated;
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static void markAllNotificationsRead() {
    if (BackendConfig.isConfigured) {
      unawaited(
        BackendRepository.markAllNotificationsRead().then(
          (_) => syncRemoteState(),
        ),
      );
      return;
    }
    for (final n in notifications.value) {
      n.isRead = true;
    }
    notifications.value = [...notifications.value]; // trigger rebuild
  }

  static void markNotificationRead(String id) {
    if (BackendConfig.isConfigured) {
      unawaited(
        BackendRepository.markNotificationRead(
          id,
        ).then((_) => syncRemoteState()),
      );
      return;
    }
    for (final n in notifications.value) {
      if (n.id == id) n.isRead = true;
    }
    notifications.value = [...notifications.value];
  }

  static int get unreadNotificationCount =>
      notifications.value.where((n) => !n.isRead).length;

  static void _addNotification(NotificationItem item) {
    notifications.value = [item, ...notifications.value];
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  static void updateUserName(String name) {
    currentUserName.value = name;
  }

  static void setAuthenticatedUser({
    required String id,
    required String name,
    required String role,
    required String email,
    String? plateNumber,
  }) {
    authenticatedUserId = id;
    authenticatedRole = role;
    if (role == 'driver') {
      currentDriverName.value = name;
    } else if (role == 'tourist') {
      currentUserName.value = name;
    }
    if (role == 'tourist') {
      adminTourists.value = [
        ...adminTourists.value.where((u) => u['id'] != id),
        {
          'id': id,
          'name': name,
          'email': email,
          'status': 'active',
          'trips': 0,
        },
      ];
    } else if (role == 'driver') {
      adminDrivers.value = [
        ...adminDrivers.value.where((d) => d['id'] != id),
        {
          'id': id,
          'name': name,
          'plate': plateNumber ?? '',
          'status': 'active',
          'rating': 0.0,
        },
      ];
    }
    unawaited(PushNotificationService.refreshRegistration());
  }

  static void clearAuthenticatedUser() {
    authenticatedUserId = null;
    authenticatedRole = null;
    currentUserName.value = '';
    currentDriverName.value = '';
    isDriverOnline.value = false;
    scheduledAt = null;
  }

  static Future<void> signOut() async {
    if (BackendConfig.isConfigured) {
      await PushNotificationService.deactivate();
      await BackendRepository.dispose();
      await AuthService.signOut();
    }
    clearAuthenticatedUser();
    bookings.value = [];
    notifications.value = [];
    adminDrivers.value = [];
    adminTourists.value = [];
    adminFeedbacks.value = [];
    activeBookingId = null;
    activeDriverBookingId = null;
  }

  // ── Admin Specific Methods ────────────────────────────────────────────────

  static final isFilipino = ValueNotifier<bool>(false);

  static final allSpots = ValueNotifier<List<TouristSpotModel>>(
    TouristSpotModel.catalog,
  );

  static final adminDrivers = ValueNotifier<List<Map<String, dynamic>>>([]);

  static final adminTourists = ValueNotifier<List<Map<String, dynamic>>>([]);

  static void approveDriver(String id) {
    if (BackendConfig.isConfigured) {
      // Remote approval requires verified expiry and service-area information
      // and is therefore completed by the admin compliance review screen.
      return;
    }
    adminDrivers.value = adminDrivers.value.map((d) {
      if (d['id'] == id) {
        return {...d, 'status': 'active'};
      }
      return d;
    }).toList();
  }

  static void updateDriverStatus(
    String id,
    String status, {
    String reason = 'Status changed by an administrator.',
    DateTime? blockedUntil,
  }) {
    if (BackendConfig.isConfigured) {
      unawaited(
        BackendRepository.setDriverApproval(
          id,
          status,
          reason: reason,
          blockedUntil: blockedUntil,
        ).then((_) => syncRemoteState()),
      );
      return;
    }
    adminDrivers.value = adminDrivers.value.map((d) {
      if (d['id'] == id) {
        return {...d, 'status': status};
      }
      return d;
    }).toList();
  }

  static void addSystemAnnouncement(String title, String message) {
    if (BackendConfig.isConfigured) {
      unawaited(
        BackendRepository.sendAnnouncement(
          title,
          message,
        ).then((_) => syncRemoteState()),
      );
      return;
    }
    _addNotification(
      NotificationItem(
        id: 'a${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        subtitle: message,
        time: DateTime.now(),
        type: NotificationType.system,
      ),
    );
  }

  static void toggleTouristStatus(String id) {
    if (BackendConfig.isConfigured) {
      final current = adminTourists.value
          .where((u) => u['id'] == id)
          .firstOrNull;
      if (current != null) {
        final status = current['status'] == 'active' ? 'suspended' : 'active';
        unawaited(
          BackendRepository.setTouristStatus(
            id,
            status,
          ).then((_) => syncRemoteState()),
        );
      }
      return;
    }
    adminTourists.value = adminTourists.value.map((u) {
      if (u['id'] == id) {
        return {
          ...u,
          'status': u['status'] == 'active' ? 'suspended' : 'active',
        };
      }
      return u;
    }).toList();
  }

  static void addOrUpdateSpot(TouristSpotModel spot) {
    final exists = allSpots.value.any((s) => s.id == spot.id);
    if (exists) {
      allSpots.value = allSpots.value
          .map((s) => s.id == spot.id ? spot : s)
          .toList();
    } else {
      allSpots.value = [...allSpots.value, spot];
    }
  }

  static void deleteSpot(String spotId) {
    TripRules.require(
      !TourPackageModel.catalog.any((p) => p.spotIds.contains(spotId)),
      'This attraction belongs to a tour package. Hide it instead of deleting it.',
    );
    TripRules.require(
      !bookings.value.any(
        (b) => b.isActive && b.stops.any((s) => s.spotId == spotId),
      ),
      'This attraction is in an active booking. Hide it for new trips instead.',
    );
    if (BackendConfig.isConfigured) {
      unawaited(
        BackendRepository.deleteSpot(spotId).then((_) => syncRemoteState()),
      );
      return;
    }
    allSpots.value = allSpots.value.where((s) => s.id != spotId).toList();
  }
}
