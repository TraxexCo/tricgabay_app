import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/registration_privacy.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/auth_service.dart';

class RegisterTouristScreen extends ConsumerStatefulWidget {
  const RegisterTouristScreen({super.key});

  @override
  ConsumerState<RegisterTouristScreen> createState() =>
      _RegisterTouristScreenState();
}

class _RegisterTouristScreenState extends ConsumerState<RegisterTouristScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _agreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate() || !_agreed) return;
    if (!BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverSetupIsIncomplete)),
      );
      return;
    }
    final consent = await requestRegistrationConsent(context);
    if (consent == null || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.registerTourist(
        privacyVersion: consent.version,
        privacyLanguage: consent.shownLanguage!,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        phone: _phoneCtrl.text,
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.accountCreatedConfirmYourEmailThenSignIn),
        ),
      );
      context.go('/login');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.createTouristAccount,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _nameCtrl,
                label: context.l10n.fullName,
                hint: context.l10n.johnDoe,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.trim().length < 2
                    ? MessageCode.enterYourFullName
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _emailCtrl,
                label: context.l10n.email,
                hint: context.l10n.johnExampleCom,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || !v.contains('@')
                    ? MessageCode.enterAValidEmail
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _phoneCtrl,
                label: context.l10n.phoneNumber,
                hint: '+63 912 345 6789',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    v == null || v.replaceAll(RegExp(r'\D'), '').length < 10
                    ? MessageCode.enterAValidPhoneNumber
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordCtrl,
                label: context.l10n.password,
                hint: context.l10n.min8Characters,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) => v == null || v.length < 8
                    ? MessageCode.passwordMustBeAtLeast8Characters
                    : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmCtrl,
                label: context.l10n.confirmPassword,
                hint: context.l10n.retypePassword,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) => v != _passwordCtrl.text
                    ? MessageCode.passwordsDoNotMatch
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Semantics(
                    label: context.l10n.iAgreeToTheTermsAndConditions,
                    child: Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      activeColor: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.iAgreeToTheTermsAndConditions,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton(
                label: context.l10n.register,
                isLoading: _isLoading,
                onPressed: _agreed ? _register : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      context.l10n.alreadyHaveAnAccount,
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        context.l10n.login,
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
