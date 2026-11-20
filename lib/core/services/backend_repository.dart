import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'spot_image_material.dart';
import 'remote_pagination.dart';
import 'section_refresh.dart';
import 'dart:async';
import 'booking_request_material.dart';
import 'pickup_service_area.dart';
import '../utils/validators.dart';
import 'dart:typed_data';
import 'realtime_refresh_policy.dart';
import 'location_upload_gate.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pickup_recovery_material.dart';

import '../../models/booking_model.dart';
import '../../models/tourist_spot_model.dart';
import '../../models/trip_record.dart';
import '../config/backend_config.dart';
import '../utils/map_coordinate_validator.dart';
import 'fare_policy.dart';
import 'cancellation_policy.dart';
import 'avatar_replacement_service.dart';
import 'telemetry_service.dart';

class BookingCreationResult {
  final BookingModel booking;
  final String pickupCode;
  const BookingCreationResult(this.booking, this.pickupCode);
}

class DataPage<T> {
  final List<T> items;
  final int page;
  final int pageSize;
  final bool hasMore;

  const DataPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

class BackendRepository {
  BackendRepository._();

  static const _secureStorage = FlutterSecureStorage();
  static const _readDeadline = Duration(seconds: 12);
  static SupabaseClient get _client => BackendConfig.client;
  static RealtimeChannel? _channel;
  static Timer? _refreshDebounce;
  static final _driverRecords = <String, Map<String, dynamic>>{};

  static const _activeBookingStatuses = [
    'payment_pending',
    'scheduled',
    'pending',
    'accepted',
    'replacement_pending',
    'ongoing',
  ];

  static Future<FarePolicy> loadFarePolicy() async {
    final row = await _client
        .from('fare_revisions')
        .select('revision,custom_fare_centavos,package_fares,reason,created_at')
        .eq('is_current', true)
        .single()
        .timeout(_readDeadline);
    return FarePolicy(
      revision: row['revision'] as int,
      customFareCents: row['custom_fare_centavos'] as int,
      packageFares: Map<String, int>.from(row['package_fares'] as Map),
      history: ['${row['created_at']} • ${row['reason']}'],
    );
  }

  static Future<CancellationPolicy> loadCancellationPolicy() async {
    final row = await _client
        .from('cancellation_policies')
        .select(
          'version,free_cancellation_minutes,accepted_trip_fee_percent,driver_wait_minutes,no_show_fee_percent,terms,created_at,change_reason',
        )
        .eq('is_current', true)
        .single()
        .timeout(_readDeadline);
    return CancellationPolicy(
      version: row['version'] as int,
      freeCancellationMinutes: row['free_cancellation_minutes'] as int,
      acceptedTripFeePercent: row['accepted_trip_fee_percent'] as int,
      driverWaitMinutes: row['driver_wait_minutes'] as int,
      noShowFeePercent: row['no_show_fee_percent'] as int,
      terms: row['terms'] as String,
      history: [
        '${row['created_at']} • ${row['change_reason'] ?? MessageCode.publishedPolicy}',
      ],
    );
  }

  static Future<List<TourPackageModel>> loadTourPackages() async {
    final rows = await _client
        .from('tour_packages')
        .select('id,name,description,tour_package_stops(spot_id,stop_order)')
        .eq('is_active', true)
        .order('id')
        .timeout(_readDeadline);
    return rows.map(TourPackageModel.fromPublishedRow).toList();
  }

  static Future<List<TouristSpotModel>> loadSpots({
    int page = 0,
    int pageSize = 200,
    bool includeInactive = false,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 200).toInt();
    final start = safePage * safeSize;
    var query = _client
        .from('tourist_spots')
        .select(
          'id,name,description,history,category,latitude,longitude,image_url,opening_hours,entrance_fee_note,tips,distance_from_town,is_active,availability_status,closed_until,closure_reason',
        );
    if (!includeInactive) query = query.eq('is_active', true);
    final rows = await query
        .order('name')
        .range(start, start + safeSize - 1)
        .timeout(_readDeadline);
    return rows
        .where((row) {
          return MapCoordinateValidator.isValid(
            latitude: row['latitude'],
            longitude: row['longitude'],
          );
        })
        .map<TouristSpotModel>((map) {
          return TouristSpotModel(
            id: map['id'],
            name: map['name'],
            description: map['description'] ?? '',
            history: map['history'] ?? '',
            category: _category(map['category']),
            latitude: MapCoordinateValidator.finiteNumber(map['latitude'])!,
            longitude: MapCoordinateValidator.finiteNumber(map['longitude'])!,
            imageUrls: map['image_url'] == null || map['image_url'] == ''
                ? const []
                : [map['image_url'] as String],
            openingHours: map['opening_hours'] ?? '',
            entranceFee: map['entrance_fee_note'] ?? '',
            tips: List<String>.from(map['tips'] ?? const []),
            distanceFromTown:
                (map['distance_from_town'] as num?)?.toDouble() ?? 0,
            isActive: map['is_active'] ?? true,
            availabilityStatus: map['availability_status'] ?? 'open',
            closedUntil: _date(map['closed_until']),
            closureReason: map['closure_reason'] as String?,
          );
        })
        .toList();
  }

  static SpotCategory _category(String? value) =>
      SpotCategory.values.firstWhere(
        (item) => item.name.toLowerCase() == (value ?? '').toLowerCase(),
        orElse: () => SpotCategory.other,
      );

  static Future<List<BookingModel>> loadBookings({
    int page = 0,
    int pageSize = 200,
    String? bookingId,
    bool activeOnly = false,
  }) async => (await _loadBookingPage(
    page: page,
    pageSize: pageSize,
    bookingId: bookingId,
    activeOnly: activeOnly,
  )).items;

  static Future<({List<BookingModel> items, bool hasMore})> loadBookingWindow({
    int throughPage = 0,
    String? viewerRole,
  }) async {
    final pickupValues = _secureStorage.readAll();
    final historyRequest = readPageWindow<BookingModel>(
      throughPage: throughPage,
      fetch: (page) async {
        final batch = await _loadBookingPage(
          page: page,
          pageSize: 50,
          viewerRole: viewerRole,
          historyOnly: true,
          pickupValues: pickupValues,
        );
        return (items: batch.items, hasMore: batch.hasMore);
      },
    );
    final (history, active) = await (
      historyRequest,
      _loadActiveBookings(viewerRole, pickupValues),
    ).wait;
    final items = {
      for (final booking in history.items) booking.id: booking,
      for (final booking in active) booking.id: booking,
    }.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return (items: items, hasMore: history.hasMore);
  }

  static Future<List<BookingModel>> _loadActiveBookings(
    String? viewerRole,
    Future<Map<String, String>> pickupValues,
  ) async {
    final items = <BookingModel>[];
    for (var page = 0; ; page++) {
      final batch = await _loadBookingPage(
        page: page,
        activeOnly: true,
        viewerRole: viewerRole,
        pickupValues: pickupValues,
      );
      items.addAll(batch.items);
      if (!batch.hasMore) return items;
    }
  }

  static Future<DataPage<BookingModel>> _loadBookingPage({
    int page = 0,
    int pageSize = 200,
    String? bookingId,
    bool activeOnly = false,
    bool historyOnly = false,
    String? viewerRole,
    Future<Map<String, String>>? pickupValues,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 200).toInt();
    final start = safePage * safeSize;
    var query = _client.from('bookings').select('''
    id,tourist_id,driver_id,package_id,quoted_amount_centavos,final_charge_centavos,
    pickup_latitude,pickup_longitude,pickup_address,passenger_count,luggage_notes,
    accessibility_needs,payment_method,payment_status,status,created_at,scheduled_at,
    dispatch_expires_at,accepted_at,started_at,completed_at,replacement_requested_at,
    replacement_reason,route_adjustment_required,interrupted_at,interruption_reason,
    tourist_wait_confirmed_at,last_route_deviation_at,cancellation_reason,driver_arrived_at,
    pickup_wait_expires_at,confirmed_stop_count,arrival_pending,client_request_id,
    tourist:profiles!bookings_tourist_id_fkey(full_name),
    driver:profiles!bookings_driver_id_fkey(full_name,driver_profiles!driver_profiles_profile_id_fkey(plate_number)),
    fare_revisions(revision),
    cancellation_policies(free_cancellation_minutes,accepted_trip_fee_percent,driver_wait_minutes,no_show_fee_percent),
    booking_stops(id,spot_id,spot_name_snapshot,latitude_snapshot,longitude_snapshot,stop_order),
    booking_offers(driver_id,status,expires_at),
    booking_route_changes(id,requested_by,requested_role,change_type,target_stop_id,proposed_order,reason,created_at,status),
    trip_events(created_at,actor_role,description),payments(status,amount_centavos),
    cash_confirmations(direction,actor_role),booking_reviews(rating,review)
  ''');
    if (bookingId != null) query = query.eq('id', bookingId);
    // Give PostgreSQL an indexed participant predicate; RLS still enforces
    // authorization independently of this query optimization.
    final viewerId = _client.auth.currentUser?.id;
    if (viewerId != null && viewerRole == 'tourist') {
      query = query.eq('tourist_id', viewerId);
    } else if (viewerId != null && viewerRole == 'driver') {
      // Pending matched offers have no assigned driver yet. RLS narrows these
      // pending candidates to this driver's unexpired offers.
      query = activeOnly
          ? query.or('driver_id.eq.$viewerId,status.eq.pending')
          : query.eq('driver_id', viewerId);
    }
    if (activeOnly) {
      query = query.inFilter('status', _activeBookingStatuses);
    } else if (historyOnly) {
      query = query.not(
        'status',
        'in',
        '(${_activeBookingStatuses.join(',')})',
      );
    }
    final (rows, secureValues) = await (
      query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(start, start + safeSize - 1)
          .timeout(_readDeadline),
      pickupValues ?? _secureStorage.readAll(),
    ).wait;

    final result = <BookingModel>[];
    for (final source in rows) {
      await readRowIndependently(
        () async {
          final row = Map<String, dynamic>.from(source);
          final id = row['id'] as String;
          final stops =
              (row['booking_stops'] as List? ?? [])
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
                ..sort(
                  (a, b) => (a['stop_order'] as int).compareTo(
                    b['stop_order'] as int,
                  ),
                );
          final eventRows =
              (row['trip_events'] as List? ?? [])
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList()
                ..sort(
                  (a, b) => (a['created_at'] as String).compareTo(
                    b['created_at'] as String,
                  ),
                );
          final paymentRows = (row['payments'] as List? ?? [])
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final cashRows = (row['cash_confirmations'] as List? ?? [])
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final reviews = row['booking_reviews'] as List? ?? [];
          final offerRows = (row['booking_offers'] as List? ?? [])
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          final ownOffer = offerRows
              .where(
                (offer) =>
                    offer['driver_id'] == _client.auth.currentUser?.id &&
                    offer['status'] == 'offered',
              )
              .firstOrNull;
          final routeChangeRows = (row['booking_route_changes'] as List? ?? [])
              .map((item) => Map<String, dynamic>.from(item))
              .where((item) => item['status'] == 'pending')
              .toList();
          final pendingRouteChange = routeChangeRows.firstOrNull;
          final driverId = row['driver_id'] as String?;
          final currentUserId = _client.auth.currentUser?.id == viewerId
              ? viewerId
              : null;
          final scopedPickupKey = currentUserId == null
              ? null
              : 'pickup_code_${currentUserId}_$id';
          var pickupCode = scopedPickupKey == null
              ? null
              : secureValues[scopedPickupKey];
          // One-time migration from the original unscoped key. Only the tourist
          // who owns the booking may claim it, so account switching cannot expose
          // a previous user's pickup code.
          if (pickupCode == null &&
              currentUserId != null &&
              row['tourist_id'] == currentUserId) {
            final legacyKey = 'pickup_code_$id';
            pickupCode = secureValues[legacyKey];
            if (pickupCode != null) {
              await _secureStorage.write(
                key: scopedPickupKey!,
                value: pickupCode,
              );
              await _secureStorage.delete(key: legacyKey);
            }
          }
          // A booking-create response can be lost after the database commits.
          // Resume only a recovery request that was persisted before its RPC;
          // the server accepts the same request once and rejects code rotation.
          if (pickupCode == null &&
              currentUserId != null &&
              row['tourist_id'] == currentUserId &&
              const [
                'scheduled',
                'pending',
                'accepted',
              ].contains(row['status'])) {
            final pendingRequest =
                secureValues[pickupRecoveryRequestKey(currentUserId, id)];
            final pendingCode =
                secureValues[pickupRecoveryCodeKey(currentUserId, id)];
            if (pendingRequest != null && pendingCode != null) {
              try {
                pickupCode = await _recoverPickupCode(
                  userId: currentUserId,
                  bookingId: id,
                  recoveryId: pendingRequest,
                  pickupCode: pendingCode,
                );
              } catch (_) {
                // Loading the booking must remain available while offline. The
                // persisted request is retried on the next refresh.
              }
            }
          }
          final receivedCents = paymentRows
              .where(
                (p) => const {
                  'paid',
                  'cash_paid',
                  'gcash_paid',
                }.contains(p['status']),
              )
              .fold<int>(0, (sum, p) => sum + (p['amount_centavos'] as int));
          bool confirmed(String direction, String actor) => cashRows.any(
            (c) => c['direction'] == direction && c['actor_role'] == actor,
          );
          final quoted = row['quoted_amount_centavos'] as int;
          final policy = row['cancellation_policies'] as Map? ?? const {};
          final tourist = row['tourist'] as Map?;
          final driver = row['driver'] as Map?;
          final driverProfile = driver?['driver_profiles'] as Map?;
          final fare = row['fare_revisions'] as Map?;
          result.add(
            BookingModel(
              id: id,
              touristId: row['tourist_id'],
              touristName:
                  tourist?['full_name'] as String? ?? MessageCode.tourist,
              driverId: driverId,
              driverName: driver?['full_name'] as String?,
              driverPlate: driverProfile?['plate_number'] as String?,
              stops: stops
                  .map(
                    (stop) => BookingStop(
                      id: stop['id'] as String? ?? '',
                      spotId: stop['spot_id'] ?? '',
                      spotName: stop['spot_name_snapshot'],
                      latitude: (stop['latitude_snapshot'] as num).toDouble(),
                      longitude: (stop['longitude_snapshot'] as num).toDouble(),
                      fareCents: 0,
                    ),
                  )
                  .toList(),
              pickupLat: (row['pickup_latitude'] as num).toDouble(),
              pickupLng: (row['pickup_longitude'] as num).toDouble(),
              pickupAddress: row['pickup_address'],
              passengerCount: row['passenger_count'] as int? ?? 1,
              luggageNotes: row['luggage_notes'] as String? ?? '',
              accessibilityNeeds: row['accessibility_needs'] as String? ?? '',
              baseFareCents: quoted,
              totalFareCents: quoted,
              paymentMethod: switch (row['payment_method']) {
                'cash' => PaymentMethod.cash,
                'paymongo' => PaymentMethod.online,
                'gcash_direct' => PaymentMethod.gcashDirect,
                _ => PaymentMethod.unknown,
              },
              paymentStatus: _paymentStatus(row['payment_status']),
              status: _bookingStatus(row['status']),
              createdAt: DateTime.parse(row['created_at']),
              scheduledAt: _date(row['scheduled_at']),
              dispatchExpiresAt: _date(row['dispatch_expires_at']),
              offerExpiresAt: _date(ownOffer?['expires_at']),
              acceptedAt: _date(row['accepted_at']),
              startedAt: _date(row['started_at']),
              completedAt: _date(row['completed_at']),
              replacementRequestedAt: _date(row['replacement_requested_at']),
              replacementReason: row['replacement_reason'] as String?,
              pendingRouteChange: pendingRouteChange == null
                  ? null
                  : BookingRouteChange(
                      id: pendingRouteChange['id'] as String,
                      requestedBy: pendingRouteChange['requested_by'] as String,
                      requestedRole:
                          pendingRouteChange['requested_role'] as String,
                      type: pendingRouteChange['change_type'] as String,
                      targetStopId:
                          pendingRouteChange['target_stop_id'] as String?,
                      proposedOrder: List<String>.from(
                        pendingRouteChange['proposed_order'] as List? ??
                            const [],
                      ),
                      reason: pendingRouteChange['reason'] as String,
                      createdAt: DateTime.parse(
                        pendingRouteChange['created_at'] as String,
                      ),
                    ),
              routeAdjustmentRequired:
                  row['route_adjustment_required'] as bool? ?? false,
              interruptedAt: _date(row['interrupted_at']),
              interruptionReason: row['interruption_reason'] as String?,
              touristWaitConfirmedAt: _date(row['tourist_wait_confirmed_at']),
              lastRouteDeviationAt: _date(row['last_route_deviation_at']),
              cancellationReason: row['cancellation_reason'],
              driverRating: reviews.isEmpty
                  ? null
                  : (reviews.first['rating'] as num).toDouble(),
              driverReview: reviews.isEmpty ? null : reviews.first['review'],
              freeCancellationMinutes:
                  policy['free_cancellation_minutes'] as int? ?? 5,
              acceptedCancellationPercent:
                  policy['accepted_trip_fee_percent'] as int? ?? 20,
              driverWaitMinutes: policy['driver_wait_minutes'] as int? ?? 10,
              noShowFeePercent: policy['no_show_fee_percent'] as int? ?? 50,
              trip: TripRecord(
                fareRevision: fare?['revision'] as int? ?? 1,
                packageId: row['package_id'],
                pickupCode: pickupCode ?? '',
                pickupArrivedAt: _date(row['driver_arrived_at']),
                pickupWaitExpiresAt: _date(row['pickup_wait_expires_at']),
                confirmedStops: row['confirmed_stop_count'] ?? 0,
                arrivalPending: row['arrival_pending'] ?? false,
                finalChargeCents: row['final_charge_centavos'],
                reviewRequired: row['payment_status'] == 'under_review',
                touristCashConfirmed: confirmed('payment', 'tourist'),
                driverCashConfirmed: confirmed('payment', 'driver'),
                touristRefundConfirmed: confirmed('refund', 'tourist'),
                driverRefundConfirmed: confirmed('refund', 'driver'),
                receivedCents: receivedCents,
                events: eventRows
                    .map(
                      (event) => TripEvent(
                        DateTime.parse(event['created_at']),
                        _actor(event['actor_role']),
                        event['description'],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
          if (currentUserId != null &&
              row['tourist_id'] == currentUserId &&
              row['client_request_id'] != null &&
              row['client_request_id'] ==
                  pendingBookingRequestId(
                    secureValues['booking_request_$currentUserId'],
                  )) {
            await _secureStorage.delete(key: 'booking_request_$currentUserId');
          }
        },
        (error, stack) {
          unawaited(TelemetryService.recordNonFatal(error, stack));
        },
      );
    }
    return DataPage(
      items: result,
      page: safePage,
      pageSize: safeSize,
      hasMore: rows.length == safeSize,
    );
  }

  static Future<
    ({
      List<Map<String, dynamic>> drivers,
      List<Map<String, dynamic>> tourists,
      bool hasMore,
    })
  >
  loadDirectory({int page = 0, int pageSize = 100}) async {
    final profiles = await _client
        .from('profiles')
        .select('id,full_name,email,role,status,phone,created_at')
        .order('id')
        .range(page * pageSize, page * pageSize + pageSize - 1)
        .timeout(_readDeadline);
    if (profiles.isEmpty) {
      return (
        drivers: <Map<String, dynamic>>[],
        tourists: <Map<String, dynamic>>[],
        hasMore: false,
      );
    }
    final driverIds = profiles
        .where((profile) => profile['role'] == 'driver')
        .map((profile) => profile['id'] as String)
        .toList();
    final (driverProfiles, locations) = driverIds.isEmpty
        ? (<Map<String, dynamic>>[], <Map<String, dynamic>>[])
        : await (
            _client
                .from('driver_profiles')
                .select(
                  'profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,rating_average,is_online,last_seen_at,passenger_capacity,accepts_accessibility_requests,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km,matching_blocked_until,matching_blocked_reason,compliance_reviewed_at,completed_trip_count,driver_cancelled_trip_count,reliability_score',
                )
                .inFilter('profile_id', driverIds)
                .timeout(_readDeadline),
            _client
                .from('driver_locations')
                .select(
                  'driver_id,latitude,longitude,accuracy_meters,heading,speed_mps,recorded_at',
                )
                .inFilter('driver_id', driverIds)
                .timeout(_readDeadline),
          ).wait;
    for (final row in driverProfiles) {
      _driverRecords[row['profile_id'] as String] = Map<String, dynamic>.from(
        row,
      );
    }
    final byDriver = {
      for (final row in driverProfiles) row['profile_id'] as String: row,
    };
    final byLocation = {
      for (final row in locations) row['driver_id'] as String: row,
    };
    final drivers = <Map<String, dynamic>>[];
    final tourists = <Map<String, dynamic>>[];
    for (final profile in profiles) {
      final id = profile['id'] as String;
      if (profile['role'] == 'driver') {
        final driver = byDriver[id];
        final location = byLocation[id];
        drivers.add({
          'id': id,
          'name': profile['full_name'],
          'plate': driver?['plate_number'] ?? '',
          'franchise': driver?['franchise_number'] ?? '',
          'licensePath': driver?['license_document_path'],
          'vehicleDocumentPath': driver?['vehicle_document_path'],
          'email': profile['email'] ?? '',
          'phone': profile['phone'] ?? '',
          'status': driver?['approval_status'] == 'approved'
              ? profile['status']
              : driver?['approval_status'] ?? 'pending',
          'rating': (driver?['rating_average'] as num?)?.toDouble() ?? 0.0,
          'passengerCapacity': driver?['passenger_capacity'] ?? 3,
          'acceptsAccessibilityRequests':
              driver?['accepts_accessibility_requests'] ?? true,
          'licenseExpiresOn': driver?['license_expires_on'],
          'franchiseExpiresOn': driver?['franchise_expires_on'],
          'vehicleInspectionExpiresOn':
              driver?['vehicle_inspection_expires_on'],
          'serviceAreaName': driver?['service_area_name'] ?? 'Bustos, Bulacan',
          'serviceAreaLatitude':
              (driver?['service_area_latitude'] as num?)?.toDouble() ?? 14.9571,
          'serviceAreaLongitude':
              (driver?['service_area_longitude'] as num?)?.toDouble() ??
              120.9188,
          'serviceAreaRadiusKm':
              (driver?['service_area_radius_km'] as num?)?.toDouble() ?? 15,
          'matchingBlockedUntil': driver?['matching_blocked_until'],
          'matchingBlockedReason': driver?['matching_blocked_reason'],
          'complianceReviewedAt': driver?['compliance_reviewed_at'],
          'completedTripCount': driver?['completed_trip_count'] ?? 0,
          'driverCancelledTripCount':
              driver?['driver_cancelled_trip_count'] ?? 0,
          'reliabilityScore':
              (driver?['reliability_score'] as num?)?.toDouble() ?? 100,
          'isOnline': driver?['is_online'] ?? false,
          'lat': location?['latitude'],
          'lng': location?['longitude'],
          'accuracy': location?['accuracy_meters'],
          'heading': location?['heading'],
          'speed': location?['speed_mps'],
          'locationUpdatedAt': location?['recorded_at'],
        });
      } else if (profile['role'] == 'tourist') {
        tourists.add({
          'id': id,
          'name': profile['full_name'],
          'email': profile['email'] ?? '',
          'phone': profile['phone'] ?? '',
          'status': profile['status'],
          'trips': 0,
        });
      }
    }
    return (
      drivers: drivers,
      tourists: tourists,
      hasMore: profiles.length == pageSize,
    );
  }

  static Future<
    ({
      List<Map<String, dynamic>> drivers,
      List<Map<String, dynamic>> tourists,
      bool hasMore,
    })
  >
  loadDirectoryWindow({int throughPage = 0}) async {
    final result =
        await readPageWindow<({bool driver, Map<String, dynamic> item})>(
          throughPage: throughPage,
          fetch: (page) async {
            final batch = await loadDirectory(page: page);
            return (
              items: [
                for (final driver in batch.drivers)
                  (driver: true, item: driver),
                for (final tourist in batch.tourists)
                  (driver: false, item: tourist),
              ],
              hasMore: batch.hasMore,
            );
          },
        );
    return (
      drivers: result.items
          .where((item) => item.driver)
          .map((item) => item.item)
          .toList(),
      tourists: result.items
          .where((item) => !item.driver)
          .map((item) => item.item)
          .toList(),
      hasMore: result.hasMore,
    );
  }

  static Future<void> setDriverOnline(bool online) =>
      rpc('set_driver_online', {'p_online': online});

  static Future<void> saveFares({
    required int customCents,
    required Map<String, int> packageFares,
    required String reason,
  }) => rpc('publish_fares', {
    'p_custom_fare_centavos': customCents,
    'p_package_fares': packageFares,
    'p_reason': reason,
  });

  static Future<void> saveCancellationPolicy({
    required int expectedVersion,
    required int freeCancellationMinutes,
    required int acceptedTripFeePercent,
    required int driverWaitMinutes,
    required int noShowFeePercent,
    required String terms,
    required String reason,
  }) => rpc('publish_cancellation_policy', {
    'p_expected_version': expectedVersion,
    'p_free_cancellation_minutes': freeCancellationMinutes,
    'p_accepted_trip_fee_percent': acceptedTripFeePercent,
    'p_driver_wait_minutes': driverWaitMinutes,
    'p_no_show_fee_percent': noShowFeePercent,
    'p_terms': terms,
    'p_reason': reason,
  });

  static Future<void> submitFeedback({
    required String category,
    required String message,
    String? bookingId,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError(MessageCode.signInBeforeSendingFeedback);
    await _client.from('feedback').insert({
      'author_id': user.id,
      'booking_id': bookingId,
      'category': category,
      'message': message.trim(),
    });
  }

  static Future<void> setDriverApproval(
    String id,
    String status, {
    required String reason,
    DateTime? blockedUntil,
  }) => rpc('admin_set_driver_status', {
    'p_driver_id': id,
    'p_status': status == 'active' ? 'approved' : status,
    'p_reason': reason,
    'p_blocked_until': blockedUntil?.toUtc().toIso8601String(),
  });

  static Future<void> reviewDriverCompliance({
    required String driverId,
    required DateTime licenseExpiresOn,
    required DateTime franchiseExpiresOn,
    required DateTime vehicleInspectionExpiresOn,
    required String serviceAreaName,
    required double serviceAreaLatitude,
    required double serviceAreaLongitude,
    required double serviceAreaRadiusKm,
    required bool approve,
    String reviewNote = '',
  }) => rpc('admin_review_driver_compliance', {
    'p_driver_id': driverId,
    'p_license_expires_on': _dateOnly(licenseExpiresOn),
    'p_franchise_expires_on': _dateOnly(franchiseExpiresOn),
    'p_vehicle_inspection_expires_on': _dateOnly(vehicleInspectionExpiresOn),
    'p_service_area_name': serviceAreaName,
    'p_service_area_latitude': serviceAreaLatitude,
    'p_service_area_longitude': serviceAreaLongitude,
    'p_service_area_radius_km': serviceAreaRadiusKm,
    'p_approve': approve,
    'p_review_note': reviewNote,
  });

  static Future<void> setTouristStatus(
    String id,
    String status, {
    required String reason,
  }) => rpc('admin_set_tourist_status', {
    'p_tourist_id': id,
    'p_status': status,
    'p_reason': reason,
  });

  static Future<Set<String>> loadAdminCapabilities() async {
    final user = _client.auth.currentUser;
    if (user == null) return const {};
    final rows = await _client
        .from('admin_capabilities')
        .select('capability')
        .eq('profile_id', user.id);
    return rows.map((row) => row['capability'] as String).toSet();
  }

  static Future<List<Map<String, dynamic>>> loadOperationalAlerts({
    int limit = 100,
  }) async {
    final rows = await _client
        .from('operational_alerts')
        .select()
        .isFilter('resolved_at', null)
        .order('last_seen_at', ascending: false)
        .limit(limit.clamp(1, 200).toInt());
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<void> sendAnnouncement(
    String title,
    String body, {
    required String audience,
    required String requestId,
  }) => rpc('send_announcement', {
    'p_title': title,
    'p_body': body,
    'p_audience': audience,
    'p_request_id': requestId,
  });

  static Future<List<Map<String, dynamic>>> loadNotifications({
    int page = 0,
    int pageSize = 100,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 100).toInt();
    final start = safePage * safeSize;
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .range(start, start + safeSize - 1);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<List<Map<String, dynamic>>> loadFeedback({
    int page = 0,
    int pageSize = 100,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 100).toInt();
    final start = safePage * safeSize;
    final rows = await _client
        .from('feedback')
        .select('id,category,message,created_at,author_id')
        .order('created_at', ascending: false)
        .range(start, start + safeSize - 1);
    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  static Future<void> markNotificationRead(String id) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  static Future<void> markAllNotificationsRead() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('recipient_id', user.id)
        .isFilter('read_at', null);
  }

  static Future<void> upsertSpot({
    required TouristSpotModel spot,
    required String address,
    Uint8List? imageBytes,
  }) async {
    String? imageUrl = spot.imageUrls.firstOrNull;
    if (imageBytes != null) {
      final material = SpotImageMaterial.create(spot.id, imageBytes);
      final path = material.path;
      await _client.storage
          .from('tourist-spots')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: FileOptions(
              contentType: material.contentType,
              upsert: false,
              cacheControl: SpotImageMaterial.cacheControl,
            ),
          );
      imageUrl = _client.storage.from('tourist-spots').getPublicUrl(path);
    }
    await _client.from('tourist_spots').upsert({
      'id': spot.id,
      'name': spot.name,
      'description': spot.description,
      'history': spot.history,
      'category': spot.category.name,
      'address': address.trim(),
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'image_url': imageUrl,
      'opening_hours': spot.openingHours,
      'entrance_fee_note': spot.entranceFee,
      'tips': spot.tips,
      'distance_from_town': spot.distanceFromTown,
      'is_active': spot.isActive,
      'availability_status': spot.availabilityStatus,
      'closed_until': spot.closedUntil?.toUtc().toIso8601String(),
      'closure_reason': spot.closureReason,
    });
    // Keep prior immutable versions: another device or concurrent edit may still reference them.
  }

  static Future<void> setSpotAvailability({
    required String spotId,
    required bool closed,
    String? reason,
    DateTime? closedUntil,
  }) => rpc('set_spot_availability', {
    'p_spot_id': spotId,
    'p_status': closed ? 'temporarily_closed' : 'open',
    'p_reason': reason,
    'p_closed_until': closedUntil?.toUtc().toIso8601String(),
  });

  static Future<void> setSpotActive(String spotId, bool active) async {
    await _client
        .from('tourist_spots')
        .update({'is_active': active})
        .eq('id', spotId);
  }

  static Future<Map<String, dynamic>> loadOwnProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError(MessageCode.signInFirst);
    final profile = await _client
        .from('profiles')
        .select('id,full_name,phone,role,avatar_path')
        .eq('id', user.id)
        .single();
    final result = Map<String, dynamic>.from(profile);
    result['email'] = user.email ?? '';
    if (profile['role'] == 'driver') {
      final driver = await _client
          .from('driver_profiles')
          .select(
            'plate_number,franchise_number,passenger_capacity,accepts_accessibility_requests,approval_status,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_radius_km,matching_blocked_until,matching_blocked_reason,reliability_score,completed_trip_count,driver_cancelled_trip_count',
          )
          .eq('profile_id', user.id)
          .single();
      result.addAll(Map<String, dynamic>.from(driver));
    }
    return result;
  }

  static Future<void> updateOwnProfile({
    required String fullName,
    required String phone,
    Uint8List? avatarBytes,
    String? plateNumber,
    String? franchiseNumber,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError(MessageCode.signInFirst);
    Future<void> writeProfile(String? avatarPath) => rpc('update_own_profile', {
      'p_full_name': fullName,
      'p_phone': Validators.normalizePhone(phone),
      'p_avatar_path': avatarPath,
      'p_plate_number': plateNumber,
      'p_franchise_number': franchiseNumber,
    });

    if (avatarBytes == null) {
      await writeProfile(null);
      return;
    }
    final profile = await _client
        .from('profiles')
        .select('avatar_path')
        .eq('id', user.id)
        .single();
    final service = AvatarReplacementService(
      store: _SupabaseAvatarObjectStore(_client),
      isReferenced: (objectPath) async {
        final rows = await _client
            .from('profiles')
            .select('id')
            .eq('avatar_path', objectPath)
            .limit(1);
        return rows.isNotEmpty;
      },
      onCleanupFailure: (objectPath, error, stack) {
        unawaited(
          TelemetryService.recordNonFatal(
            StateError(
              MessageCode.avatarCleanupPendingForObjectValue(
                (objectPath).toString(),
              ),
            ),
            stack,
          ),
        );
      },
    );
    await service.replace(
      userId: user.id,
      bytes: avatarBytes,
      previousPath: profile['avatar_path'] as String?,
      updateProfile: writeProfile,
    );
  }

  static Future<void> updateDriverServiceProfile({
    required int passengerCapacity,
    required bool acceptsAccessibilityRequests,
  }) => rpc('update_driver_service_profile', {
    'p_passenger_capacity': passengerCapacity,
    'p_accepts_accessibility_requests': acceptsAccessibilityRequests,
  });

  static Future<void> deleteSpot(String id) async {
    await _client.from('tourist_spots').delete().eq('id', id);
    final files = await _client.storage.from('tourist-spots').list(path: id);
    final paths = files.map((file) => '$id/${file.name}').toList();
    if (paths.isNotEmpty) {
      await _client.storage.from('tourist-spots').remove(paths);
    }
  }

  static Future<String> createDriverDocumentUrl(String path) =>
      _client.storage.from('driver-documents').createSignedUrl(path, 300);

  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static BookingStatus _bookingStatus(String value) => switch (value) {
    'payment_pending' => BookingStatus.paymentPending,
    'scheduled' => BookingStatus.scheduled,
    'replacement_pending' => BookingStatus.replacementPending,
    _ =>
      BookingStatus.values
              .where((status) => status.name == value)
              .firstOrNull ??
          BookingStatus.unknown,
  };
  static TripActor _actor(String? value) => TripActor.values.firstWhere(
    (actor) => actor.name == value,
    orElse: () => TripActor.unknown,
  );
  static PaymentStatus _paymentStatus(String value) => switch (value) {
    'checkout_created' => PaymentStatus.checkoutCreated,
    'processing' => PaymentStatus.processing,
    'failed' => PaymentStatus.failed,
    'cash_awaiting_confirmation' => PaymentStatus.awaitingConfirmation,
    'gcash_awaiting_confirmation' => PaymentStatus.gcashAwaitingConfirmation,
    'disputed' => PaymentStatus.disputed,
    'under_review' => PaymentStatus.underReview,
    'paid' || 'cash_paid' || 'gcash_paid' => PaymentStatus.paid,
    'waived' => PaymentStatus.waived,
    'refund_required' => PaymentStatus.refundDue,
    'refund_processing' => PaymentStatus.refundProcessing,
    'partially_refunded' => PaymentStatus.partiallyRefunded,
    'refunded' => PaymentStatus.refunded,
    'unpaid' => PaymentStatus.unpaid,
    _ => PaymentStatus.unknown,
  };

  static Future<List<Map<String, dynamic>>> loadFinancialLedger(
    String bookingId,
  ) async {
    final rows = await _client
        .from('financial_ledger_entries')
        .select(
          'id,entry_type,direction,amount_centavos,currency,provider,provider_mode,provider_reference,description,metadata,occurred_at',
        )
        .eq('booking_id', bookingId)
        .order('occurred_at', ascending: false);
    return rows
        .map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  static Future<BookingCreationResult> createBooking({
    required String? packageId,
    required PaymentMethod paymentMethod,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required List<TouristSpotModel> stops,
    required int passengerCount,
    required String luggageNotes,
    required String accessibilityNeeds,
    DateTime? scheduledAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError(MessageCode.signInFirst);
    final params = <String, dynamic>{
      'p_package_id': packageId,
      'p_payment_method': switch (paymentMethod) {
        PaymentMethod.online => 'paymongo',
        PaymentMethod.gcashDirect => 'gcash_direct',
        _ => 'cash',
      },
      'p_pickup_address': pickupAddress,
      'p_pickup_latitude': pickupLatitude,
      'p_pickup_longitude': pickupLongitude,
      'p_passenger_count': passengerCount,
      'p_luggage_notes': luggageNotes,
      'p_accessibility_needs': accessibilityNeeds,
      'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      'p_stops': [
        for (var i = 0; i < stops.length; i++)
          {'spot_id': stops[i].id, 'stop_order': i + 1},
      ],
    };
    final requestId = await BookingRequestMaterial.prepare(
      userId: userId,
      payload: params,
      read: (key) => _secureStorage.read(key: key),
      write: (key, value) => _secureStorage.write(key: key, value: value),
    );
    params['p_request_id'] = requestId;
    Map<String, dynamic> response;
    try {
      response = Map<String, dynamic>.from(
        await _client.rpc('create_booking_with_schedule', params: params),
      );
    } on PostgrestException catch (error) {
      if (const ['P0001', '42501', '23514', '22023'].contains(error.code)) {
        await _secureStorage.delete(key: 'booking_request_$userId');
      }
      rethrow;
    } catch (_) {
      final row = await _client
          .from('bookings')
          .select('id,tourist_id,client_request_id')
          .eq('tourist_id', userId)
          .eq('client_request_id', requestId)
          .maybeSingle();
      final matchedId = matchingBookingRequest(
        row,
        userId: userId,
        requestId: requestId,
      );
      if (matchedId == null) rethrow;
      response = {'booking_id': matchedId, 'pickup_code': null};
    }
    if (userId != _client.auth.currentUser?.id) {
      throw StateError(MessageCode.bookingSessionChanged);
    }
    final id = response['booking_id'] as String;
    final codeKey = 'pickup_code_${userId}_$id';
    final pickupCode =
        response['pickup_code'] as String? ??
        await _secureStorage.read(key: codeKey) ??
        await _recoverPickupCode(userId: userId, bookingId: id);
    await _secureStorage.write(key: codeKey, value: pickupCode);
    final bookings = await loadBookings(bookingId: id);
    final booking = bookings.firstWhere((booking) => booking.id == id);
    await _secureStorage.delete(key: 'booking_request_$userId');
    return BookingCreationResult(booking, pickupCode);
  }

  static Future<PickupServiceArea> loadPickupServiceArea() async {
    final row = await _client
        .from('service_configuration')
        .select('centre_latitude,centre_longitude,radius_km')
        .eq('singleton', true)
        .single();
    return PickupServiceArea(
      (row['centre_latitude'] as num).toDouble(),
      (row['centre_longitude'] as num).toDouble(),
      (row['radius_km'] as num).toDouble(),
    );
  }

  static Future<void> reissuePickupCode(String bookingId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError(MessageCode.signInFirst);
    await reissuePickupWithMaterial(
      userId: userId,
      bookingId: bookingId,
      read: (key) => _secureStorage.read(key: key),
      write: (key, value) => _secureStorage.write(key: key, value: value),
      delete: (key) => _secureStorage.delete(key: key),
      issue: (material) async {
        final code = await _client.rpc(
          'reissue_booking_pickup_code',
          params: {
            'p_booking_id': bookingId,
            'p_request_id': material.requestId,
            'p_code': material.code,
          },
        );
        if (_client.auth.currentUser?.id != userId) {
          throw StateError(MessageCode.sessionChanged);
        }
        return code as String;
      },
    );
  }

  static Future<String> _recoverPickupCode({
    required String userId,
    required String bookingId,
    String? recoveryId,
    String? pickupCode,
  }) async {
    final material = recoveryId != null && pickupCode != null
        ? PickupRecoveryMaterial(requestId: recoveryId, code: pickupCode)
        : await preparePickupRecoveryMaterial(
            userId: userId,
            bookingId: bookingId,
            read: (key) => _secureStorage.read(key: key),
            write: (key, value) => _secureStorage.write(key: key, value: value),
          );
    final stableRequestId = material.requestId;
    final stableCode = material.code;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final recovered =
            await _client.rpc(
                  'recover_booking_pickup_code',
                  params: {
                    'p_booking_id': bookingId,
                    'p_recovery_id': stableRequestId,
                    'p_pickup_code': stableCode,
                  },
                )
                as String;
        if (recovered != stableCode) {
          throw StateError(MessageCode.pickupRecoveryFailed);
        }
        await finalizePickupRecoveryMaterial(
          userId: userId,
          bookingId: bookingId,
          code: recovered,
          write: (key, value) => _secureStorage.write(key: key, value: value),
          delete: (key) => _secureStorage.delete(key: key),
        );
        return recovered;
      } on PostgrestException {
        rethrow;
      } catch (_) {
        // Retry the same recovery operation; surface only the stable message below.
      }
    }
    throw StateError(MessageCode.pickupRecoveryFailed);
  }

  static Future<void> rpc(String name, Map<String, dynamic> parameters) async {
    await _client.rpc(name, params: parameters);
  }

  static Future<Map<String, dynamic>?> driverGcashDetails(String driverId) =>
      _client
          .from('driver_gcash_details')
          .select('gcash_account_name,gcash_number,is_active,qr_object_path')
          .eq('driver_id', driverId)
          .maybeSingle();

  static Future<void> saveDriverGcashDetails({
    required String number,
    required String name,
    required bool active,
  }) async {
    final driverId = _client.auth.currentUser?.id;
    if (driverId == null) throw StateError(MessageCode.signInFirst);
    await _client.from('driver_gcash_details').upsert({
      'driver_id': driverId,
      'gcash_number': number,
      'gcash_account_name': name,
      'is_active': active,
    });
  }

  static Future<String?> bookingGcashReference(String bookingId) async =>
      await _client.rpc(
            'get_booking_gcash_reference',
            params: {'p_booking_id': bookingId},
          )
          as String?;

  static Future<void> registerPushToken({
    required String token,
    required String platform,
    required String deviceLabel,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.rpc(
      'register_push_token',
      params: {
        'p_token': token,
        'p_platform': platform,
        'p_device_label': deviceLabel,
      },
    );
  }

  static Future<void> revokePushToken(String token) async {
    await _client.rpc('revoke_push_token', params: {'p_token': token});
  }

  static Future<void> purgePickupCodes({
    required String userId,
    Set<String> retained = const {},
  }) async {
    final values = await _secureStorage.readAll();
    final prefix = 'pickup_code_${userId}_';
    final removals = values.keys.where(
      (key) =>
          (key.startsWith(prefix) &&
              !retained.contains(key.substring(prefix.length))) ||
          ((key.startsWith('pickup_recovery_request_${userId}_') ||
                  key.startsWith('pickup_recovery_code_${userId}_')) &&
              !retained.contains(key.split('_').last)),
    );
    for (final key in removals) {
      await _secureStorage.delete(key: key);
    }
  }

  static final _locationUploadGate = LocationUploadGate();

  static Future<void> publishLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
    required DateTime recordedAt,
    bool isMocked = false,
  }) async {
    final owner = _client.auth.currentUser?.id;
    if (owner == null) return;
    await _locationUploadGate.publish(
      owner: owner,
      latitude: latitude,
      longitude: longitude,
      now: DateTime.now(),
      write: () => rpc('publish_driver_location_with_flags', {
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_accuracy': accuracy,
        'p_heading': heading,
        'p_speed': speed,
        'p_recorded_at': recordedAt.toUtc().toIso8601String(),
        'p_is_mocked': isMocked,
      }),
    );
  }

  static final _pendingRefresh = <RemoteSection>{};
  static void subscribe(
    void Function(Set<RemoteSection>) onChanged, {
    required void Function(Map<String, dynamic>) onLocation,
  }) {
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _pendingRefresh.clear();
    final oldChannel = _channel;
    if (oldChannel != null) unawaited(_client.removeChannel(oldChannel));
    final channel = _client.channel('tric-gabay-session');
    _channel = channel;
    for (final entry in realtimeSections.entries) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: entry.key,
        callback: (payload) {
          if (!identical(_channel, channel)) return;
          if (entry.key == 'driver_profiles') {
            final row = payload.newRecord;
            final previous = _driverRecords[row['profile_id']];
            if (!driverProfileNeedsRefresh(previous, row)) {
              return;
            }
          }
          _pendingRefresh.add(entry.value);
          // Fixed window: continuous events cannot postpone the refresh forever.
          _refreshDebounce ??= Timer(const Duration(milliseconds: 300), () {
            _refreshDebounce = null;
            final sections = Set<RemoteSection>.of(_pendingRefresh);
            _pendingRefresh.clear();
            onChanged(sections);
          });
        },
      );
    }
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'driver_locations',
      callback: (payload) {
        if (!identical(_channel, channel)) return;
        onLocation(
          payload.eventType == PostgresChangeEvent.delete
              ? {'driver_id': payload.oldRecord['driver_id']}
              : payload.newRecord,
        );
      },
    );
    var wasSubscribed = false;
    channel.subscribe((status, error) {
      if (!identical(_channel, channel)) return;
      if (status == RealtimeSubscribeStatus.subscribed) {
        if (wasSubscribed) onChanged(RemoteSection.values.toSet());
        wasSubscribed = true;
      }
    });
  }

  static Future<void> dispose() async {
    _locationUploadGate.reset();
    _driverRecords.clear();
    _refreshDebounce?.cancel();
    _refreshDebounce = null;
    _pendingRefresh.clear();
    final departingChannel = _channel;
    _channel = null;
    if (departingChannel != null) await _client.removeChannel(departingChannel);
  }
}

class _SupabaseAvatarObjectStore implements AvatarObjectStore {
  final SupabaseClient client;

  const _SupabaseAvatarObjectStore(this.client);

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) => client.storage
      .from('profile-images')
      .uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: false),
      );

  @override
  Future<void> remove(String path) async {
    await client.storage.from('profile-images').remove([path]);
  }
}
