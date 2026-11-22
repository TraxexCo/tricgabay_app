import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

import 'shared_widgets.dart';

/// The app logo shared between the launch screen and sign-in, so it flies and
/// shrinks into place instead of the two screens simply swapping.
class BrandLogoHero extends StatelessWidget {
  const BrandLogoHero({super.key, required this.size, this.showShadow = true});

  static const tag = 'brand-logo';

  /// Matches the native splash logo (128dp), so launch hands over seamlessly.
  static const launchSize = 128.0;

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    // Keep the circle crisp while it scales between the two sizes.
    // Scale one fixed-size logo during the flight; resizing AppLogo itself
    // would re-decode the image every frame.
    flightShuttleBuilder: (_, _, _, _, _) =>
        const FittedBox(child: AppLogo(size: launchSize, showShadow: true)),
    child: AppLogo(size: size, showShadow: showShadow),
  );
}

/// Shown while startup checks run (app version, privacy notice). It matches
/// the phone's native launch screen exactly (brand blue, 128dp logo in the
/// centre), so launch looks like one screen instead of flashing white.
class LaunchBarrier extends StatelessWidget {
  const LaunchBarrier({super.key, this.semanticsLabel});

  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: ColoredBox(
      color: AppColors.primary,
      child: Center(
        child: Semantics(
          label: semanticsLabel,
          child: const AppLogo(size: BrandLogoHero.launchSize),
        ),
      ),
    ),
  );
}
