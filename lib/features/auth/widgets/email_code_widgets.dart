import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/email_code_errors.dart';
import '../../../core/widgets/app_text_field.dart';

/// How long the user waits before asking for another emailed code.
const emailCodeResendCooldown = Duration(seconds: 60);

/// The 6-digit code box: digits only, six at most, offered to the keyboard's
/// one-time-code autofill, with its own label for screen readers.
class EmailCodeField extends StatelessWidget {
  const EmailCodeField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.autofocus = false,
    this.enabled = true,
    this.validate = true,
  });

  final TextEditingController controller;
  final void Function(String)? onSubmitted;
  final TextInputAction textInputAction;
  final bool autofocus;
  final bool enabled;

  /// Whether the box checks itself inside a form. Off where the screen shows
  /// its own message instead.
  final bool validate;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: context.l10n.sixDigitCode,
      keyboardType: TextInputType.number,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.oneTimeCode],
      textInputAction: textInputAction,
      autofocus: autofocus,
      enabled: enabled,
      onSubmitted: onSubmitted,
      validator: validate
          ? (value) => normalizeEmailCode(value) == null
                ? MessageCode.enterAllSixDigits
                : null
          : null,
    );
  }
}

/// A message under a field that screen readers announce when it changes.
class InlineFormMessage extends StatelessWidget {
  const InlineFormMessage({
    super.key,
    required this.message,
    this.isError = true,
  });

  /// A message code or plain text; null shows nothing.
  final String? message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final text = message;
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Text(
          context.message(text),
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isError ? AppColors.danger : AppColors.success,
          ),
        ),
      ),
    );
  }
}

/// "Resend code", disabled with a countdown after each send so the user cannot
/// trip the email rate limit. Starts counting down at once when
/// [startCoolingDown] is true (a code was just sent).
class ResendCodeButton extends StatefulWidget {
  const ResendCodeButton({
    super.key,
    required this.onResend,
    this.onSent,
    this.onError,
    this.cooldown = emailCodeResendCooldown,
    this.startCoolingDown = true,
  });

  final Future<void> Function() onResend;
  final VoidCallback? onSent;
  final void Function(Object error)? onError;
  final Duration cooldown;
  final bool startCoolingDown;

  @override
  State<ResendCodeButton> createState() => _ResendCodeButtonState();
}

class _ResendCodeButtonState extends State<ResendCodeButton> {
  Timer? _timer;
  int _secondsLeft = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.startCoolingDown) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = widget.cooldown.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          _secondsLeft = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resend() async {
    if (_sending || _secondsLeft > 0) return;
    setState(() => _sending = true);
    try {
      await widget.onResend();
      if (!mounted) return;
      _startCooldown();
      widget.onSent?.call();
    } catch (error) {
      if (!mounted) return;
      // After a rate-limit refusal, wait out the cooldown before trying again.
      if (emailCodeFailureFor(error) == EmailCodeFailure.rateLimited) {
        _startCooldown();
      }
      widget.onError?.call(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final waiting = _secondsLeft > 0;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: TextButton(
        onPressed: waiting || _sending ? null : _resend,
        child: Text(
          waiting
              ? context.l10n.resendCodeInValue('$_secondsLeft')
              : context.l10n.resendCode,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
