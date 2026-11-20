import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tricgabay_app/core/services/cancellation_policy.dart';
import 'package:tricgabay_app/core/services/fare_policy.dart';
import 'package:tricgabay_app/core/state/offline_state_store.dart';

void main() {
  const userId = 'offline-test-user';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('rejects commands that could create financial or trip conflicts', () {
    expect(
      () => OfflineStateStore.enqueue(
        userId: userId,
        id: 'payment-1',
        type: 'capture_payment',
      ),
      throwsStateError,
    );
  });

  test('bounds the queue and keeps the newest safe acknowledgements', () async {
    for (var index = 0; index < 55; index++) {
      await OfflineStateStore.enqueue(
        userId: userId,
        id: 'read-$index',
        type: 'notification_read',
        payload: {'notification_id': '$index'},
      );
    }
    final replayed = <String>[];
    await OfflineStateStore.replay(userId, (command) async {
      replayed.add(command.id);
    });
    expect(replayed, hasLength(50));
    expect(replayed.first, 'read-5');
    expect(replayed.last, 'read-54');
  });

  test('keeps failed and later commands for a future retry', () async {
    for (final id in ['first', 'second', 'third']) {
      await OfflineStateStore.enqueue(
        userId: userId,
        id: id,
        type: 'notification_read',
        payload: {'notification_id': id},
      );
    }
    await OfflineStateStore.replay(userId, (command) async {
      if (command.id == 'second') throw StateError('offline');
    });
    final retry = <String>[];
    await OfflineStateStore.replay(userId, (command) async {
      retry.add(command.id);
    });
    expect(retry, ['second', 'third']);
  });

  test('clearUser removes both cached snapshot and pending commands', () async {
    await OfflineStateStore.saveSnapshot(
      userId: userId,
      bookings: const [],
      spots: const [],
      farePolicy: const FarePolicy(),
      cancellationPolicy: const CancellationPolicy(),
    );
    await OfflineStateStore.enqueue(
      userId: userId,
      id: 'read-before-logout',
      type: 'notification_read',
      payload: {'notification_id': 'notice-1'},
    );

    await OfflineStateStore.clearUser(userId);

    final replayed = <String>[];
    await OfflineStateStore.replay(userId, (command) async {
      replayed.add(command.id);
    });
    expect(replayed, isEmpty);
    expect(await OfflineStateStore.restoreSnapshot(userId), isNull);
  });
}
