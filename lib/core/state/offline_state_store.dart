import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/booking_model.dart';
import '../../models/tourist_spot_model.dart';
import '../services/cancellation_policy.dart';
import '../services/fare_policy.dart';

class CachedAppSnapshot {
  final DateTime savedAt;
  final List<BookingModel> bookings;
  final List<TouristSpotModel> spots;
  final FarePolicy farePolicy;
  final CancellationPolicy cancellationPolicy;

  const CachedAppSnapshot({
    required this.savedAt,
    required this.bookings,
    required this.spots,
    required this.farePolicy,
    required this.cancellationPolicy,
  });

  bool get isStale =>
      DateTime.now().difference(savedAt) > const Duration(hours: 24);
}

class OfflineCommand {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;

  const OfflineCommand({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'payload': payload,
    'created_at': createdAt.toUtc().toIso8601String(),
    'attempts': attempts,
  };

  factory OfflineCommand.fromMap(Map<String, dynamic> map) => OfflineCommand(
    id: map['id'] as String,
    type: map['type'] as String,
    payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
    createdAt: DateTime.parse(map['created_at'] as String),
    attempts: map['attempts'] as int? ?? 0,
  );
}

/// A bounded, user-scoped cache and replay queue.
///
/// Only idempotent convenience commands are accepted. Booking, matching,
/// pickup, payment, cancellation, settlement, and trip transitions are never
/// queued: those actions must receive a current server response.
class OfflineStateStore {
  OfflineStateStore._();

  static const _schemaVersion = 1;
  static const _safeCommandTypes = {
    'notification_read',
    'notifications_read_all',
  };
  static SharedPreferences? _preferences;

  static Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static String _snapshotKey(String userId) =>
      'offline_snapshot_v$_schemaVersion:$userId';
  static String _queueKey(String userId) =>
      'offline_queue_v$_schemaVersion:$userId';

  static Future<void> saveSnapshot({
    required String userId,
    required List<BookingModel> bookings,
    required List<TouristSpotModel> spots,
    required FarePolicy farePolicy,
    required CancellationPolicy cancellationPolicy,
  }) async {
    await initialize();
    final boundedBookings = bookings.take(100).map((booking) {
      final map = booking.toMap();
      final trip = Map<String, dynamic>.from(map['trip'] as Map);
      trip['pickupCode'] = '';
      map['trip'] = trip;
      return {'id': booking.id, ...map};
    }).toList();
    final boundedSpots = spots
        .take(100)
        .map((spot) => {'id': spot.id, ...spot.toMap()})
        .toList();
    final encoded = jsonEncode({
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'bookings': boundedBookings,
      'spots': boundedSpots,
      'fare_policy': farePolicy.toMap(),
      'cancellation_policy': {
        'version': cancellationPolicy.version,
        'free_cancellation_minutes': cancellationPolicy.freeCancellationMinutes,
        'accepted_trip_fee_percent': cancellationPolicy.acceptedTripFeePercent,
        'driver_wait_minutes': cancellationPolicy.driverWaitMinutes,
        'no_show_fee_percent': cancellationPolicy.noShowFeePercent,
        'terms': cancellationPolicy.terms,
      },
    });
    await _preferences!.setString(_snapshotKey(userId), encoded);
  }

  static Future<CachedAppSnapshot?> restoreSnapshot(String userId) async {
    await initialize();
    final raw = _preferences!.getString(_snapshotKey(userId));
    if (raw == null) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final cancellation = Map<String, dynamic>.from(
        map['cancellation_policy'] as Map,
      );
      return CachedAppSnapshot(
        savedAt: DateTime.parse(map['saved_at'] as String).toLocal(),
        bookings: (map['bookings'] as List).map((item) {
          final value = Map<String, dynamic>.from(item as Map);
          return BookingModel.fromMap(value, value['id'] as String);
        }).toList(),
        spots: (map['spots'] as List).map((item) {
          final value = Map<String, dynamic>.from(item as Map);
          return TouristSpotModel.fromMap(value, value['id'] as String);
        }).toList(),
        farePolicy: FarePolicy.fromMap(
          Map<String, dynamic>.from(map['fare_policy'] as Map),
        ),
        cancellationPolicy: CancellationPolicy(
          version: cancellation['version'] as int? ?? 1,
          freeCancellationMinutes:
              cancellation['free_cancellation_minutes'] as int? ?? 5,
          acceptedTripFeePercent:
              cancellation['accepted_trip_fee_percent'] as int? ?? 20,
          driverWaitMinutes: cancellation['driver_wait_minutes'] as int? ?? 10,
          noShowFeePercent: cancellation['no_show_fee_percent'] as int? ?? 50,
          terms: cancellation['terms'] as String? ?? '',
        ),
      );
    } catch (_) {
      await _preferences!.remove(_snapshotKey(userId));
      return null;
    }
  }

  static Future<void> enqueue({
    required String userId,
    required String id,
    required String type,
    Map<String, dynamic> payload = const {},
  }) async {
    if (!_safeCommandTypes.contains(type)) {
      throw StateError(MessageCode.offlineReplayUnsafe);
    }
    await initialize();
    final commands = await _readQueue(userId);
    if (commands.any((command) => command.id == id)) return;
    final combined = [
      ...commands,
      OfflineCommand(
        id: id,
        type: type,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    ];
    final next = combined.length <= 50
        ? combined
        : combined.sublist(combined.length - 50);
    await _writeQueue(userId, next);
  }

  static Future<void> replay(
    String userId,
    Future<void> Function(OfflineCommand command) execute,
  ) async {
    final commands = await _readQueue(userId);
    if (commands.isEmpty) return;
    final remaining = <OfflineCommand>[];
    for (var index = 0; index < commands.length; index++) {
      final command = commands[index];
      if (DateTime.now().difference(command.createdAt) >
              const Duration(days: 7) ||
          command.attempts >= 5) {
        continue;
      }
      try {
        await execute(command);
      } catch (_) {
        remaining.add(
          OfflineCommand(
            id: command.id,
            type: command.type,
            payload: command.payload,
            createdAt: command.createdAt,
            attempts: command.attempts + 1,
          ),
        );
        remaining.addAll(commands.skip(index + 1));
        break;
      }
    }
    await _writeQueue(userId, remaining);
  }

  static Future<void> clearUser(String userId) async {
    await initialize();
    await _preferences!.remove(_snapshotKey(userId));
    await _preferences!.remove(_queueKey(userId));
  }

  static Future<List<OfflineCommand>> _readQueue(String userId) async {
    await initialize();
    final raw = _preferences!.getString(_queueKey(userId));
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map(
            (item) =>
                OfflineCommand.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
    } catch (_) {
      await _preferences!.remove(_queueKey(userId));
      return [];
    }
  }

  static Future<void> _writeQueue(
    String userId,
    List<OfflineCommand> commands,
  ) async {
    await initialize();
    await _preferences!.setString(
      _queueKey(userId),
      jsonEncode(commands.map((command) => command.toMap()).toList()),
    );
  }
}
