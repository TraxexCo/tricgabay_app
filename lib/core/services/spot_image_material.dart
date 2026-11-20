import 'package:tricgabay_app/core/l10n/message_codes.g.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import 'image_upload_validator.dart';

class SpotImageMaterial {
  final String path, contentType;
  static const cacheControl = '31536000';
  const SpotImageMaterial._(this.path, this.contentType);
  factory SpotImageMaterial.create(
    String spotId,
    Uint8List bytes, {
    String? version,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(spotId)) {
      throw StateError(MessageCode.invalidAttractionImageOwner);
    }
    final mime = ImageUploadValidator.validateProfileImage(bytes);
    final id = version ?? const Uuid().v4();
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(id)) {
      throw StateError(MessageCode.invalidAttractionImageVersion);
    }
    final objectPath = '$spotId/$id.${mime == 'image/png' ? 'png' : 'jpg'}';
    ImageUploadValidator.validateForObject(
      bytes,
      path: objectPath,
      contentType: mime,
    );
    return SpotImageMaterial._(objectPath, mime);
  }
}
