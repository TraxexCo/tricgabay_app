import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/email_code_auth.dart';
import '../../../core/services/email_code_errors.dart';
import '../../../core/widgets/app_button.dart';
import '../widgets/email_code_widgets.dart';

/// What the sign-up code screen needs to know.
class VerifyEmailArgs {
  const VerifyEmailArgs(this.email, {this.codeJustSent = true});

  final String email;

  /// False when the user arrives without a fresh email (for example from the
  /// login screen), so "Resend code" is available straight away.
  final bool codeJustSent;
}

/// "Enter the 6-digit code we emailed you": confirms a new account.
///
/// Pops `true` once the code is accepted (the user is then signed in) and
/// `false` when the user goes back to sign in.
class VerifyEmailCodeScreen extends StatefulWidget {
  const VerifyEmailCodeScreen({
    super.key,
    required this.args,
    this.auth = const AuthServiceEmailCodes(),
    this.resendCooldown = emailCodeResendCooldown,
  });

  final VerifyEmailArgs args;
  final EmailCodeAuth auth;
  final Duration resendCooldown;

  @override
  State<VerifyEmailCodeScreen> createState() => _VerifyEmailCodeScreenState();
}

class _VerifyEmailCodeScreenState extends State<VerifyEmailCodeScreen> {
  final _code = TextEditingController();
  String? _error;
  String? _info;
  bool _verifying = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = normalizeEmailCode(_code.text);
    if (code == null) {
      setState(() {
        _info = null;
        _error = MessageCode.enterAllSixDigits;
      });
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    try {
      await widget.auth.verifySignUpCode(widget.args.email, code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = emailCodeMessage(emailCodeFailureFor(error));
      });
    }
  }

  void _back() => Navigator.of(context).pop(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary, onPressed: _back),
        title: Text(context.l10n.verifyYourEmail),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.enterSixDigitCodeEmailed,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.codeSentToValue(widget.args.email),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.neverShareThisCode,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              EmailCodeField(
                controller: _code,
                autofocus: true,
                validate: false,
                enabled: !_verifying,
                onSubmitted: (_) => _verify(),
              ),
              InlineFormMessage(message: _error),
              InlineFormMessage(message: _info, isError: false),
              const SizedBox(height: 24),
              AppButton(
                label: context.l10n.verifyCode,
                isLoading: _verifying,
                onPressed: _verify,
              ),
              const SizedBox(height: 8),
              ResendCodeButton(
                cooldown: widget.resendCooldown,
                startCoolingDown: widget.args.codeJustSent,
                onResend: () => widget.auth.resendSignUpCode(widget.args.email),
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
                onPressed: _back,
                child: Text(context.l10n.backToLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
