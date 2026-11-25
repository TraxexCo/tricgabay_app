import 'error_messages.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

/// One encrypted, account-scoped record survives retries and process death.
class BookingRequestMaterial {
  static Future<String> prepare({
    required String userId,
    required Map<String, dynamic> payload,
    required Future<String?> Function(String) read,
    required Future<void> Function(String, String) write,
  }) async {
    final key = 'booking_request_$userId';
    final fingerprint = jsonEncode(payload);
    final saved = await read(key);
    if (saved != null) {
      final record = jsonDecode(saved) as Map<String, dynamic>;
      if (record['payload'] != fingerprint) {
        throw const ClientOperationException(ClientFailure.pendingBooking);
      }
      return record['id'] as String;
    }
    final id = const Uuid().v4();
    await write(key, jsonEncode({'id': id, 'payload': fingerprint}));
    return id;
  }
}

/// Do not recover a booking unless both request identity and ownership match.
String? matchingBookingRequest(
  Map<String, dynamic>? row, {
  required String userId,
  required String requestId,
}) {
  if (row == null ||
      row['tourist_id'] != userId ||
      row['client_request_id'] != requestId) {
    return null;
  }
  return row['id'] as String?;
}

String? pendingBookingRequestId(String? stored) {
  if (stored == null) return null;
  try {
    return (jsonDecode(stored) as Map<String, dynamic>)['id'] as String?;
  } catch (_) {
    return null;
  }
}
