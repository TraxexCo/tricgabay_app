import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:math';

import 'package:uuid/uuid.dart';

typedef RecoveryRead = Future<String?> Function(String key);
typedef RecoveryWrite = Future<void> Function(String key, String value);
typedef RecoveryDelete = Future<void> Function(String key);

class PickupRecoveryMaterial {
  const PickupRecoveryMaterial({required this.requestId, required this.code});

  final String requestId;
  final String code;
}

String pickupRecoveryRequestKey(String userId, String bookingId) =>
    'pickup_recovery_request_${userId}_$bookingId';

String pickupRecoveryCodeKey(String userId, String bookingId) =>
    'pickup_recovery_code_${userId}_$bookingId';

/// Prepares a retry identity before the remote mutation. A partially written
/// pair is replaced before any RPC is sent; a complete pair is always reused.
Future<PickupRecoveryMaterial> preparePickupRecoveryMaterial({
  required String userId,
  required String bookingId,
  required RecoveryRead read,
  required RecoveryWrite write,
  String Function()? createRequestId,
  String Function()? createCode,
}) async {
  final requestKey = pickupRecoveryRequestKey(userId, bookingId);
  final codeKey = pickupRecoveryCodeKey(userId, bookingId);
  final existingRequestId = await read(requestKey);
  final existingCode = await read(codeKey);
  if (existingRequestId != null && existingCode != null) {
    return PickupRecoveryMaterial(
      requestId: existingRequestId,
      code: existingCode,
    );
  }

  final requestId = (createRequestId ?? () => const Uuid().v4())();
  final code =
      (createCode ?? () => (Random.secure().nextInt(9000) + 1000).toString())();
  await write(requestKey, requestId);
  await write(codeKey, code);
  return PickupRecoveryMaterial(requestId: requestId, code: code);
}

/// Writes the user-visible authoritative code before deleting retry material.
/// Therefore interruption during cleanup cannot lose the confirmed code.
Future<void> finalizePickupRecoveryMaterial({
  required String userId,
  required String bookingId,
  required String code,
  required RecoveryWrite write,
  required RecoveryDelete delete,
}) async {
  await write('pickup_code_${userId}_$bookingId', code);
  await delete(pickupRecoveryRequestKey(userId, bookingId));
  await delete(pickupRecoveryCodeKey(userId, bookingId));
}

/// A general reissue has its own server RPC but retains the existing durable
/// recovery-material lifecycle so transport loss cannot cause another rotation.
Future<String> reissuePickupWithMaterial({
  required String userId,
  required String bookingId,
  required RecoveryRead read,
  required RecoveryWrite write,
  required RecoveryDelete delete,
  required Future<String> Function(PickupRecoveryMaterial) issue,
}) async {
  final oldCode = await read('pickup_code_${userId}_$bookingId');
  final material = await preparePickupRecoveryMaterial(
    userId: userId,
    bookingId: bookingId,
    read: read,
    write: write,
    createCode: () {
      String code;
      do {
        code = (Random.secure().nextInt(9000) + 1000).toString();
      } while (code == oldCode);
      return code;
    },
  );
  final confirmed = await issue(material);
  if (confirmed != material.code) {
    throw StateError(MessageCode.codeReissueCouldNotBeConfirmed);
  }
  await finalizePickupRecoveryMaterial(
    userId: userId,
    bookingId: bookingId,
    code: confirmed,
    write: write,
    delete: delete,
  );
  return confirmed;
}
