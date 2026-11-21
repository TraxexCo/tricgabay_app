import 'package:flutter/material.dart';

/// A rounded box border for filled text fields that keeps the floating label
/// *inside* the field.
///
/// [OutlineInputBorder] floats the label onto the top border line. On a
/// filled field that makes the label straddle the edge of the coloured box
/// and overlap whatever sits above it. Reporting `isOutline == false` makes
/// the decorator lay the label out inside the fill instead, Material 3's
/// filled-field layout, while this class still paints a full rounded outline.
class FilledFieldBorder extends InputBorder {
  const FilledFieldBorder({
    super.borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final BorderRadius borderRadius;

  @override
  bool get isOutline => false;

  @override
  FilledFieldBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) => FilledFieldBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  FilledFieldBorder scale(double t) => FilledFieldBorder(
    borderSide: borderSide.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is FilledFieldBorder) {
      return FilledFieldBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is FilledFieldBorder) {
      return FilledFieldBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..addRRect(
      borderRadius
          .resolve(textDirection)
          .toRRect(rect)
          .deflate(borderSide.width),
    );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0,
    double gapPercentage = 0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    final outer = borderRadius.resolve(textDirection).toRRect(rect);
    canvas.drawRRect(outer.deflate(borderSide.width / 2), borderSide.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is FilledFieldBorder &&
      other.borderSide == borderSide &&
      other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}
