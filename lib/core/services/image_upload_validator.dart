import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:typed_data';

class ImageUploadValidator {
  ImageUploadValidator._();

  static const int maxProfileBytes = 5 * 1024 * 1024;

  /// The destination extension and MIME must agree with the detected content.
  /// Original picker filenames are never trusted as the content type.
  static String validateForObject(
    Uint8List bytes, {
    required String path,
    required String contentType,
    bool jpegOnly = false,
  }) {
    final detected = validateProfileImage(bytes);
    final extension = path.split('.').last.toLowerCase();
    final expected = detected == 'image/png' ? 'png' : 'jpg';
    if (contentType != detected ||
        extension != expected ||
        (jpegOnly && detected != 'image/jpeg')) {
      throw StateError(
        MessageCode.imageContentMimeTypeAndFileExtensionMustMatch,
      );
    }
    return detected;
  }

  static String validateProfileImage(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxProfileBytes) {
      throw StateError(MessageCode.profileImagesMustBe5MbOrSmaller);
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return 'image/jpeg';
    }
    const pngSignature = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    if (bytes.length >= pngSignature.length) {
      var png = true;
      for (var index = 0; index < pngSignature.length; index++) {
        if (bytes[index] != pngSignature[index]) {
          png = false;
          break;
        }
      }
      if (png) return 'image/png';
    }
    throw StateError(MessageCode.profileImagesMustBeJpegOrPngFiles);
  }
}
