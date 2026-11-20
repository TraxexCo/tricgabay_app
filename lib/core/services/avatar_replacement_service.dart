import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import 'image_upload_validator.dart';

abstract interface class AvatarObjectStore {
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  Future<void> remove(String path);
}

typedef AvatarProfileWriter = Future<void> Function(String newPath);
typedef AvatarReferenceChecker = Future<bool> Function(String objectPath);
typedef AvatarCleanupDiagnostic =
    void Function(String objectPath, Object error, StackTrace stack);

class AvatarReplacementService {
  final AvatarObjectStore store;
  final AvatarCleanupDiagnostic onCleanupFailure;
  final AvatarReferenceChecker isReferenced;
  final String Function() newId;

  AvatarReplacementService({
    required this.store,
    required this.onCleanupFailure,
    required this.isReferenced,
    String Function()? newId,
  }) : newId = newId ?? const Uuid().v4;

  Future<String> replace({
    required String userId,
    required Uint8List bytes,
    required String? previousPath,
    required AvatarProfileWriter updateProfile,
  }) async {
    final safeSegment = RegExp(r'^[A-Za-z0-9_-]+$');
    if (!safeSegment.hasMatch(userId)) {
      throw StateError(MessageCode.avatarOwnerIsInvalid);
    }
    final contentType = ImageUploadValidator.validateProfileImage(bytes);
    final extension = contentType == 'image/png' ? 'png' : 'jpg';
    final version = newId();
    if (!safeSegment.hasMatch(version)) {
      throw StateError(MessageCode.avatarObjectVersionIsInvalid);
    }
    final newPath = '$userId/avatars/$version.$extension';

    await store.upload(path: newPath, bytes: bytes, contentType: contentType);
    try {
      await updateProfile(newPath);
    } catch (_) {
      await _removeOrRecord(newPath);
      rethrow;
    }

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != newPath &&
        previousPath.startsWith('$userId/')) {
      try {
        if (!await isReferenced(previousPath)) {
          await _removeOrRecord(previousPath);
        }
      } catch (error, stack) {
        // A failed reference check must fail closed: retain the object and
        // record a bounded cleanup diagnostic for deliberate later review.
        onCleanupFailure(previousPath, error, stack);
      }
    }
    return newPath;
  }

  Future<void> _removeOrRecord(String path) async {
    try {
      await store.remove(path);
    } catch (error, stack) {
      // The storage path is needed for an administrator cleanup job. It is
      // owner-scoped and contains no image bytes, credentials, or profile data.
      onCleanupFailure(path, error, stack);
    }
  }
}
