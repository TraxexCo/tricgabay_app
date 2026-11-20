import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/navigation/launch_preferences.dart';
import '../../../core/widgets/brand_logo_hero.dart';
import '../../../core/widgets/shared_widgets.dart';
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
  bool _framesHeld = false;

  @override
  void initState() {
    super.initState();
    // Keep the phone's native splash up until the logo image has decoded,
    // so the first Flutter frame never shows an empty circle.
    WidgetsBinding.instance.deferFirstFrame();
    _framesHeld = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_restoreAndOpen());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_framesHeld) return;
    // Also warm the smaller sign-in logo so the Hero lands on a ready image.
    unawaited(
      Future.wait([
        precacheImage(
          AppLogo.provider(context, BrandLogoHero.launchSize),
          context,
        ),
        precacheImage(AppLogo.provider(context, 92), context),
      ]).whenComplete(_releaseFrames),
    );
    // Never hold the screen for long if an image cannot load.
    _safety ??= Timer(const Duration(seconds: 2), _releaseFrames);
  }

  Timer? _safety;

  void _releaseFrames() {
    _safety?.cancel();
    if (!_framesHeld) return;
    _framesHeld = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  @override
  void dispose() {
    _releaseFrames();
    super.dispose();
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
              // Fade the tagline out as soon as the next screen starts arriving;
              // a replaced page otherwise stays visible underneath it.
              child: FadeTransition(
                opacity: ReverseAnimation(
                  CurvedAnimation(
                    parent:
                        ModalRoute.of(context)?.secondaryAnimation ??
                        kAlwaysDismissedAnimation,
                    curve: const Interval(0, .25),
                  ),
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}
