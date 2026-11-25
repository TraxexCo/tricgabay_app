/// Independent authoritative reads invalidated by realtime changes.
enum RemoteSection {
  fares,
  cancellationPolicy,
  spots,
  bookings,
  directory,
  notifications,
  feedback,
  capabilities,
  alerts,
}

const realtimeSections = <String, RemoteSection>{
  'bookings': RemoteSection.bookings,
  'booking_offers': RemoteSection.bookings,
  'booking_route_changes': RemoteSection.bookings,
  'payments': RemoteSection.bookings,
  'refunds': RemoteSection.bookings,
  'cash_confirmations': RemoteSection.bookings,
  'booking_reviews': RemoteSection.bookings,
  'trip_events': RemoteSection.bookings,
  'booking_stops': RemoteSection.bookings,
  'tourist_spots': RemoteSection.spots,
  'notifications': RemoteSection.notifications,
  'profiles': RemoteSection.directory,
  'driver_profiles': RemoteSection.directory,
  'fare_revisions': RemoteSection.fares,
  'cancellation_policies': RemoteSection.cancellationPolicy,
  'feedback': RemoteSection.feedback,
  'admin_capabilities': RemoteSection.capabilities,
  'operational_alerts': RemoteSection.alerts,
};

/// RLS-filtered location payloads only patch drivers already visible locally.
/// Ignore delayed events so they cannot move the map back to an older sample.
List<Map<String, dynamic>> patchDriverLocation(
  List<Map<String, dynamic>> drivers,
  Map<String, dynamic> row,
) => drivers.map((driver) {
  if (driver['id'] != row['driver_id']) return driver;
  final incoming = DateTime.tryParse(row['recorded_at']?.toString() ?? '');
  final existing = DateTime.tryParse(
    driver['locationUpdatedAt']?.toString() ?? '',
  );
  if (incoming != null && existing != null && incoming.isBefore(existing)) {
    return driver;
  }
  return {
    ...driver,
    'lat': row['latitude'],
    'lng': row['longitude'],
    'accuracy': row['accuracy_meters'],
    'heading': row['heading'],
    'speed': row['speed_mps'],
    'locationUpdatedAt': row['recorded_at'],
  };
}).toList();

/// Heartbeats change every upload; only visible profile fields invalidate reads.
bool driverProfileNeedsRefresh(
  Map<String, dynamic>? previous,
  Map<String, dynamic> row,
) =>
    previous == null ||
    previous.entries.any(
      (entry) =>
          entry.key != 'last_seen_at' &&
          entry.key != 'updated_at' &&
          entry.value != row[entry.key],
    );
