// Builds the square, transparent splash logos from the app logo photo.
// Run: dart run tool/make_splash_logo.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final source = img.decodeImage(
    File('assets/images/tric_gabay_logo.png').readAsBytesSync(),
  )!;
  // Centre-crop to a square, as AppLogo does with BoxFit.cover.
  final side = source.width < source.height ? source.width : source.height;
  final square = img.copyCrop(
    source,
    x: (source.width - side) ~/ 2,
    y: (source.height - side) ~/ 2,
    width: side,
    height: side,
  );

  // Pre-Android 12 and iOS: a 512px circular logo with a white ring, drawn at
  // 4x density so it appears at 128dp, the size Flutter's splash starts at.
  File('assets/images/splash_logo.png').writeAsBytesSync(
    img.encodePng(_circle(square, 512, ring: 22)),
  );

  // Android 12+: the system masks a 288dp icon to its central 192dp circle,
  // so the logo sits inside a transparent 960px canvas at 2/3 size.
  final android12 = img.Image(width: 960, height: 960, numChannels: 4);
  img.compositeImage(android12, _circle(square, 600, ring: 26), dstX: 180, dstY: 180);
  File('assets/images/splash_logo_android12.png').writeAsBytesSync(
    img.encodePng(android12),
  );
  stdout.writeln('splash logos written');
}

img.Image _circle(img.Image square, int size, {required int ring}) {
  final scaled = img.copyResize(
    square,
    width: size - ring * 2,
    height: size - ring * 2,
    interpolation: img.Interpolation.cubic,
  );
  final out = img.Image(width: size, height: size, numChannels: 4);
  final c = size / 2;
  final outer = c * c;
  final inner = (c - ring) * (c - ring);
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x + .5 - c, dy = y + .5 - c;
      final d = dx * dx + dy * dy;
      if (d > outer) continue;
      if (d > inner) {
        out.setPixelRgba(x, y, 255, 255, 255, 255);
      } else {
        final p = scaled.getPixel(x - ring, y - ring);
        out.setPixelRgba(x, y, p.r, p.g, p.b, 255);
      }
    }
  }
  return out;
}
