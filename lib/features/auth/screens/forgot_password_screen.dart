import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/config/backend_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/email_code_auth.dart';
import '../../../core/services/email_code_errors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../widgets/email_code_widgets.dart';

/// Step 1 of a password reset: ask for a 6-digit code by email.
///
/// The next screen opens the same way whether or not the email has an
/// account, so the app never reveals which emails are registered.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.auth = const AuthServiceEmailCodes(),
    this.skipConfigurationCheck = false,
  });

  final EmailCodeAuth auth;

  /// Lets tests run without a configured backend.
  final bool skipConfigurationCheck;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    if (!widget.skipConfigurationCheck && !BackendConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.serverSetupIsIncomplete)),
      );
      return;
    }
    final email = _emailController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.requestPasswordResetCode(email);
    } catch (error) {
      final failure = emailCodeFailureFor(error);
      // Only problems that say nothing about the account are shown. Any other
      // refusal would reveal that the email is registered, so it looks the
      // same as success.
      if (failure == EmailCodeFailure.rateLimited ||
          failure == EmailCodeFailure.network) {
        if (mounted) {
          setState(() {
            _loading = false;
            _error = emailCodeMessage(failure);
          });
        }
        return;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    await context.push(AppRoutes.resetPassword, extra: email);
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.forgotPassword,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.enterYourEmailAndWeWillSendYouA6DigitCode,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _emailController,
                  label: context.l10n.emailAddress,
                  hint: context.l10n.exampleEmailCom,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendCode(),
                  validator: (v) => v == null || !v.contains('@')
                      ? MessageCode.enterAValidEmail
                      : null,
                ),
                InlineFormMessage(message: _error),
                const SizedBox(height: 32),
                AppButton(
                  label: context.l10n.sendResetCode,
                  isLoading: _loading,
                  onPressed: _sendCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
