import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../l10n/app_l10n.dart';
import '../motion/motion.dart';

/// Slide-to-confirm for actions that must not happen by accident, such as a
/// driver confirming a payment.
///
/// Motion: a sheen sweeps the label as a hint, the track fills behind the
/// thumb while dragging, an early release springs back, success fills the
/// track green with a check and a haptic tap, and failure shakes the track.
class SwipeToConfirm extends StatefulWidget {
  final String text;
  final VoidCallback? onConfirm;
  final Future<void> Function()? onConfirmAsync;
  final String? accessibilityLabel;
  final String? errorText;
  final bool enabled;
  final Color trackColor;
  final Color thumbColor;
  const SwipeToConfirm({
    super.key,
    required this.text,
    this.onConfirm,
    this.onConfirmAsync,
    this.accessibilityLabel,
    this.errorText,
    this.enabled = true,
    this.trackColor = AppColors.primary,
    this.thumbColor = Colors.white,
  }) : assert((onConfirm == null) != (onConfirmAsync == null));
  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with TickerProviderStateMixin {
  static const _thumbSize = 56.0;
  double _dragPosition = 0;
  bool _confirmed = false;
  bool _pending = false;
  bool _failed = false;

  // Springs the thumb back to the start after an early release or failure.
  late final AnimationController _spring =
      AnimationController(vsync: this, duration: Motion.medium)
        ..addListener(() {
          setState(() => _dragPosition = _springFrom * (1 - _spring.value));
        });
  double _springFrom = 0;

  // Sheen across the label; a short, finite hint rather than a loop.
  late final _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool get _interactive => widget.enabled && !_pending && !_confirmed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && _sheen.value == 0 && !_sheen.isAnimating) {
      _sheen.repeat(count: 2);
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    _sheen.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _springBack() {
    if (_dragPosition == 0) return;
    _springFrom = _dragPosition;
    if (Motion.reduced(context)) {
      setState(() => _dragPosition = 0);
    } else {
      _spring.forward(from: 0);
    }
  }

  Future<void> _confirm() async {
    if (!_interactive) return;
    setState(() {
      _pending = true;
      _failed = false;
    });
    try {
      final confirmAsync = widget.onConfirmAsync;
      if (confirmAsync == null) {
        widget.onConfirm!();
      } else {
        await confirmAsync();
      }
      if (mounted) {
        unawaited(HapticFeedback.mediumImpact());
        setState(() => _confirmed = true);
      }
    } catch (_) {
      if (mounted) {
        unawaited(HapticFeedback.heavyImpact());
        setState(() => _failed = true);
        if (!Motion.reduced(context)) _shake.forward(from: 0);
      }
    } finally {
      if (mounted) {
        setState(() => _pending = false);
        if (!_confirmed) _springBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final end = (constraints.maxWidth - _thumbSize - 4).clamp(
        0.0,
        double.infinity,
      );
      final label = context.message(
        _confirmed ? MessageCode.done : widget.text,
      );
      final color = _confirmed ? AppColors.success : widget.trackColor;
      final progress = end <= 0 ? 0.0 : (_dragPosition / end).clamp(0.0, 1.0);
      final thumbLeft = _confirmed ? end : _dragPosition;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 8 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Semantics(
              button: true,
              enabled: _interactive,
              label: _pending
                  ? context.l10n.paymentProcessing
                  : widget.accessibilityLabel ?? label,
              excludeSemantics: true,
              onTap: _interactive ? _confirm : null,
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.medium),
                constraints: const BoxConstraints(minHeight: 64),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: _confirmed ? .14 : .08),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: color.withValues(alpha: .3)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Fill that follows the thumb, and floods on success.
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: Motion.of(
                            context,
                            _confirmed ? Motion.long : Duration.zero,
                          ),
                          curve: Motion.enter,
                          width: _confirmed
                              ? constraints.maxWidth
                              : thumbLeft + _thumbSize + 4,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: _confirmed ? .22 : .10 + .14 * progress,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(72, 20, 16, 20),
                      child: Opacity(
                        opacity: _confirmed ? 1 : 1 - progress * .7,
                        child: _SheenText(
                          animation: _sheen,
                          enabled: _interactive,
                          text: label,
                          style: GoogleFonts.poppins(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    AnimatedPositioned(
                      duration: Motion.of(
                        context,
                        _confirmed ? Motion.medium : Duration.zero,
                      ),
                      curve: Motion.enter,
                      left: thumbLeft,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onHorizontalDragStart: (_) => _spring.stop(),
                          onHorizontalDragUpdate: (details) {
                            if (!_interactive || end <= 0) return;
                            final next = (_dragPosition + details.delta.dx)
                                .clamp(0.0, end);
                            setState(() => _dragPosition = next);
                            if (next >= end) _confirm();
                          },
                          onHorizontalDragEnd: (_) {
                            if (_interactive) _springBack();
                          },
                          onHorizontalDragCancel: () {
                            if (_interactive) _springBack();
                          },
                          child: AnimatedContainer(
                            duration: Motion.of(context, Motion.medium),
                            margin: const EdgeInsets.all(2),
                            width: _thumbSize,
                            height: _thumbSize,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: .35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: Motion.of(context, Motion.medium),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: CurvedAnimation(
                                      parent: animation,
                                      curve: Motion.pop,
                                    ),
                                    child: child,
                                  ),
                              child: _pending
                                  ? Center(
                                      key: const ValueKey('pending'),
                                      child: SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: widget.thumbColor,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      _confirmed
                                          ? Icons.check
                                          : Icons.arrow_forward_ios,
                                      key: ValueKey(_confirmed),
                                      color: widget.thumbColor,
                                      size: _confirmed ? 26 : 20,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            child: _failed
                ? Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        widget.errorText ?? context.l10n.gcashActionFailed,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      );
    },
  );
}

/// Label with a light sheen sweeping across it.
class _SheenText extends StatelessWidget {
  const _SheenText({
    required this.animation,
    required this.enabled,
    required this.text,
    required this.style,
  });

  final Animation<double> animation;
  final bool enabled;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      if (!enabled || !animation.isAnimating) return child!;
      final t = animation.value * 3 - 1;
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(t - .6, 0),
          end: Alignment(t + .6, 0),
          colors: [
            style.color!,
            Colors.white.withValues(alpha: .9),
            style.color!,
          ],
        ).createShader(bounds),
        child: child,
      );
    },
    child: Text(text, style: style),
  );
}
