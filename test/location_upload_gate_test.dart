import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/location_upload_gate.dart';

void main() {
  late LocationUploadGate gate;
  late DateTime now;
  late int writes;
  Future<bool> send({
    int seconds = 0,
    double lat = 14.95,
    String owner = 'a',
    Future<void> Function()? write,
  }) => gate.publish(
    owner: owner,
    latitude: lat,
    longitude: 120.92,
    now: now.add(Duration(seconds: seconds)),
    write:
        write ??
        () async {
          writes++;
        },
  );
  setUp(() {
    gate = LocationUploadGate();
    now = DateTime.utc(2026);
    writes = 0;
  });
  test('moving samples require five seconds and fifteen metres', () async {
    expect(await send(), isTrue);
    expect(await send(seconds: 4, lat: 14.96), isFalse);
    expect(await send(seconds: 5, lat: 14.95001), isFalse);
    expect(await send(seconds: 5, lat: 14.96), isTrue);
    expect(writes, 2);
  });
  test('stationary drivers publish at the thirty-second heartbeat', () async {
    await send();
    expect(await send(seconds: 29), isFalse);
    expect(await send(seconds: 30), isTrue);
  });
  test('simultaneous streams cannot overlap writes', () async {
    final pending = Completer<void>();
    final first = send(write: () => pending.future);
    expect(await send(seconds: 6, lat: 14.96), isFalse);
    pending.complete();
    expect(await first, isTrue);
  });
  test('failed writes can retry without waiting for throttle', () async {
    await expectLater(
      send(
        write: () async {
          throw StateError('offline');
        },
      ),
      throwsStateError,
    );
    expect(await send(), isTrue);
  });
  test(
    'logout and account switch discard old in-flight throttle state',
    () async {
      final pending = Completer<void>();
      final first = send(write: () => pending.future);
      gate.reset();
      expect(await send(owner: 'b'), isTrue);
      pending.complete();
      await first;
      expect(await send(owner: 'b', seconds: 1, lat: 14.96), isFalse);
    },
  );
}
