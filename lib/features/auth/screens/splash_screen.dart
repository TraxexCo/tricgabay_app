import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/error_messages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.restoreProfile});

  final Future<SignedInProfile?> Function()? restoreProfile;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

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
        PrototypeSession.setAuthenticatedUser(
          id: profile.id,
          name: profile.name,
          role: profile.applicationPending
              ? 'driver_pending'
              : profile.role.name,
          email: profile.email,
          plateNumber: profile.plateNumber,
        );
        unawaited(
          PrototypeSession.syncRemoteState().catchError((Object error) {
            ErrorMessages.forError(error);
          }),
        );
      }
    } catch (error) {
      if (!mounted) return;
      PrototypeSession.storageError.value = ErrorMessages.forError(error);
    }
    if (!mounted) return;
    context.go(switch (PrototypeSession.authenticatedRole) {
      'admin' => '/admin/dashboard',
      'driver' => '/driver/home',
      'driver_pending' => '/driver/application-pending',
      'tourist' => '/tourist/home',
      _ => '/onboarding',
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Color(0xFF0F4C81)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLogo(size: 152, showShadow: true),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.appName(AppBrand.name),
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.yourGuideYourRideInBustos,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.surface.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
