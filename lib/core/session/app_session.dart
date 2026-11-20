import 'booking_draft.dart';
import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import '../l10n/locale_controller.dart';
import '../services/error_messages.dart';
import '../services/section_refresh.dart';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/trip_record.dart';
import '../services/fare_policy.dart';
import '../services/cancellation_policy.dart';
import '../services/trip_rules.dart';
import '../services/backend_repository.dart';
import '../services/realtime_refresh_policy.dart';
import '../config/backend_config.dart';
import '../services/auth_service.dart';
import '../services/push_notification_service.dart';
import '../services/active_trip_tracking_service.dart';
import '../services/session_termination_coordinator.dart';
import '../services/telemetry_service.dart';
import '../state/offline_state_store.dart';
import '../state/feature_controllers.dart';
import '../../models/tourist_spot_model.dart';
import '../../models/booking_model.dart';
import '../../models/notification_item.dart';

export '../../models/notification_item.dart';

// ---------------------------------------------------------------------------
// Application session
// ---------------------------------------------------------------------------

/// Local app state with persisted bookings and fare policies.
/// Cross-device synchronization and trusted authorization need a backend.
class AppSession {
  AppSession._();

  static final itinerary = AppFeatureControllers.catalog.itinerary;
  static final favorites = AppFeatureControllers.catalog.favorites;

  static final bookings = AppFeatureControllers.booking.bookings;
  static final notifications = AppFeatureControllers.booking.notifications;
  static final currentUserName = AppFeatureControllers.auth.currentUserName;
  static final authRevision = AppFeatureControllers.auth.revision;
  static final _currentAccount =
      ValueNotifier<({String id, String name, String email})?>(null);
  static ValueListenable<({String id, String name, String email})?>
  get currentAccount => _currentAccount;
  static String? authenticatedUserId;
  static String? authenticatedRole;

  static String? activeBookingId;
  static String? activePackageId;
  static final userLatitude = AppFeatureControllers.booking.userLatitude;
  static final userLongitude = AppFeatureControllers.booking.userLongitude;
  static final adminFeedbacks = AppFeatureControllers.admin.feedback;
  static final adminCapabilities = AppFeatureControllers.admin.capabilities;
  static final operationalAlerts =
      AppFeatureControllers.admin.operationalAlerts;
  static final focusedSpotId = AppFeatureControllers.catalog.focusedSpotId;

  // ── Booking draft ─────────────────────────────────────────────────────
  static final draft = BookingDraft(
    AppFeatureControllers.booking.customPickupAddress,
  );

  // ── Fare ────────────────────────────────────────────────────────────────

  static final farePolicy = AppFeatureControllers.booking.farePolicy;
  static final cancellationPolicy =
      AppFeatureControllers.booking.cancellationPolicy;
  static double get estimatedFare => itinerary.value.isEmpty
      ? 0
      : farePolicy.value.quote(activePackageId) / 100;
  static double packageFare(TourPackageModel package) =>
      farePolicy.value.quote(package.id) / 100;

  // ── Active Package ───────────────────────────────────────────────────────

  static final tourPackages = ValueNotifier<List<TourPackageModel>>(
    BackendConfig.isConfigured ? const [] : TourPackageModel.catalog,
  );

  static TourPackageModel? get activePackage {
    final id = activePackageId;
    if (id == null) return null;
    for (final package in tourPackages.value) {
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
              MessageCode.aPackageStopIsUnavailablePleaseChooseAnotherRoute,
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
        MessageCode.isTemporarilyClosedAndCannotBeAddedRightNow(spot.name),
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
  static final storageError = AppFeatureControllers.auth.storageError;
  static Future<void> _queue = Future.value();
  static Future<void>? _syncInFlight;
  static final _pendingSections = <RemoteSection>{};
  static int _sessionGeneration = 0;
  static String? _subscribedUserId;
  static const _legacyStorageKey = 'tric_gabay_transactions_v1';
  static bool _languagePersistenceAttached = false;
  static bool _syncingLanguage = false;

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await LocaleController.initialize(prefs);
      _syncingLanguage = true;
      isFilipino.value = LocaleController.effectiveLocale.languageCode == 'fil';
      _syncingLanguage = false;
      if (!_languagePersistenceAttached) {
        _languagePersistenceAttached = true;
        isFilipino.addListener(() {
          if (!_syncingLanguage) {
            unawaited(
              LocaleController.choose(
                isFilipino.value ? AppLanguage.filipino : AppLanguage.english,
              ),
            );
          }
        });
        LocaleController.revision.addListener(() {
          _syncingLanguage = true;
          isFilipino.value =
              LocaleController.effectiveLocale.languageCode == 'fil';
          _syncingLanguage = false;
        });
      }
      await OfflineStateStore.initialize();
      if (BackendConfig.isConfigured) {
        allSpots.value = [];
        tourPackages.value = [];
        bookings.value = [];
        activeBookingId = null;
        activeDriverBookingId = null;
        storageError.value = null;
        return;
      }
      // Older builds kept a simulated booking ledger on the device; it is no
      // longer used, so drop it.
      unawaited(prefs.remove(_legacyStorageKey));
      _restoreActiveIds();
      storageError.value = null;
    } catch (_) {
      storageError.value = MessageCode
          .savedTripDataCouldNotBeReadBookingChangesArePausedToProtect;
    }
  }

  static final hasMoreBookings = ValueNotifier<bool>(false);
  static final hasMoreDirectory = ValueNotifier<bool>(false);
  static final loadingMoreBookings = ValueNotifier<bool>(false);
  static final loadingMoreDirectory = ValueNotifier<bool>(false);
  static final loadingSections = ValueNotifier<Set<RemoteSection>>(const {});
  static int _bookingWindowPage = 0, _directoryWindowPage = 0;
  static int _loadedBookingPage = 0, _loadedDirectoryPage = 0;
  static Future<List<BookingModel>> _readBookingWindow() async {
    final generation = _sessionGeneration, page = _bookingWindowPage;
    final result = await BackendRepository.loadBookingWindow(
      throughPage: page,
      viewerRole: authenticatedRole,
    );
    if (generation == _sessionGeneration) {
      hasMoreBookings.value = result.hasMore;
      _loadedBookingPage = page;
    }
    return result.items;
  }

  static Future<
    ({List<Map<String, dynamic>> drivers, List<Map<String, dynamic>> tourists})
  >
  _readDirectoryWindow() async {
    final generation = _sessionGeneration, page = _directoryWindowPage;
    final result = await BackendRepository.loadDirectoryWindow(
      throughPage: page,
    );
    if (generation == _sessionGeneration) {
      hasMoreDirectory.value = result.hasMore;
      _loadedDirectoryPage = page;
    }
    return (drivers: result.drivers, tourists: result.tourists);
  }

  static Future<void> loadMore({required bool directory}) async {
    final busy = directory ? loadingMoreDirectory : loadingMoreBookings;
    if (busy.value ||
        !(directory ? hasMoreDirectory.value : hasMoreBookings.value)) {
      return;
    }
    final generation = _sessionGeneration;
    busy.value = true;
    if (directory) {
      _directoryWindowPage++;
    } else {
      _bookingWindowPage++;
    }
    try {
      await syncRemoteState(
        sections: {
          directory ? RemoteSection.directory : RemoteSection.bookings,
        },
      );
    } finally {
      if (generation == _sessionGeneration) {
        _directoryWindowPage = _loadedDirectoryPage;
        _bookingWindowPage = _loadedBookingPage;
        busy.value = false;
      }
    }
  }

  static Future<void> syncRemoteState({Set<RemoteSection>? sections}) {
    if (!BackendConfig.isConfigured || authenticatedUserId == null) {
      return Future.value();
    }
    _pendingSections.addAll(sections ?? RemoteSection.values);
    final existing = _syncInFlight;
    if (existing != null) {
      return existing;
    }
    final completer = Completer<void>();
    _syncInFlight = completer.future;
    unawaited(_runSyncLoop(completer));
    return completer.future;
  }

  static Future<void> _runSyncLoop(Completer<void> completer) async {
    try {
      do {
        final sections = Set<RemoteSection>.of(_pendingSections);
        _pendingSections.clear();
        loadingSections.value = Set.unmodifiable({
          ...sections,
          if (sections.contains(RemoteSection.bookings))
            RemoteSection.directory,
        });
        final trace = TimelineTask()..start('refresh_app_data');
        try {
          await _syncRemoteStateOnce(sections);
        } finally {
          trace.finish();
        }
      } while (_pendingSections.isNotEmpty && authenticatedUserId != null);
      completer.complete();
    } catch (error, stackTrace) {
      if (!completer.isCompleted) completer.completeError(error, stackTrace);
    } finally {
      _syncInFlight = null;
      loadingSections.value = const {};
    }
  }

  static Future<void> _syncRemoteStateOnce(Set<RemoteSection> sections) async {
    final userId = authenticatedUserId;
    final role = authenticatedRole;
    final generation = _sessionGeneration;
    if (userId == null) return;
    try {
      // Revalidate mutable account state on every authoritative refresh. A
      // long-lived access token must not preserve app access after a profile
      // suspension or driver-approval revocation.
      if (!await refreshAccountAccess()) return;
      if (generation != _sessionGeneration || userId != authenticatedUserId) {
        return;
      }
      final failures = <RemoteSection>{};
      Future<T> readSection<T>(
        RemoteSection section,
        Future<T> Function() load,
        T previous,
      ) => refreshSection(load, previous, (error, stack) {
        failures.add(section);
        ErrorMessages.forError(error);
      });
      final results = await Future.wait([
        sections.contains(RemoteSection.fares)
            ? readSection(
                RemoteSection.fares,
                BackendRepository.loadFarePolicy,
                farePolicy.value,
              )
            : Future.value(farePolicy.value),
        sections.contains(RemoteSection.cancellationPolicy)
            ? readSection(
                RemoteSection.cancellationPolicy,
                BackendRepository.loadCancellationPolicy,
                cancellationPolicy.value,
              )
            : Future.value(cancellationPolicy.value),
        sections.contains(RemoteSection.spots)
            ? readSection(
                RemoteSection.spots,
                () => BackendRepository.loadSpots(
                  includeInactive: role == 'admin',
                ),
                allSpots.value,
              )
            : Future.value(allSpots.value),
        sections.contains(RemoteSection.bookings)
            ? readSection(
                RemoteSection.bookings,
                _readBookingWindow,
                bookings.value,
              )
            : Future.value(bookings.value),
        sections.contains(RemoteSection.directory) ||
                sections.contains(RemoteSection.bookings)
            ? readSection(RemoteSection.directory, _readDirectoryWindow, (
                drivers: adminDrivers.value,
                tourists: adminTourists.value,
              ))
            : Future.value((
                drivers: adminDrivers.value,
                tourists: adminTourists.value,
              )),
        sections.contains(RemoteSection.notifications)
            ? readSection(
                RemoteSection.notifications,
                BackendRepository.loadNotifications,
                <Map<String, dynamic>>[],
              )
            : Future.value(<Map<String, dynamic>>[]),
        if (role == 'admin')
          sections.contains(RemoteSection.feedback)
              ? readSection(
                  RemoteSection.feedback,
                  BackendRepository.loadFeedback,
                  adminFeedbacks.value,
                )
              : Future.value(adminFeedbacks.value)
        else
          Future.value(<Map<String, dynamic>>[]),
        if (role == 'admin')
          sections.contains(RemoteSection.capabilities)
              ? readSection(
                  RemoteSection.capabilities,
                  BackendRepository.loadAdminCapabilities,
                  adminCapabilities.value,
                )
              : Future.value(adminCapabilities.value)
        else
          Future.value(<String>{}),
        if (role == 'admin')
          sections.contains(RemoteSection.alerts)
              ? readSection(
                  RemoteSection.alerts,
                  BackendRepository.loadOperationalAlerts,
                  operationalAlerts.value,
                )
              : Future.value(operationalAlerts.value)
        else
          Future.value(<Map<String, dynamic>>[]),
        sections.contains(RemoteSection.spots) && role != 'driver'
            ? readSection(
                RemoteSection.spots,
                BackendRepository.loadTourPackages,
                tourPackages.value,
              )
            : Future.value(tourPackages.value),
      ]);
      if (generation != _sessionGeneration ||
          userId != authenticatedUserId ||
          userId != BackendConfig.client.auth.currentUser?.id) {
        return;
      }
      if (sections.contains(RemoteSection.fares)) {
        farePolicy.value = results[0] as FarePolicy;
      }
      if (sections.contains(RemoteSection.cancellationPolicy)) {
        cancellationPolicy.value = results[1] as CancellationPolicy;
      }
      if (sections.contains(RemoteSection.spots)) {
        allSpots.value = results[2] as List<TouristSpotModel>;
        tourPackages.value = results[9] as List<TourPackageModel>;
      }
      if (sections.contains(RemoteSection.bookings)) {
        bookings.value = results[3] as List<BookingModel>;
      }
      final directory =
          results[4]
              as ({
                List<Map<String, dynamic>> drivers,
                List<Map<String, dynamic>> tourists,
              });
      if (sections.contains(RemoteSection.directory) ||
          sections.contains(RemoteSection.bookings)) {
        adminDrivers.value = directory.drivers;
        adminTourists.value = directory.tourists;
      }
      final remoteNotifications = results[5] as List<Map<String, dynamic>>;
      if (sections.contains(RemoteSection.notifications) &&
          !failures.contains(RemoteSection.notifications)) {
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
      }
      if (sections.contains(RemoteSection.feedback)) {
        adminFeedbacks.value = results[6] as List<Map<String, dynamic>>;
      }
      if (sections.contains(RemoteSection.capabilities)) {
        adminCapabilities.value = results[7] as Set<String>;
      }
      if (sections.contains(RemoteSection.alerts)) {
        operationalAlerts.value = results[8] as List<Map<String, dynamic>>;
      }
      if (role == 'driver') {
        final ownDriver = directory.drivers
            .where((driver) => driver['id'] == userId)
            .firstOrNull;
        isDriverOnline.value = ownDriver?['isOnline'] == true;
      }
      _restoreActiveIds();
      if (role == 'driver' &&
          sections.contains(RemoteSection.bookings) &&
          !failures.contains(RemoteSection.bookings)) {
        final active = bookings.value
            .where(
              (booking) =>
                  booking.id == activeDriverBookingId &&
                  (booking.status == BookingStatus.accepted ||
                      booking.status == BookingStatus.ongoing),
            )
            .firstOrNull;
        if (active == null) {
          await ActiveTripTrackingService.reconcileAuthoritativeBooking(null);
        } else {
          await ActiveTripTrackingService.reconcileAuthoritativeBooking(
            active.id,
          );
        }
      }
      if (role == 'tourist' &&
          sections.contains(RemoteSection.bookings) &&
          !failures.contains(RemoteSection.bookings)) {
        final retained = bookings.value
            .where((booking) => booking.touristId == userId && booking.isActive)
            .map((booking) => booking.id)
            .toSet();
        await BackendRepository.purgePickupCodes(
          userId: userId,
          retained: retained,
        );
      }
      storageError.value = failures.isEmpty
          ? null
          : MessageCode
                .someInformationCouldNotRefreshPreviouslyLoadedDataIsShownReconnectAndRetry;
      if (_subscribedUserId != userId) {
        _subscribedUserId = userId;
        BackendRepository.subscribe(
          (sections) {
            if (generation != _sessionGeneration ||
                userId != authenticatedUserId) {
              return;
            }
            unawaited(
              syncRemoteState(sections: sections).catchError((Object _) {
                // storageError exposes the retryable failure.
              }),
            );
          },
          onLocation: (row) {
            if (generation != _sessionGeneration ||
                userId != authenticatedUserId) {
              return;
            }
            adminDrivers.value = patchDriverLocation(adminDrivers.value, row);
          },
        );
      }
      await OfflineStateStore.saveSnapshot(
        userId: userId,
        bookings: bookings.value,
        spots: allSpots.value,
        farePolicy: farePolicy.value,
        cancellationPolicy: cancellationPolicy.value,
      );
      await OfflineStateStore.replay(userId, (command) async {
        switch (command.type) {
          case 'notification_read':
            await BackendRepository.markNotificationRead(
              command.payload['notification_id'] as String,
            );
            return;
          case 'notifications_read_all':
            await BackendRepository.markAllNotificationsRead();
            return;
          default:
            throw StateError(MessageCode.unsupportedOfflineCommand);
        }
      });
    } catch (error) {
      if (generation == _sessionGeneration && userId == authenticatedUserId) {
        final cached = await OfflineStateStore.restoreSnapshot(userId);
        if (cached != null && !cached.isStale && bookings.value.isEmpty) {
          bookings.value = cached.bookings;
          allSpots.value = cached.spots;
          farePolicy.value = cached.farePolicy;
          cancellationPolicy.value = cached.cancellationPolicy;
          _restoreActiveIds();
          storageError.value =
              MessageCode.offlineModeShowingSavedDataFromCriticalActionsRequireAConnectionValue(
                (cached.savedAt).toString(),
              );
        } else {
          storageError.value = MessageCode
              .couldNotSynchronizeWithTheServerCheckYourConnectionAndRetry;
        }
      }
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

  static Future<void> saveFares({
    required int customCents,
    required Map<String, int> packages,
    required int expectedRevision,
    String reason = MessageCode.administratorUpdatedFixedFares,
  }) => _serial(() async {
    final old = farePolicy.value;
    TripRules.require(
      old.revision == expectedRevision,
      MessageCode
          .pricesChangedWhileYouWereEditingReopenThisPageAndReviewTheLatest,
    );
    TripRules.require(
      customCents > 0 &&
          customCents <= 10000000 &&
          packages.values.every((v) => v > 0 && v <= 10000000) &&
          tourPackages.value.every((p) => packages.containsKey(p.id)),
      MessageCode.enterValidFixedFaresForEveryRoute,
    );
    _requireServer();
    await BackendRepository.saveFares(
      customCents: customCents,
      packageFares: packages,
      reason: reason.trim(),
    );
    await syncRemoteState();
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
      MessageCode.aConfiguredServerAndAdministratorAccountAreRequired,
    );
    TripRules.require(
      cancellationPolicy.value.version == expectedVersion,
      MessageCode.thePolicyChangedWhileYouWereEditingReopenThisPage,
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
      paymentMethod == PaymentMethod.cash ||
          paymentMethod == PaymentMethod.gcashDirect,
      MessageCode.onlinePaymentUnavailable,
    );
    TripRules.require(
      !bookings.value.any((b) => b.touristId == currentTouristId && b.isActive),
      MessageCode.youAlreadyHaveAnActiveBookingOpenTripsToContinueOrCancelIt,
    );
    TripRules.require(
      farePolicy.value.revision == expectedFareRevision,
      MessageCode.thePriceChangedReviewTheUpdatedFareAndConfirmAgain,
    );
    final spots = List<TouristSpotModel>.from(itinerary.value);
    TripRules.require(
      spots.isNotEmpty && spots.length <= 12,
      MessageCode.selectBetween1And12Destinations,
    );
    TripRules.require(
      spots.map((s) => s.id).toSet().length == spots.length,
      MessageCode.removeDuplicateDestinations,
    );
    TripRules.require(
      spots.every(
        (s) => allSpots.value.any(
          (live) =>
              live.id == s.id && live.isActive && !live.isTemporarilyClosed,
        ),
      ),
      MessageCode.aDestinationIsNoLongerAvailableUpdateYourItinerary,
    );
    final lat = draft.pickupLat ?? userLatitude.value;
    final lng = draft.pickupLng ?? userLongitude.value;
    TripRules.require(
      lat != null &&
          lng != null &&
          lat.isFinite &&
          lng.isFinite &&
          lat >= -90 &&
          lat <= 90 &&
          lng >= -180 &&
          lng <= 180,
      MessageCode.chooseAPickupPointOnTheMapOrEnableLocationFirst,
    );
    final pkg = activePackage;
    if (pkg != null) {
      TripRules.require(
        listEquals(pkg.spotIds, spots.map((s) => s.id).toList()),
        MessageCode.packageStopsChangedSelectThePackageAgain,
      );
    }
    _requireServer();
    final serviceArea = await BackendRepository.loadPickupServiceArea();
    TripRules.require(
      serviceArea.contains(lat!, lng!),
      MessageCode.thePickupPinIsOutsideTheServiceAreaChooseANearbyPickupPoint,
    );
    final created = await BackendRepository.createBooking(
      packageId: activePackageId,
      paymentMethod: paymentMethod,
      pickupAddress: draft.pickupAddress.value ?? MessageCode.currentGpsPickup,
      pickupLatitude: lat,
      pickupLongitude: lng,
      stops: spots,
      passengerCount: draft.passengerCount,
      luggageNotes: draft.luggageNotes,
      accessibilityNeeds: draft.accessibilityNeeds,
      scheduledAt: draft.scheduledAt,
    );
    await syncRemoteState();
    activeBookingId = created.booking.id;
    return created.booking;
  });

  static BookingModel bookingById(String id) {
    final b = bookings.value.where((b) => b.id == id).firstOrNull;
    TripRules.require(b != null, MessageCode.thisBookingCouldNotBeFound);
    return b!;
  }

  static String? get currentDriverId =>
      authenticatedRole == 'driver' ? authenticatedUserId : null;
  static bool ownsDriverBooking(BookingModel b) =>
      currentDriverId != null && b.driverId == currentDriverId;

  /// Every trip and admin action is decided by the server; there is no
  /// offline simulation of booking rules in the app.
  static void _requireServer() => TripRules.require(
    BackendConfig.isConfigured,
    MessageCode.serverConnectionRequired,
  );

  static Future<BookingModel> cancelBooking(
    String id, {
    required TripActor actor,
    required String reason,
  }) async {
    _requireServer();
    await BackendRepository.rpc('cancel_booking', {
      'p_booking_id': id,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> retryDriverSearch(String id) async {
    _requireServer();
    await BackendRepository.rpc('retry_booking_dispatch', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<void> declineDriverOffer(String id) async {
    TripRules.require(
      BackendConfig.isConfigured,
      MessageCode.decliningMatchedOffersRequiresTheConfiguredServer,
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
      MessageCode.driverReplacementRequiresTheConfiguredServer,
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
      MessageCode.driverReplacementRequiresTheConfiguredServer,
    );
    await BackendRepository.rpc('decide_driver_replacement', {
      'p_booking_id': id,
      'p_find_replacement': findReplacement,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> reportPickupArrival(String id) async {
    _requireServer();
    await BackendRepository.rpc('report_pickup_arrival', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> declareTouristNoShow(String id) async {
    _requireServer();
    await BackendRepository.rpc('declare_tourist_no_show', {
      'p_booking_id': id,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> startTrip(String id, String code) async {
    _requireServer();
    await BackendRepository.rpc('start_trip', {
      'p_booking_id': id,
      'p_pickup_code': code,
    });
    await syncRemoteState();
    final booking = bookingById(id);
    if (booking.status != BookingStatus.ongoing) {
      throw StateError(
        MessageCode
            .thatPickupCodeIsIncorrectOrTemporarilyLockedAfterRepeatedAttempts,
      );
    }
    return booking;
  }

  static Future<BookingModel> reportArrival(String id) async {
    _requireServer();
    await BackendRepository.rpc('report_stop_arrival', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> confirmArrival(String id) async {
    _requireServer();
    await BackendRepository.rpc('confirm_stop_arrival', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
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
      MessageCode.auditedRouteChangesRequireTheConfiguredServer,
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
    _requireServer();
    await BackendRepository.rpc('complete_trip', {'p_booking_id': id});
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> disputeBooking(
    String id,
    TripActor actor,
    String reason,
  ) async {
    _requireServer();
    await BackendRepository.rpc('open_dispute', {
      'p_booking_id': id,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> addCaseStatement(
    String id,
    TripActor actor,
    String text,
  ) async {
    _requireServer();
    await BackendRepository.rpc('add_dispute_statement', {
      'p_booking_id': id,
      'p_statement': text,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> resolveSettlement(
    String id,
    int cents,
    String reason,
  ) async {
    _requireServer();
    await BackendRepository.rpc('resolve_booking_charge', {
      'p_booking_id': id,
      'p_charge_centavos': cents,
      'p_reason': reason,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<BookingModel> confirmCash(
    String id,
    TripActor actor, {
    bool refund = false,
  }) async {
    _requireServer();
    await BackendRepository.rpc('confirm_cash', {
      'p_booking_id': id,
      'p_direction': refund ? 'refund' : 'payment',
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static Future<List<Map<String, dynamic>>> financialLedger(String id) {
    TripRules.require(
      BackendConfig.isConfigured,
      MessageCode.theFinancialRecordRequiresTheConfiguredServer,
    );
    return BackendRepository.loadFinancialLedger(id);
  }

  static Future<BookingModel> markBookingRated(
    String id,
    double rating, {
    String review = '',
  }) async {
    _requireServer();
    await BackendRepository.rpc('submit_driver_review', {
      'p_booking_id': id,
      'p_rating': rating.round(),
      'p_review': review,
    });
    await syncRemoteState();
    return bookingById(id);
  }

  static final isDriverOnline = AppFeatureControllers.driver.isOnline;
  static final currentDriverName = AppFeatureControllers.driver.currentName;
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
    return _serial(() async {
      _requireServer();
      await BackendRepository.rpc('accept_booking', {'p_booking_id': id});
      await syncRemoteState();
      return bookingById(id);
    });
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  static void markAllNotificationsRead() {
    if (BackendConfig.isConfigured) {
      for (final notification in notifications.value) {
        notification.isRead = true;
      }
      notifications.value = [...notifications.value];
      final userId = authenticatedUserId;
      final generation = _sessionGeneration;
      unawaited(
        BackendRepository.markAllNotificationsRead()
            .then((_) {
              if (userId == authenticatedUserId &&
                  generation == _sessionGeneration) {
                return syncRemoteState(sections: {RemoteSection.notifications});
              }
            })
            .catchError((Object _) async {
              if (userId != null &&
                  userId == authenticatedUserId &&
                  generation == _sessionGeneration) {
                await OfflineStateStore.enqueue(
                  userId: userId,
                  id: 'notifications_read_all',
                  type: 'notifications_read_all',
                );
              }
            }),
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
      for (final notification in notifications.value) {
        if (notification.id == id) notification.isRead = true;
      }
      notifications.value = [...notifications.value];
      final userId = authenticatedUserId;
      final generation = _sessionGeneration;
      unawaited(
        BackendRepository.markNotificationRead(id)
            .then((_) {
              if (userId == authenticatedUserId &&
                  generation == _sessionGeneration) {
                return syncRemoteState(sections: {RemoteSection.notifications});
              }
            })
            .catchError((Object _) async {
              if (userId != null &&
                  userId == authenticatedUserId &&
                  generation == _sessionGeneration) {
                await OfflineStateStore.enqueue(
                  userId: userId,
                  id: 'notification_read:$id',
                  type: 'notification_read',
                  payload: {'notification_id': id},
                );
              }
            }),
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

  // ── User Profile ──────────────────────────────────────────────────────────

  static void updateAccountName(String name) {
    final account = _currentAccount.value;
    if (account == null || account.id != authenticatedUserId) return;
    _setAccountIdentity(account.id, name, account.email);
  }

  static void _setAccountIdentity(String id, String name, String email) {
    _currentAccount.value = (id: id, name: name, email: email);
    if (authenticatedRole == 'driver') {
      currentDriverName.value = name;
    } else if (authenticatedRole == 'tourist') {
      currentUserName.value = name;
    }
  }

  static void setAuthenticatedUser({
    required String id,
    required String name,
    required String role,
    required String email,
    String? plateNumber,
  }) {
    if (authenticatedUserId != id || authenticatedRole != role) {
      _sessionGeneration++;
      _subscribedUserId = null;
      _pendingSections.clear();
      _bookingWindowPage = 0;
      _directoryWindowPage = 0;
      _loadedBookingPage = 0;
      _loadedDirectoryPage = 0;
      hasMoreBookings.value = false;
      hasMoreDirectory.value = false;
      loadingMoreBookings.value = false;
      loadingMoreDirectory.value = false;
      // The unconfigured in-memory adapter is retained only for isolated unit
      // tests. Real builds always clear the previous account before applying
      // another user's state.
      if (BackendConfig.isConfigured || authenticatedUserId == id) {
        _clearUserScopedState();
      }
    }
    authenticatedUserId = id;
    authenticatedRole = role;
    _setAccountIdentity(id, name, email);
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
    authRevision.value++;
    unawaited(PushNotificationService.refreshRegistration());
  }

  static void clearAuthenticatedUser() {
    _sessionGeneration++;
    _subscribedUserId = null;
    authenticatedUserId = null;
    authenticatedRole = null;
    _clearUserScopedState();
    // Optional collection from the departing account must not carry into the
    // next account's sign-in or first privacy notice.
    unawaited(TelemetryService.setConsent(false).catchError((Object _) {}));
    authRevision.value++;
  }

  static Future<void> handleSessionEnded() async {
    final departingUserId = authenticatedUserId;
    clearAuthenticatedUser();
    await Future.wait([
      _disconnectSessionServices(),
      if (departingUserId != null) OfflineStateStore.clearUser(departingUserId),
    ]);
  }

  static Future<void> _disconnectSessionServices() async {
    Future<void> attempt(Future<void> action) async {
      try {
        await action;
      } catch (_) {
        /* Local state is already cleared. */
      }
    }

    await Future.wait([
      attempt(PushNotificationService.deactivate()),
      attempt(BackendRepository.dispose()),
    ]);
  }

  /// Refresh the account's effective app role before loading role-scoped data.
  /// A result for a departed session must never alter the new account.
  static Future<bool> refreshAccountAccess({
    Future<SignedInProfile?> Function()? load,
  }) async {
    final userId = authenticatedUserId;
    final generation = _sessionGeneration;
    if (userId == null) return false;
    final profile = await (load ?? AuthService.restoreSession)();
    if (generation != _sessionGeneration || userId != authenticatedUserId) {
      return false;
    }
    if (profile == null || profile.id != userId) {
      await handleSessionEnded();
      return false;
    }
    final role = profile.applicationPending
        ? 'driver_pending'
        : profile.role.name;
    if (role != authenticatedRole) {
      setAuthenticatedUser(
        id: profile.id,
        name: profile.name,
        role: role,
        email: profile.email,
        plateNumber: profile.plateNumber,
      );
      if (role != 'driver_pending') {
        _pendingSections.addAll(RemoteSection.values);
      }
      return false;
    }
    _setAccountIdentity(profile.id, profile.name, profile.email);
    return role != 'driver_pending';
  }

  static void _clearUserScopedState() {
    loadingSections.value = const {};
    _bookingWindowPage = 0;
    _directoryWindowPage = 0;
    _loadedBookingPage = 0;
    _loadedDirectoryPage = 0;
    hasMoreBookings.value = false;
    hasMoreDirectory.value = false;
    loadingMoreBookings.value = false;
    loadingMoreDirectory.value = false;
    unawaited(ActiveTripTrackingService.stop());
    _currentAccount.value = null;
    currentUserName.value = '';
    currentDriverName.value = '';
    isDriverOnline.value = false;
    bookings.value = [];
    notifications.value = [];
    adminDrivers.value = [];
    adminTourists.value = [];
    adminFeedbacks.value = [];
    adminCapabilities.value = {};
    operationalAlerts.value = [];
    favorites.value = {};
    itinerary.value = [];
    activePackageId = null;
    activeBookingId = null;
    activeDriverBookingId = null;
    draft.clear();
    userLatitude.value = null;
    userLongitude.value = null;
    focusedSpotId.value = null;
  }

  static Future<void> signOut() async {
    final departingUserId = authenticatedUserId;
    if (BackendConfig.isConfigured) {
      await SessionTerminationCoordinator(
        clearLocal: () async {
          clearAuthenticatedUser();
          if (departingUserId != null) {
            await OfflineStateStore.clearUser(departingUserId);
          }
        },
        disconnect: _disconnectSessionServices,
        remoteSignOut: AuthService.signOut,
      ).terminate();
      return;
    }
    clearAuthenticatedUser();
    if (departingUserId != null) {
      await OfflineStateStore.clearUser(departingUserId);
    }
  }

  // ── Admin Specific Methods ────────────────────────────────────────────────

  static final isFilipino = AppFeatureControllers.preferences.isFilipino;

  static final allSpots = AppFeatureControllers.catalog.spots;

  static final adminDrivers = AppFeatureControllers.admin.drivers;

  static final adminTourists = AppFeatureControllers.admin.tourists;

  static bool hasAdminCapability(String capability) =>
      adminCapabilities.value.contains('super_admin') ||
      adminCapabilities.value.contains(capability);

  static Future<void> updateDriverStatus(
    String id,
    String status, {
    required String reason,
    DateTime? blockedUntil,
  }) async {
    TripRules.require(
      reason.trim().length >= 5,
      MessageCode.enterAReasonOfAtLeastFiveCharacters,
    );
    _requireServer();
    await BackendRepository.setDriverApproval(
      id,
      status,
      reason: reason,
      blockedUntil: blockedUntil,
    );
    await syncRemoteState();
    return;
  }

  static Future<void> addSystemAnnouncement(
    String title,
    String message, {
    required String audience,
    required String requestId,
  }) async {
    _requireServer();
    await BackendRepository.sendAnnouncement(
      title,
      message,
      audience: audience,
      requestId: requestId,
    );
    await syncRemoteState();
    return;
  }

  static Future<void> toggleTouristStatus(
    String id, {
    required String reason,
  }) async {
    TripRules.require(
      reason.trim().length >= 5,
      MessageCode.enterAReasonOfAtLeastFiveCharacters,
    );
    _requireServer();
    final current = adminTourists.value.where((u) => u['id'] == id).firstOrNull;
    if (current != null) {
      final status = current['status'] == 'active' ? 'suspended' : 'active';
      await BackendRepository.setTouristStatus(id, status, reason: reason);
      await syncRemoteState();
    }
    return;
  }

  static Future<void> deleteSpot(String spotId) async {
    TripRules.require(
      !tourPackages.value.any((p) => p.spotIds.contains(spotId)),
      MessageCode.thisAttractionBelongsToATourPackageHideItInsteadOfDeletingIt,
    );
    TripRules.require(
      !bookings.value.any(
        (b) => b.isActive && b.stops.any((s) => s.spotId == spotId),
      ),
      MessageCode.thisAttractionIsInAnActiveBookingHideItForNewTripsInstead,
    );
    _requireServer();
    await BackendRepository.deleteSpot(spotId);
    return;
  }
}
