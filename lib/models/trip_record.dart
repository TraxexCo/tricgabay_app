/// Local transaction metadata. All money is stored in centavos.
enum TripActor { tourist, driver, admin, system }

class TripEvent {
  final DateTime at;
  final TripActor actor;
  final String description;
  const TripEvent(this.at, this.actor, this.description);
  Map<String, dynamic> toMap() => {
    'at': at.toIso8601String(),
    'actor': actor.name,
    'description': description,
  };
  factory TripEvent.fromMap(Map<String, dynamic> map) => TripEvent(
    DateTime.parse(map['at']),
    TripActor.values.byName(map['actor']),
    map['description'],
  );
}

class TripRecord {
  final int fareRevision;
  final String? packageId;
  final String? packageName;
  final String pickupCode;
  final DateTime? pickupArrivedAt;
  final DateTime? pickupWaitExpiresAt;
  final int confirmedStops;
  final bool arrivalPending;
  final int? finalChargeCents;
  final bool reviewRequired;
  final bool touristCashConfirmed;
  final bool driverCashConfirmed;
  final bool touristRefundConfirmed;
  final bool driverRefundConfirmed;
  final int receivedCents;
  final List<TripEvent> events;

  const TripRecord({
    this.fareRevision = 1,
    this.packageId,
    this.packageName,
    this.pickupCode = '',
    this.pickupArrivedAt,
    this.pickupWaitExpiresAt,
    this.confirmedStops = 0,
    this.arrivalPending = false,
    this.finalChargeCents,
    this.reviewRequired = false,
    this.touristCashConfirmed = false,
    this.driverCashConfirmed = false,
    this.touristRefundConfirmed = false,
    this.driverRefundConfirmed = false,
    this.receivedCents = 0,
    this.events = const [],
  });

  TripRecord copyWith({
    int? confirmedStops,
    DateTime? pickupArrivedAt,
    DateTime? pickupWaitExpiresAt,
    bool? arrivalPending,
    int? finalChargeCents,
    bool? reviewRequired,
    bool? touristCashConfirmed,
    bool? driverCashConfirmed,
    bool? touristRefundConfirmed,
    bool? driverRefundConfirmed,
    int? receivedCents,
    List<TripEvent>? events,
  }) => TripRecord(
    fareRevision: fareRevision,
    packageId: packageId,
    packageName: packageName,
    pickupCode: pickupCode,
    pickupArrivedAt: pickupArrivedAt ?? this.pickupArrivedAt,
    pickupWaitExpiresAt: pickupWaitExpiresAt ?? this.pickupWaitExpiresAt,
    confirmedStops: confirmedStops ?? this.confirmedStops,
    arrivalPending: arrivalPending ?? this.arrivalPending,
    finalChargeCents: finalChargeCents ?? this.finalChargeCents,
    reviewRequired: reviewRequired ?? this.reviewRequired,
    touristCashConfirmed: touristCashConfirmed ?? this.touristCashConfirmed,
    driverCashConfirmed: driverCashConfirmed ?? this.driverCashConfirmed,
    touristRefundConfirmed:
        touristRefundConfirmed ?? this.touristRefundConfirmed,
    driverRefundConfirmed: driverRefundConfirmed ?? this.driverRefundConfirmed,
    receivedCents: receivedCents ?? this.receivedCents,
    events: events ?? this.events,
  );

  Map<String, dynamic> toMap() => {
    'fareRevision': fareRevision,
    'packageId': packageId,
    'packageName': packageName,
    'pickupCode': pickupCode,
    'pickupArrivedAt': pickupArrivedAt?.toIso8601String(),
    'pickupWaitExpiresAt': pickupWaitExpiresAt?.toIso8601String(),
    'confirmedStops': confirmedStops,
    'arrivalPending': arrivalPending,
    'finalChargeCents': finalChargeCents,
    'reviewRequired': reviewRequired,
    'touristCashConfirmed': touristCashConfirmed,
    'driverCashConfirmed': driverCashConfirmed,
    'touristRefundConfirmed': touristRefundConfirmed,
    'driverRefundConfirmed': driverRefundConfirmed,
    'receivedCents': receivedCents,
    'events': events.map((e) => e.toMap()).toList(),
  };
  factory TripRecord.fromMap(Map<String, dynamic> map) => TripRecord(
    fareRevision: map['fareRevision'] ?? 1,
    packageId: map['packageId'],
    packageName: map['packageName'],
    pickupCode: map['pickupCode'] ?? '',
    pickupArrivedAt: map['pickupArrivedAt'] == null
        ? null
        : DateTime.parse(map['pickupArrivedAt']),
    pickupWaitExpiresAt: map['pickupWaitExpiresAt'] == null
        ? null
        : DateTime.parse(map['pickupWaitExpiresAt']),
    confirmedStops: map['confirmedStops'] ?? 0,
    arrivalPending: map['arrivalPending'] ?? false,
    finalChargeCents: map['finalChargeCents'],
    reviewRequired: map['reviewRequired'] ?? false,
    touristCashConfirmed: map['touristCashConfirmed'] ?? false,
    driverCashConfirmed: map['driverCashConfirmed'] ?? false,
    touristRefundConfirmed: map['touristRefundConfirmed'] ?? false,
    driverRefundConfirmed: map['driverRefundConfirmed'] ?? false,
    receivedCents: map['receivedCents'] ?? 0,
    events: (map['events'] as List? ?? [])
        .map((e) => TripEvent.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
  );
}
