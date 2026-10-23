import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/booking_model.dart';
import '../../models/tourist_spot_model.dart';
import '../../models/trip_record.dart';
import '../config/backend_config.dart';
import 'fare_policy.dart';
import 'cancellation_policy.dart';

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
  static SupabaseClient get _client => BackendConfig.client;
  static RealtimeChannel? _channel;
  static Timer? _refreshDebounce;

  static Future<FarePolicy> loadFarePolicy() async {
    final row = await _client
        .from('fare_revisions')
        .select('revision,custom_fare_centavos,package_fares,reason,created_at')
        .eq('is_current', true)
        .single();
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
        .select()
        .eq('is_current', true)
        .single();
    return CancellationPolicy(
      version: row['version'] as int,
      freeCancellationMinutes: row['free_cancellation_minutes'] as int,
      acceptedTripFeePercent: row['accepted_trip_fee_percent'] as int,
      driverWaitMinutes: row['driver_wait_minutes'] as int,
      noShowFeePercent: row['no_show_fee_percent'] as int,
      terms: row['terms'] as String,
      history: [
        '${row['created_at']} • ${row['change_reason'] ?? 'Published policy'}',
      ],
    );
  }

  static Future<List<TouristSpotModel>> loadSpots({
    int page = 0,
    int pageSize = 200,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 200).toInt();
    final start = safePage * safeSize;
    final rows = await _client
        .from('tourist_spots')
        .select()
        .eq('is_active', true)
        .order('name')
        .range(start, start + safeSize - 1);
    return rows.map<TouristSpotModel>((row) {
      final map = Map<String, dynamic>.from(row);
      return TouristSpotModel(
        id: map['id'],
        name: map['name'],
        description: map['description'] ?? '',
        history: map['history'] ?? '',
        category: _category(map['category']),
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        imageUrls: map['image_url'] == null || map['image_url'] == ''
            ? const []
            : [map['image_url'] as String],
        openingHours: map['opening_hours'] ?? '',
        entranceFee: map['entrance_fee_note'] ?? '',
        tips: List<String>.from(map['tips'] ?? const []),
        distanceFromTown: (map['distance_from_town'] as num?)?.toDouble() ?? 0,
        isActive: map['is_active'] ?? true,
        availabilityStatus: map['availability_status'] ?? 'open',
        closedUntil: _date(map['closed_until']),
        closureReason: map['closure_reason'] as String?,
      );
    }).toList();
  }

  static SpotCategory _category(String? value) =>
      SpotCategory.values.firstWhere(
        (item) => item.name.toLowerCase() == (value ?? '').toLowerCase(),
        orElse: () => SpotCategory.other,
      );

  static Future<List<BookingModel>> loadBookings({
    int page = 0,
    int pageSize = 200,
  }) async {
    final safePage = page < 0 ? 0 : page;
    final safeSize = pageSize.clamp(1, 200).toInt();
    final start = safePage * safeSize;
    final rows = await _client
        .from('bookings')
        .select(
          '*,booking_stops(*),booking_offers(*),booking_route_changes(*),trip_events(*),payments(*),refunds(*),cash_confirmations(*),booking_reviews(*)',
        )
        .order('created_at', ascending: false)
        .range(start, start + safeSize - 1);
    final profileIds = <String>{};
    for (final row in rows) {
      profileIds.add(row['tourist_id'] as String);
      if (row['driver_id'] != null) profileIds.add(row['driver_id'] as String);
    }
    final profileRows = profileIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('profiles')
              .select('id,full_name')
              .inFilter('id', profileIds.toList());
    final profiles = {
      for (final p in profileRows) p['id'] as String: p['full_name'] as String,
    };
    final driverRows = profileIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client
              .from('driver_profiles')
              .select('profile_id,plate_number')
              .inFilter('profile_id', profileIds.toList());
    final plates = {
      for (final d in driverRows)
        d['profile_id'] as String: d['plate_number'] as String,
    };
    final fares = await _client.from('fare_revisions').select('id,revision');
    final revisions = {
      for (final f in fares) f['id'] as String: f['revision'] as int,
    };
    final policyRows = await _client
        .from('cancellation_policies')
        .select(
          'id,free_cancellation_minutes,accepted_trip_fee_percent,driver_wait_minutes,no_show_fee_percent',
        );
    final policies = {
      for (final policy in policyRows)
        policy['id'] as String: Map<String, dynamic>.from(policy),
    };

    final result = <BookingModel>[];
    for (final source in rows) {
      final row = Map<String, dynamic>.from(source);
      final id = row['id'] as String;
      final stops =
          (row['booking_stops'] as List? ?? [])
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
            ..sort(
              (a, b) =>
                  (a['stop_order'] as int).compareTo(b['stop_order'] as int),
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
      final currentUserId = _client.auth.currentUser?.id;
      final scopedPickupKey = currentUserId == null
          ? null
          : 'pickup_code_${currentUserId}_$id';
      var pickupCode = scopedPickupKey == null
          ? null
          : await _secureStorage.read(key: scopedPickupKey);
      // One-time migration from the original unscoped key. Only the tourist
      // who owns the booking may claim it, so account switching cannot expose
      // a previous user's pickup code.
      if (pickupCode == null &&
          currentUserId != null &&
          row['tourist_id'] == currentUserId) {
        final legacyKey = 'pickup_code_$id';
        pickupCode = await _secureStorage.read(key: legacyKey);
        if (pickupCode != null) {
          await _secureStorage.write(key: scopedPickupKey!, value: pickupCode);
          await _secureStorage.delete(key: legacyKey);
        }
      }
      final receivedCents = paymentRows
          .where((p) => p['status'] == 'paid' || p['status'] == 'cash_paid')
          .fold<int>(0, (sum, p) => sum + (p['amount_centavos'] as int));
      bool confirmed(String direction, String actor) => cashRows.any(
        (c) => c['direction'] == direction && c['actor_role'] == actor,
      );
      final quoted = row['quoted_amount_centavos'] as int;
      final policy = policies[row['cancellation_policy_id']] ?? const {};
      result.add(
        BookingModel(
          id: id,
          touristId: row['tourist_id'],
          touristName: profiles[row['tourist_id']] ?? 'Tourist',
          driverId: driverId,
          driverName: driverId == null ? null : profiles[driverId],
          driverPlate: driverId == null ? null : plates[driverId],
          stops: stops
              .map(
                (stop) => BookingStop(
                  id: stop['id'] as String? ?? '',
                  spotId: stop['spot_id'] ?? '',
                  spotName: stop['spot_name_snapshot'],
                  latitude: (stop['latitude_snapshot'] as num).toDouble(),
                  longitude: (stop['longitude_snapshot'] as num).toDouble(),
                  fare: 0,
                ),
              )
              .toList(),
          pickupLat: (row['pickup_latitude'] as num).toDouble(),
          pickupLng: (row['pickup_longitude'] as num).toDouble(),
          pickupAddress: row['pickup_address'],
          passengerCount: row['passenger_count'] as int? ?? 1,
          luggageNotes: row['luggage_notes'] as String? ?? '',
          accessibilityNeeds: row['accessibility_needs'] as String? ?? '',
          baseFare: quoted / 100,
          totalFare: quoted / 100,
          paymentMethod: row['payment_method'] == 'paymongo'
              ? PaymentMethod.online
              : PaymentMethod.cash,
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
                  requestedRole: pendingRouteChange['requested_role'] as String,
                  type: pendingRouteChange['change_type'] as String,
                  targetStopId: pendingRouteChange['target_stop_id'] as String?,
                  proposedOrder: List<String>.from(
                    pendingRouteChange['proposed_order'] as List? ?? const [],
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
            fareRevision: revisions[row['fare_revision_id']] ?? 1,
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
    }
    return result;
  }

  static Future<
    ({List<Map<String, dynamic>> drivers, List<Map<String, dynamic>> tourists})
  >
  loadDirectory() async {
    final profiles = await _client
        .from('profiles')
        .select('id,full_name,email,role,status,phone,created_at')
        .limit(500);
    final driverProfiles = await _client
        .from('driver_profiles')
        .select(
          'profile_id,plate_number,franchise_number,license_document_path,vehicle_document_path,approval_status,rating_average,is_online,last_seen_at,passenger_capacity,accepts_accessibility_requests,license_expires_on,franchise_expires_on,vehicle_inspection_expires_on,service_area_name,service_area_latitude,service_area_longitude,service_area_radius_km,matching_blocked_until,matching_blocked_reason,compliance_reviewed_at,completed_trip_count,driver_cancelled_trip_count,reliability_score',
        )
        .limit(500);
    final locations = await _client
        .from('driver_locations')
        .select()
        .limit(500);
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
    return (drivers: drivers, tourists: tourists);
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
    if (user == null) throw StateError('Sign in before sending feedback.');
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

  static Future<void> sendAnnouncement(String title, String body) =>
      rpc('send_announcement', {'p_title': title, 'p_body': body});

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
      if (imageBytes.length > 5 * 1024 * 1024) {
        throw StateError('Tourist spot images must be 5 MB or smaller.');
      }
      final path = '${spot.id}/cover.jpg';
      await _client.storage
          .from('tourist-spots')
          .uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
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
    if (imageBytes != null) {
      final files = await _client.storage
          .from('tourist-spots')
          .list(path: spot.id);
      final obsolete = files
          .where((file) => file.name != 'cover.jpg')
          .map((file) => '${spot.id}/${file.name}')
          .toList();
      if (obsolete.isNotEmpty) {
        await _client.storage.from('tourist-spots').remove(obsolete);
      }
    }
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

  static Future<Map<String, dynamic>> loadOwnProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('Sign in first.');
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
    if (user == null) throw StateError('Sign in first.');
    String? avatarPath;
    if (avatarBytes != null) {
      if (avatarBytes.length > 5 * 1024 * 1024) {
        throw StateError('Profile images must be 5 MB or smaller.');
      }
      avatarPath = '${user.id}/avatar.jpg';
      await _client.storage
          .from('profile-images')
          .uploadBinary(
            avatarPath,
            avatarBytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
    }
    await rpc('update_own_profile', {
      'p_full_name': fullName,
      'p_phone': phone,
      'p_avatar_path': avatarPath,
      'p_plate_number': plateNumber,
      'p_franchise_number': franchiseNumber,
    });
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
    'scheduled' => BookingStatus.scheduled,
    'replacement_pending' => BookingStatus.replacementPending,
    _ => BookingStatus.values.byName(value),
  };
  static TripActor _actor(String? value) => TripActor.values.firstWhere(
    (actor) => actor.name == value,
    orElse: () => TripActor.system,
  );
  static PaymentStatus _paymentStatus(String value) => switch (value) {
    'checkout_created' => PaymentStatus.checkoutCreated,
    'processing' => PaymentStatus.processing,
    'failed' => PaymentStatus.failed,
    'cash_awaiting_confirmation' => PaymentStatus.awaitingConfirmation,
    'under_review' => PaymentStatus.underReview,
    'paid' || 'cash_paid' => PaymentStatus.paid,
    'waived' => PaymentStatus.waived,
    'refund_required' => PaymentStatus.refundDue,
    'refund_processing' => PaymentStatus.refundProcessing,
    'partially_refunded' => PaymentStatus.partiallyRefunded,
    'refunded' => PaymentStatus.refunded,
    _ => PaymentStatus.unpaid,
  };

  static Future<String> processPayMongoRefund({
    required String bookingId,
    required int amountCents,
    required String reason,
  }) async {
    final response = await _client.functions.invoke(
      'process-paymongo-refund',
      body: {
        'booking_id': bookingId,
        'amount_centavos': amountCents,
        'reason': reason,
      },
    );
    if (response.status < 200 || response.status >= 300) {
      final data = response.data is Map ? response.data as Map : null;
      final detail = data?['error'] ?? response.data;
      final note = data?['note'];
      throw StateError(
        [detail, note]
            .where((part) => part != null && part.toString().trim().isNotEmpty)
            .join('\n'),
      );
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['message']?.toString() ?? 'Refund decision recorded.';
  }

  static Future<String> reconcilePayMongoPayment(String bookingId) async {
    final response = await _client.functions.invoke(
      'reconcile-paymongo-payment',
      body: {'booking_id': bookingId},
    );
    if (response.status < 200 || response.status >= 300) {
      final detail = response.data is Map
          ? (response.data as Map)['error']
          : response.data;
      throw StateError(
        detail?.toString() ?? 'Payment status could not be refreshed.',
      );
    }
    final data = Map<String, dynamic>.from(response.data as Map);
    return data['message']?.toString() ?? 'Payment status refreshed.';
  }

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
    final response = Map<String, dynamic>.from(
      await _client.rpc(
        'create_booking_with_schedule',
        params: {
          'p_package_id': packageId,
          'p_payment_method': paymentMethod == PaymentMethod.online
              ? 'paymongo'
              : 'cash',
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
        },
      ),
    );
    final id = response['booking_id'] as String;
    final pickupCode = response['pickup_code'] as String;
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('The booking session expired.');
    await _secureStorage.write(
      key: 'pickup_code_${userId}_$id',
      value: pickupCode,
    );
    final bookings = await loadBookings();
    return BookingCreationResult(
      bookings.firstWhere((booking) => booking.id == id),
      pickupCode,
    );
  }

  static Future<void> rpc(String name, Map<String, dynamic> parameters) async {
    await _client.rpc(name, params: parameters);
    unawaited(dispatchCommunications());
  }

  static Future<void> dispatchCommunications() async {
    try {
      await _client.functions.invoke(
        'dispatch-communications',
        body: const {'limit': 20},
      );
    } catch (_) {
      // Delivery is queued server-side. A provider outage must never roll back
      // the booking action that created the notification.
    }
  }

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
    unawaited(dispatchCommunications());
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
          key.startsWith(prefix) &&
          !retained.contains(key.substring(prefix.length)),
    );
    for (final key in removals) {
      await _secureStorage.delete(key: key);
    }
  }

  static Future<String> completePayMongoTestRefund({
    required String bookingId,
    required int amountCents,
    required String reason,
  }) async {
    final result = Map<String, dynamic>.from(
      await _client.rpc(
        'complete_paymongo_test_refund',
        params: {
          'p_booking_id': bookingId,
          'p_amount_centavos': amountCents,
          'p_reason': reason,
        },
      ),
    );
    unawaited(dispatchCommunications());
    return result['status'] == 'succeeded'
        ? 'Refund completed in PayMongo test mode.'
        : 'Refund update recorded.';
  }

  static Future<String> createCheckout(String bookingId) async {
    final response = await _client.functions.invoke(
      'create-paymongo-checkout',
      body: {'booking_id': bookingId},
    );
    if (response.status < 200 || response.status >= 300) {
      throw StateError(
        response.data?['error'] ?? 'Checkout could not be created.',
      );
    }
    return response.data['checkout_url'] as String;
  }

  static Future<void> publishLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? heading,
    double? speed,
    required DateTime recordedAt,
  }) => rpc('publish_driver_location', {
    'p_latitude': latitude,
    'p_longitude': longitude,
    'p_accuracy': accuracy,
    'p_heading': heading,
    'p_speed': speed,
    'p_recorded_at': recordedAt.toUtc().toIso8601String(),
  });

  static void subscribe(void Function() onChanged) {
    _channel?.unsubscribe();
    _channel = _client.channel('tric-gabay-session')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'bookings',
        callback: (_) => _debounce(onChanged),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'booking_offers',
        callback: (_) => _debounce(onChanged),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'booking_route_changes',
        callback: (_) => _debounce(onChanged),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'tourist_spots',
        callback: (_) => _debounce(onChanged),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'driver_locations',
        callback: (_) => _debounce(onChanged),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        callback: (_) => _debounce(onChanged),
      )
      ..subscribe();
  }

  static void _debounce(void Function() callback) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 300), callback);
  }

  static Future<void> dispose() async {
    _refreshDebounce?.cancel();
    if (_channel != null) await _client.removeChannel(_channel!);
    _channel = null;
  }
}
