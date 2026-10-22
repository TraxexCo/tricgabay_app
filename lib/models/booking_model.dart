import 'trip_record.dart';

enum BookingStatus {
  scheduled,
  pending,
  accepted,
  replacementPending,
  ongoing,
  completed,
  cancelled,
}

enum PaymentMethod { cash, online }

enum PaymentStatus {
  unpaid,
  checkoutCreated,
  processing,
  failed,
  awaitingConfirmation,
  underReview,
  paid,
  waived,
  refundDue,
  refundProcessing,
  partiallyRefunded,
  refunded,
}

class BookingStop {
  final String id;
  final String spotId;
  final String spotName;
  final double latitude;
  final double longitude;
  final double fare;

  const BookingStop({
    this.id = '',
    required this.spotId,
    required this.spotName,
    required this.latitude,
    required this.longitude,
    required this.fare,
  });

  factory BookingStop.fromMap(Map<String, dynamic> map) => BookingStop(
    id: map['id'] ?? '',
    spotId: map['spotId'] ?? '',
    spotName: map['spotName'] ?? '',
    latitude: (map['latitude'] ?? 0.0).toDouble(),
    longitude: (map['longitude'] ?? 0.0).toDouble(),
    fare: (map['fare'] ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'spotId': spotId,
    'spotName': spotName,
    'latitude': latitude,
    'longitude': longitude,
    'fare': fare,
  };
}

class BookingRouteChange {
  final String id;
  final String requestedBy;
  final String requestedRole;
  final String type;
  final String? targetStopId;
  final List<String> proposedOrder;
  final String reason;
  final DateTime createdAt;

  const BookingRouteChange({
    required this.id,
    required this.requestedBy,
    required this.requestedRole,
    required this.type,
    this.targetStopId,
    this.proposedOrder = const [],
    required this.reason,
    required this.createdAt,
  });

  factory BookingRouteChange.fromMap(Map<String, dynamic> map) =>
      BookingRouteChange(
        id: map['id'] ?? '',
        requestedBy: map['requestedBy'] ?? '',
        requestedRole: map['requestedRole'] ?? '',
        type: map['type'] ?? '',
        targetStopId: map['targetStopId'],
        proposedOrder: List<String>.from(map['proposedOrder'] ?? const []),
        reason: map['reason'] ?? '',
        createdAt: map['createdAt'] == null
            ? DateTime.now()
            : DateTime.parse(map['createdAt']),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'requestedBy': requestedBy,
    'requestedRole': requestedRole,
    'type': type,
    'targetStopId': targetStopId,
    'proposedOrder': proposedOrder,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };
}

class BookingModel {
  final String id;
  final String touristId;
  final String touristName;
  final String? driverId;
  final String? driverName;
  final String? driverPlate;
  final List<BookingStop> stops;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final int passengerCount;
  final String luggageNotes;
  final String accessibilityNeeds;
  final double baseFare;
  final double totalFare;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final DateTime? dispatchExpiresAt;
  final DateTime? offerExpiresAt;
  final DateTime? acceptedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? replacementRequestedAt;
  final String? replacementReason;
  final BookingRouteChange? pendingRouteChange;
  final bool routeAdjustmentRequired;
  final DateTime? interruptedAt;
  final String? interruptionReason;
  final DateTime? touristWaitConfirmedAt;
  final DateTime? lastRouteDeviationAt;
  final String? cancellationReason;
  final double? driverRating;
  final String? driverReview;
  final int freeCancellationMinutes;
  final int acceptedCancellationPercent;
  final int driverWaitMinutes;
  final int noShowFeePercent;
  final TripRecord trip;

  bool get isActive =>
      status == BookingStatus.scheduled ||
      status == BookingStatus.pending ||
      status == BookingStatus.accepted ||
      status == BookingStatus.replacementPending ||
      status == BookingStatus.ongoing;
  int get quotedCents => (totalFare * 100).round();
  int get amountDueCents => trip.reviewRequired
      ? 0
      : ((trip.finalChargeCents ?? 0) - trip.receivedCents).clamp(
          0,
          quotedCents,
        );
  int get refundDueCents => trip.reviewRequired
      ? 0
      : (trip.receivedCents - (trip.finalChargeCents ?? trip.receivedCents))
            .clamp(0, quotedCents);
  DateTime? get freeCancellationUntil =>
      acceptedAt?.add(Duration(minutes: freeCancellationMinutes));
  bool get isWithinFreeCancellation =>
      freeCancellationUntil == null ||
      !DateTime.now().isAfter(freeCancellationUntil!);
  int get lateCancellationFeeCents =>
      (quotedCents * acceptedCancellationPercent / 100).round();
  int get noShowFeeCents => (quotedCents * noShowFeePercent / 100).round();
  bool get isDispatchExpired =>
      status == BookingStatus.pending &&
      dispatchExpiresAt != null &&
      !DateTime.now().isBefore(dispatchExpiresAt!);
  bool get isOfferExpired =>
      offerExpiresAt != null && !DateTime.now().isBefore(offerExpiresAt!);

  const BookingModel({
    required this.id,
    required this.touristId,
    required this.touristName,
    this.driverId,
    this.driverName,
    this.driverPlate,
    required this.stops,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.passengerCount = 1,
    this.luggageNotes = '',
    this.accessibilityNeeds = '',
    required this.baseFare,
    required this.totalFare,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.unpaid,
    this.status = BookingStatus.pending,
    required this.createdAt,
    this.scheduledAt,
    this.dispatchExpiresAt,
    this.offerExpiresAt,
    this.acceptedAt,
    this.startedAt,
    this.completedAt,
    this.replacementRequestedAt,
    this.replacementReason,
    this.pendingRouteChange,
    this.routeAdjustmentRequired = false,
    this.interruptedAt,
    this.interruptionReason,
    this.touristWaitConfirmedAt,
    this.lastRouteDeviationAt,
    this.cancellationReason,
    this.driverRating,
    this.driverReview,
    this.freeCancellationMinutes = 5,
    this.acceptedCancellationPercent = 20,
    this.driverWaitMinutes = 10,
    this.noShowFeePercent = 50,
    this.trip = const TripRecord(),
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingModel(
      id: id,
      touristId: map['touristId'] ?? '',
      touristName: map['touristName'] ?? '',
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPlate: map['driverPlate'],
      stops:
          (map['stops'] as List<dynamic>?)
              ?.map((s) => BookingStop.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      pickupLat: (map['pickupLat'] ?? 0.0).toDouble(),
      pickupLng: (map['pickupLng'] ?? 0.0).toDouble(),
      pickupAddress: map['pickupAddress'] ?? '',
      passengerCount: map['passengerCount'] ?? 1,
      luggageNotes: map['luggageNotes'] ?? '',
      accessibilityNeeds: map['accessibilityNeeds'] ?? '',
      baseFare: (map['baseFare'] ?? 0.0).toDouble(),
      totalFare: (map['totalFare'] ?? 0.0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (p) => p.name == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (p) => p.name == map['paymentStatus'],
        orElse: () => PaymentStatus.unpaid,
      ),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      scheduledAt: map['scheduledAt'] == null
          ? null
          : DateTime.parse(map['scheduledAt']),
      dispatchExpiresAt: map['dispatchExpiresAt'] == null
          ? null
          : DateTime.parse(map['dispatchExpiresAt']),
      offerExpiresAt: map['offerExpiresAt'] == null
          ? null
          : DateTime.parse(map['offerExpiresAt']),
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.parse(map['acceptedAt'])
          : null,
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      replacementRequestedAt: map['replacementRequestedAt'] == null
          ? null
          : DateTime.parse(map['replacementRequestedAt']),
      replacementReason: map['replacementReason'],
      pendingRouteChange: map['pendingRouteChange'] == null
          ? null
          : BookingRouteChange.fromMap(
              Map<String, dynamic>.from(map['pendingRouteChange']),
            ),
      routeAdjustmentRequired: map['routeAdjustmentRequired'] ?? false,
      interruptedAt: map['interruptedAt'] == null
          ? null
          : DateTime.parse(map['interruptedAt']),
      interruptionReason: map['interruptionReason'],
      touristWaitConfirmedAt: map['touristWaitConfirmedAt'] == null
          ? null
          : DateTime.parse(map['touristWaitConfirmedAt']),
      lastRouteDeviationAt: map['lastRouteDeviationAt'] == null
          ? null
          : DateTime.parse(map['lastRouteDeviationAt']),
      cancellationReason: map['cancellationReason'],
      driverRating: (map['driverRating'] as num?)?.toDouble(),
      driverReview: map['driverReview'],
      freeCancellationMinutes: map['freeCancellationMinutes'] ?? 5,
      acceptedCancellationPercent: map['acceptedCancellationPercent'] ?? 20,
      driverWaitMinutes: map['driverWaitMinutes'] ?? 10,
      noShowFeePercent: map['noShowFeePercent'] ?? 50,
      trip: map['trip'] == null
          ? const TripRecord()
          : TripRecord.fromMap(Map<String, dynamic>.from(map['trip'])),
    );
  }

  Map<String, dynamic> toMap() => {
    'touristId': touristId,
    'touristName': touristName,
    'driverId': driverId,
    'driverName': driverName,
    'driverPlate': driverPlate,
    'stops': stops.map((s) => s.toMap()).toList(),
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'pickupAddress': pickupAddress,
    'passengerCount': passengerCount,
    'luggageNotes': luggageNotes,
    'accessibilityNeeds': accessibilityNeeds,
    'baseFare': baseFare,
    'totalFare': totalFare,
    'paymentMethod': paymentMethod.name,
    'paymentStatus': paymentStatus.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'scheduledAt': scheduledAt?.toIso8601String(),
    'dispatchExpiresAt': dispatchExpiresAt?.toIso8601String(),
    'offerExpiresAt': offerExpiresAt?.toIso8601String(),
    'acceptedAt': acceptedAt?.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'replacementRequestedAt': replacementRequestedAt?.toIso8601String(),
    'replacementReason': replacementReason,
    'pendingRouteChange': pendingRouteChange?.toMap(),
    'routeAdjustmentRequired': routeAdjustmentRequired,
    'interruptedAt': interruptedAt?.toIso8601String(),
    'interruptionReason': interruptionReason,
    'touristWaitConfirmedAt': touristWaitConfirmedAt?.toIso8601String(),
    'lastRouteDeviationAt': lastRouteDeviationAt?.toIso8601String(),
    'cancellationReason': cancellationReason,
    'driverRating': driverRating,
    'driverReview': driverReview,
    'freeCancellationMinutes': freeCancellationMinutes,
    'acceptedCancellationPercent': acceptedCancellationPercent,
    'driverWaitMinutes': driverWaitMinutes,
    'noShowFeePercent': noShowFeePercent,
    'trip': trip.toMap(),
  };

  BookingModel copyWith({
    String? id,
    String? touristId,
    String? touristName,
    String? driverId,
    String? driverName,
    String? driverPlate,
    List<BookingStop>? stops,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    int? passengerCount,
    String? luggageNotes,
    String? accessibilityNeeds,
    double? baseFare,
    double? totalFare,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? scheduledAt,
    DateTime? dispatchExpiresAt,
    DateTime? offerExpiresAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? replacementRequestedAt,
    String? replacementReason,
    BookingRouteChange? pendingRouteChange,
    bool? routeAdjustmentRequired,
    DateTime? interruptedAt,
    String? interruptionReason,
    DateTime? touristWaitConfirmedAt,
    DateTime? lastRouteDeviationAt,
    String? cancellationReason,
    double? driverRating,
    String? driverReview,
    int? freeCancellationMinutes,
    int? acceptedCancellationPercent,
    int? driverWaitMinutes,
    int? noShowFeePercent,
    TripRecord? trip,
  }) {
    return BookingModel(
      id: id ?? this.id,
      touristId: touristId ?? this.touristId,
      touristName: touristName ?? this.touristName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPlate: driverPlate ?? this.driverPlate,
      stops: stops ?? this.stops,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      passengerCount: passengerCount ?? this.passengerCount,
      luggageNotes: luggageNotes ?? this.luggageNotes,
      accessibilityNeeds: accessibilityNeeds ?? this.accessibilityNeeds,
      baseFare: baseFare ?? this.baseFare,
      totalFare: totalFare ?? this.totalFare,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      dispatchExpiresAt: dispatchExpiresAt ?? this.dispatchExpiresAt,
      offerExpiresAt: offerExpiresAt ?? this.offerExpiresAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      replacementRequestedAt:
          replacementRequestedAt ?? this.replacementRequestedAt,
      replacementReason: replacementReason ?? this.replacementReason,
      pendingRouteChange: pendingRouteChange ?? this.pendingRouteChange,
      routeAdjustmentRequired:
          routeAdjustmentRequired ?? this.routeAdjustmentRequired,
      interruptedAt: interruptedAt ?? this.interruptedAt,
      interruptionReason: interruptionReason ?? this.interruptionReason,
      touristWaitConfirmedAt:
          touristWaitConfirmedAt ?? this.touristWaitConfirmedAt,
      lastRouteDeviationAt: lastRouteDeviationAt ?? this.lastRouteDeviationAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      driverRating: driverRating ?? this.driverRating,
      driverReview: driverReview ?? this.driverReview,
      freeCancellationMinutes:
          freeCancellationMinutes ?? this.freeCancellationMinutes,
      acceptedCancellationPercent:
          acceptedCancellationPercent ?? this.acceptedCancellationPercent,
      driverWaitMinutes: driverWaitMinutes ?? this.driverWaitMinutes,
      noShowFeePercent: noShowFeePercent ?? this.noShowFeePercent,
      trip: trip ?? this.trip,
    );
  }
}
