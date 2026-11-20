import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/navigation/launch_preferences.dart';
import '../../../core/widgets/brand_logo_hero.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/error_messages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreProfile});

  final Future<SignedInProfile?> Function()? restoreProfile;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // The first frame matches the native splash (brand blue, 128dp logo in the
  // centre), so launch looks like one continuous screen. The logo stays put
  // while the session restores, then flies into the sign-in header.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreAndOpen());
    });
  }

  Future<void> _restoreAndOpen() async {
    final load =
        widget.restoreProfile ??
        (BackendConfig.isConfigured ? AuthService.restoreSession : null);
    try {
      final profile = await load?.call();
      if (!mounted) return;
      if (profile != null &&
          (!BackendConfig.isConfigured ||
              BackendConfig.client.auth.currentUser?.id == profile.id)) {
        AppSession.setAuthenticatedUser(
          id: profile.id,
          name: profile.name,
          role: profile.applicationPending
              ? 'driver_pending'
              : profile.role.name,
          email: profile.email,
          plateNumber: profile.plateNumber,
        );
        unawaited(
          AppSession.syncRemoteState().catchError((Object error) {
            ErrorMessages.forError(error);
          }),
        );
      }
    } catch (error) {
      if (!mounted) return;
      AppSession.storageError.value = ErrorMessages.forError(error);
    }
    final seenIntro = await LaunchPreferences.onboardingSeen();
    if (!mounted) return;
    context.go(switch (AppSession.authenticatedRole) {
      'admin' => '/admin/dashboard',
      'driver' => '/driver/home',
      'driver_pending' => '/driver/application-pending',
      'tourist' => '/tourist/home',
      _ => seenIntro ? '/login' : '/onboarding',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            const Center(
              child: BrandLogoHero(
                size: BrandLogoHero.launchSize,
                showShadow: false,
              ),
            ),
            Align(
              alignment: const Alignment(0, .42),
              child: FadeSlideIn(
                delay: Motion.medium,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.appName(AppBrand.name),
                      style: GoogleFonts.poppins(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.yourGuideYourRideInBustos,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.surface.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
