// Combines build/screens/*.png into labelled contact sheets for review.
// Run: dart run tool/contact_sheet.dart
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final files = Directory('build/screens')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  const cols = 4, rows = 2, w = 312, h = 675, label = 22;
  final out = Directory('build/screens/sheets')..createSync(recursive: true);
  for (var s = 0; s * cols * rows < files.length; s++) {
    final sheet = img.Image(width: cols * w, height: rows * (h + label));
    img.fill(sheet, color: img.ColorRgb8(220, 220, 220));
    for (var i = 0; i < cols * rows; i++) {
      final index = s * cols * rows + i;
      if (index >= files.length) break;
      final shot = img.copyResize(
        img.decodePng(files[index].readAsBytesSync())!,
        width: w,
        height: h,
      );
      final x = (i % cols) * w, y = (i ~/ cols) * (h + label);
      img.compositeImage(sheet, shot, dstX: x, dstY: y + label);
      final name = files[index].uri.pathSegments.last.replaceAll('.png', '');
      img.drawString(sheet, name, font: img.arial14, x: x + 4, y: y + 4,
          color: img.ColorRgb8(0, 0, 0));
    }
    File('${out.path}/sheet_$s.png').writeAsBytesSync(img.encodePng(sheet));
  }
  stdout.writeln('sheets: ${(files.length / (cols * rows)).ceil()}');
}
