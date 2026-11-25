import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/email_code_auth.dart';
import '../../../core/services/email_code_errors.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../widgets/email_code_widgets.dart';

/// Step 2 of a password reset: the 6-digit code from the email plus the new
/// password. The code is checked first, then the password is set and the user
/// signs in again with it.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.auth = const AuthServiceEmailCodes(),
    this.resendCooldown = emailCodeResendCooldown,
  });

  final String email;
  final EmailCodeAuth auth;
  final Duration resendCooldown;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  // Once the code is accepted it is used up; a failed password change then
  // retries inside the same recovery session without asking for a new code.
  bool _codeAccepted = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final code = normalizeEmailCode(_code.text);
    if (code == null) {
      setState(() {
        _info = null;
        _error = MessageCode.enterAllSixDigits;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _info = null;
    });
    try {
      if (!_codeAccepted) {
        try {
          await widget.auth.verifyRecoveryCode(widget.email, code);
        } catch (error) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _error = emailCodeMessage(emailCodeFailureFor(error));
          });
          return;
        }
        _codeAccepted = true;
      }
      await widget.auth.updateRecoveredPassword(_password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.passwordUpdatedSignInAgain)),
      );
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) return;
      // Losing the recovery session means the code must be asked for again.
      if (error is AuthException &&
          error.message ==
              MessageCode
                  .thisPasswordResetLinkIsInvalidOrExpiredRequestANewOne) {
        _codeAccepted = false;
      }
      setState(() {
        _saving = false;
        _error = ErrorMessages.forError(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.createANewPassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.secureYourAccount,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(context.l10n.resetCodeSentNeutral(widget.email)),
                const SizedBox(height: 4),
                Text(context.l10n.neverShareThisCode),
                const SizedBox(height: 28),
                EmailCodeField(
                  controller: _code,
                  autofocus: true,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _password,
                  label: context.l10n.newPassword,
                  obscureText: true,
                  enabled: !_saving,
                  validator: Validators.password,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirm,
                  label: context.l10n.confirmNewPassword,
                  obscureText: true,
                  enabled: !_saving,
                  textInputAction: TextInputAction.done,
                  validator: (value) =>
                      Validators.confirmPassword(_password.text)(value),
                ),
                InlineFormMessage(message: _error),
                InlineFormMessage(message: _info, isError: false),
                const SizedBox(height: 28),
                AppButton(
                  label: context.l10n.updatePassword,
                  isLoading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 8),
                ResendCodeButton(
                  cooldown: widget.resendCooldown,
                  onResend: () =>
                      widget.auth.requestPasswordResetCode(widget.email),
                  onSent: () => setState(() {
                    _error = null;
                    _info = MessageCode.newCodeSent;
                  }),
                  onError: (error) => setState(() {
                    _info = null;
                    _error = emailCodeMessage(emailCodeFailureFor(error));
                  }),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(context.l10n.backToLogin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
