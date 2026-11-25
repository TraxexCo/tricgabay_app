import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/pickup_recovery_material.dart';

class MemoryRecoveryStore {
  final values = <String, String>{};
  int writes = 0;
  int deletes = 0;
  int? failWriteAt;
  int? failDeleteAt;

  Future<String?> read(String key) async => values[key];

  Future<void> write(String key, String value) async {
    writes += 1;
    if (writes == failWriteAt) throw StateError('injected write interruption');
    values[key] = value;
  }

  Future<void> delete(String key) async {
    deletes += 1;
    if (deletes == failDeleteAt) {
      throw StateError('injected delete interruption');
    }
    values.remove(key);
  }
}

void main() {
  const userId = 'tourist-1';
  const bookingId = 'booking-1';

  test(
    'complete persisted recovery material survives an app restart',
    () async {
      final store = MemoryRecoveryStore();
      final first = await preparePickupRecoveryMaterial(
        userId: userId,
        bookingId: bookingId,
        read: store.read,
        write: store.write,
        createRequestId: () => 'request-a',
        createCode: () => '4827',
      );
      final restarted = await preparePickupRecoveryMaterial(
        userId: userId,
        bookingId: bookingId,
        read: store.read,
        write: store.write,
        createRequestId: () => 'request-b',
        createCode: () => '1954',
      );
      expect(first.requestId, 'request-a');
      expect(restarted.requestId, 'request-a');
      expect(restarted.code, '4827');
      expect(store.writes, 2);
    },
  );

  test(
    'interruption between material writes is repaired before an RPC',
    () async {
      final store = MemoryRecoveryStore()..failWriteAt = 2;
      await expectLater(
        preparePickupRecoveryMaterial(
          userId: userId,
          bookingId: bookingId,
          read: store.read,
          write: store.write,
          createRequestId: () => 'incomplete-request',
          createCode: () => '1111',
        ),
        throwsStateError,
      );
      store.failWriteAt = null;
      final repaired = await preparePickupRecoveryMaterial(
        userId: userId,
        bookingId: bookingId,
        read: store.read,
        write: store.write,
        createRequestId: () => 'replacement-request',
        createCode: () => '2356',
      );
      expect(repaired.requestId, 'replacement-request');
      expect(repaired.code, '2356');
    },
  );

  test(
    'cleanup interruption cannot erase the authoritative pickup code',
    () async {
      final store = MemoryRecoveryStore()..failDeleteAt = 1;
      store.values[pickupRecoveryRequestKey(userId, bookingId)] = 'request-a';
      store.values[pickupRecoveryCodeKey(userId, bookingId)] = '4827';
      await expectLater(
        finalizePickupRecoveryMaterial(
          userId: userId,
          bookingId: bookingId,
          code: '4827',
          write: store.write,
          delete: store.delete,
        ),
        throwsStateError,
      );
      expect(store.values['pickup_code_${userId}_$bookingId'], '4827');
      expect(
        store.values[pickupRecoveryRequestKey(userId, bookingId)],
        'request-a',
      );
      expect(store.values[pickupRecoveryCodeKey(userId, bookingId)], '4827');
    },
  );
}
