import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/image_upload_validator.dart';

void main() {
  group('profile image validation', () {
    test('accepts JPEG and PNG signatures', () {
      expect(
        ImageUploadValidator.validateProfileImage(
          Uint8List.fromList([0xff, 0xd8, 0xff, 0x00]),
        ),
        'image/jpeg',
      );
      expect(
        ImageUploadValidator.validateProfileImage(
          Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        ),
        'image/png',
      );
    });

    test('rejects unsupported and oversized content', () {
      expect(
        () => ImageUploadValidator.validateProfileImage(
          Uint8List.fromList([0x47, 0x49, 0x46]),
        ),
        throwsStateError,
      );
      expect(
        () => ImageUploadValidator.validateProfileImage(
          Uint8List(ImageUploadValidator.maxProfileBytes + 1),
        ),
        throwsStateError,
      );
    });
  });
}
