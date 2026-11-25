import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/avatar_replacement_service.dart';

void main() {
  late FakeAvatarStore store;
  late List<String> diagnostics;
  late AvatarReplacementService service;

  setUp(() {
    store = FakeAvatarStore();
    diagnostics = [];
    service = AvatarReplacementService(
      store: store,
      newId: () => 'version-2',
      isReferenced: (_) async => false,
      onCleanupFailure: (name, _, _) => diagnostics.add(name),
    );
  });

  test(
    'successful replacement updates profile before deleting old avatar',
    () async {
      final events = <String>[];
      store.events = events;
      final path = await service.replace(
        userId: 'user-1',
        bytes: jpeg,
        previousPath: 'user-1/avatar.jpg',
        updateProfile: (path) async => events.add('profile:$path'),
      );
      expect(path, 'user-1/avatars/version-2.jpg');
      expect(events, [
        'upload:user-1/avatars/version-2.jpg',
        'profile:user-1/avatars/version-2.jpg',
        'remove:user-1/avatar.jpg',
      ]);
    },
  );

  test('upload failure leaves profile and previous avatar untouched', () async {
    store.uploadError = StateError('upload failed');
    var profileWrites = 0;
    await expectLater(
      service.replace(
        userId: 'user-1',
        bytes: jpeg,
        previousPath: 'user-1/avatar.jpg',
        updateProfile: (_) async => profileWrites++,
      ),
      throwsStateError,
    );
    expect(profileWrites, 0);
    expect(store.removed, isEmpty);
  });

  test('profile failure removes only the new orphan', () async {
    await expectLater(
      service.replace(
        userId: 'user-1',
        bytes: jpeg,
        previousPath: 'user-1/avatar.jpg',
        updateProfile: (_) async => throw StateError('profile failed'),
      ),
      throwsStateError,
    );
    expect(store.removed, ['user-1/avatars/version-2.jpg']);
    expect(store.removed, isNot(contains('user-1/avatar.jpg')));
  });

  test('cleanup failure does not undo successful profile update', () async {
    store.removeError = StateError('cleanup failed');
    var writtenPath = '';
    final path = await service.replace(
      userId: 'user-1',
      bytes: png,
      previousPath: 'user-1/avatar.jpg',
      updateProfile: (value) async => writtenPath = value,
    );
    expect(path, writtenPath);
    expect(diagnostics, ['user-1/avatar.jpg']);
  });

  test('referenced previous object is retained', () async {
    service = AvatarReplacementService(
      store: store,
      newId: () => 'version-2',
      isReferenced: (_) async => true,
      onCleanupFailure: (name, _, _) => diagnostics.add(name),
    );
    await service.replace(
      userId: 'user-1',
      bytes: jpeg,
      previousPath: 'user-1/avatar.jpg',
      updateProfile: (_) async {},
    );
    expect(store.removed, isEmpty);
  });

  test('cross-owner previous object is never sent to delete', () async {
    await service.replace(
      userId: 'user-1',
      bytes: jpeg,
      previousPath: 'user-2/avatar.jpg',
      updateProfile: (_) async {},
    );
    expect(store.removed, isEmpty);
  });

  test(
    'profile and orphan cleanup failures preserve the original error',
    () async {
      store.removeError = StateError('cleanup failed');
      await expectLater(
        service.replace(
          userId: 'user-1',
          bytes: jpeg,
          previousPath: 'user-1/avatar.jpg',
          updateProfile: (_) async => throw StateError('profile failed'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(diagnostics, ['user-1/avatars/version-2.jpg']);
      expect(store.removed, isEmpty);
    },
  );

  test('invalid image is rejected before storage access', () async {
    await expectLater(
      service.replace(
        userId: 'user-1',
        bytes: Uint8List.fromList([1, 2, 3]),
        previousPath: null,
        updateProfile: (_) async {},
      ),
      throwsStateError,
    );
    expect(store.uploaded, isEmpty);
  });

  test('invalid owner path is rejected before storage access', () async {
    await expectLater(
      service.replace(
        userId: '../another-user',
        bytes: jpeg,
        previousPath: null,
        updateProfile: (_) async {},
      ),
      throwsStateError,
    );
    expect(store.uploaded, isEmpty);
  });
}

final jpeg = Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]);
final png = Uint8List.fromList([
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
]);

class FakeAvatarStore implements AvatarObjectStore {
  Object? uploadError;
  Object? removeError;
  List<String> events = [];
  final uploaded = <String>[];
  final removed = <String>[];

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (uploadError case final error?) throw error;
    uploaded.add(path);
    events.add('upload:$path');
  }

  @override
  Future<void> remove(String path) async {
    if (removeError case final error?) throw error;
    removed.add(path);
    events.add('remove:$path');
  }
}
