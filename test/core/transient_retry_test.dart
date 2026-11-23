import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tricgabay_app/core/services/transient_retry.dart';

void main() {
  const fast = [Duration(milliseconds: 1), Duration(milliseconds: 1)];

  test('a dropped connection that recovers is retried silently', () async {
    var calls = 0;
    final value = await retryTransient(
      () async {
        calls++;
        if (calls < 3) throw const SocketException('reset');
        return 'ok';
      },
      label: 'test',
      delays: fast,
    );
    expect(value, 'ok');
    expect(calls, 3);
  });

  test(
    'a failure that keeps happening is rethrown after the retries',
    () async {
      var calls = 0;
      await expectLater(
        retryTransient(
          () async {
            calls++;
            throw const SocketException('down');
          },
          label: 'test',
          delays: fast,
        ),
        throwsA(isA<SocketException>()),
      );
      expect(calls, 3);
    },
  );

  test('a real server refusal is not retried', () async {
    var calls = 0;
    await expectLater(
      retryTransient(
        () async {
          calls++;
          throw const PostgrestException(message: 'denied', code: '42501');
        },
        label: 'test',
        delays: fast,
      ),
      throwsA(isA<PostgrestException>()),
    );
    expect(calls, 1);
  });

  test('a request that never answers is cut off and retried', () async {
    var calls = 0;
    final value = await retryTransient(
      () {
        calls++;
        return calls == 1
            ? Completer<String>().future
            : Future.value('late but fine');
      },
      label: 'test',
      delays: fast,
      timeout: const Duration(milliseconds: 20),
    );
    expect(value, 'late but fine');
    expect(calls, 2);
  });

  test('which errors count as transient', () {
    expect(isTransientFailure(const SocketException('x')), isTrue);
    expect(isTransientFailure(TimeoutException('x')), isTrue);
    expect(
      isTransientFailure(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      ),
      isTrue,
    );
    expect(
      isTransientFailure(const PostgrestException(message: 'x', code: '500')),
      isTrue,
    );
    expect(
      isTransientFailure(const PostgrestException(message: 'x', code: '42501')),
      isFalse,
    );
    expect(isTransientFailure(StateError('x')), isFalse);
  });
}
