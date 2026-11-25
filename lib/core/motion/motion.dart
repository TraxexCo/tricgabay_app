import 'package:flutter/material.dart';

/// Shared timing for every animation in the app, so motion feels like one
/// system. Nothing here should hold up input for longer than [long].
abstract final class Motion {
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration long = Duration(milliseconds: 420);

  /// Gap between items of a staggered entrance.
  static const Duration stagger = Duration(milliseconds: 55);

  /// Elements arriving on screen.
  static const Curve enter = Curves.easeOutCubic;

  /// Elements leaving or settling back.
  static const Curve exit = Curves.easeInCubic;

  /// Playful overshoot for confirmations.
  static const Curve pop = Curves.easeOutBack;

  /// True when the OS asks for reduced motion; show final states directly.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when motion is reduced.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
