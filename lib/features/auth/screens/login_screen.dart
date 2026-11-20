import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/motion_widgets.dart';
import '../../../core/widgets/brand_logo_hero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

import '../../../core/session/app_session.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _isLoading = false;
  String _role = 'tourist';

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context
                .l10n
                .serverSetupIsIncompleteAddTheSupabaseBuildConfigurationBeforeSigningIn,
          ),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final role = _role == 'driver' ? AppRole.driver : AppRole.tourist;
      final profile = await AuthService.signIn(
        email: _emailCtrl.text,
        password: _pwdCtrl.text,
        expectedRole: role,
      );
      AppSession.setAuthenticatedUser(
        id: profile.id,
        name: profile.name,
        role: profile.applicationPending ? 'driver_pending' : profile.role.name,
        email: profile.email,
        plateNumber: profile.plateNumber,
      );
      await AppSession.syncRemoteState();
      if (!mounted) return;
      context.go(
        profile.applicationPending
            ? '/driver/application-pending'
            : profile.role == AppRole.driver
            ? '/driver/home'
            : '/tourist/home',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.message(ErrorMessages.forError(error)))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.isFilipino,
      builder: (context, isFilipino, _) {
        // Everything below the header enters in a short stagger after the
        // logo lands, so the screen assembles instead of appearing at once.
        final items = <Widget>[
          Text(
            context.l10n.welcomeBack,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.chooseYourWorkspaceThenSignInToContinue,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EFF5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _roleOption(
                  'tourist',
                  Icons.explore_outlined,
                  context.l10n.explore,
                ),
                _roleOption(
                  'driver',
                  Icons.electric_rickshaw_outlined,
                  context.l10n.drive,
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          AppTextField(
            controller: _emailCtrl,
            label: context.l10n.emailAddress,
            hint: context.l10n.enterYourEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) =>
                v == null || v.isEmpty ? MessageCode.emailIsRequired : null,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _pwdCtrl,
            label: context.l10n.password,
            hint: context.l10n.enterYourPassword,
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                v == null || v.isEmpty ? MessageCode.passwordIsRequired : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.push('/forgot-password'),
              child: Text(
                context.l10n.forgotPasswordLabel,
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: _role == 'tourist'
                ? context.l10n.enterTouristApp
                : context.l10n.enterDriverApp,
            prefixIcon: _role == 'tourist'
                ? Icons.explore
                : Icons.electric_rickshaw,
            isLoading: _isLoading,
            onPressed: _login,
          ),
          const SizedBox(height: 26),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                context.l10n.donTHaveAnAccount,
                style: GoogleFonts.poppins(color: AppColors.textSecondary),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => context.push('/register/role'),
                  child: Text(
                    context.l10n.signUp,
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.push('/admin/login'),
            child: Text(
              context.l10n.manageAppOpenTheAdminPortal(AppBrand.name),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ];
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, item) in items.indexed)
                            FadeSlideIn.staggered(index: i + 2, child: item),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          children: [
            const BrandLogoHero(size: 92),
            const SizedBox(height: 14),
            FadeSlideIn(
              delay: Motion.medium,
              child: Text(
                context.l10n.appName(AppBrand.name),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            FadeSlideIn(
              delay: Motion.medium + Motion.stagger,
              child: Text(
                context.l10n.yourLocalJourneyStartsHere,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _roleOption(String value, IconData icon, String label) {
    final selected = _role == value;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: context.l10n.modeValue(context.message((label).toString())),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _role = value),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x160D1B2A),
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    context.message(label),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
