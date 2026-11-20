import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../l10n/app_l10n.dart';

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

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  static const _thumbSize = 56.0;
  double _dragPosition = 0;
  bool _confirmed = false;
  bool _pending = false;
  bool _failed = false;

  bool get _interactive => widget.enabled && !_pending && !_confirmed;

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
      if (mounted) setState(() => _confirmed = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() {
          _pending = false;
          _dragPosition = 0;
        });
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            enabled: _interactive,
            label: _pending
                ? context.l10n.paymentProcessing
                : widget.accessibilityLabel ?? label,
            excludeSemantics: true,
            onTap: _interactive ? _confirm : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              decoration: BoxDecoration(
                color: widget.trackColor.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: widget.trackColor.withValues(alpha: .3),
                ),
              ),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(72, 20, 16, 20),
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: widget.trackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Positioned(
                    left: _dragPosition,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (!_interactive || end <= 0) return;
                          final next = (_dragPosition + details.delta.dx).clamp(
                            0.0,
                            end,
                          );
                          setState(() => _dragPosition = next);
                          if (next >= end) _confirm();
                        },
                        onHorizontalDragEnd: (_) {
                          if (_interactive) setState(() => _dragPosition = 0);
                        },
                        onHorizontalDragCancel: () {
                          if (_interactive) setState(() => _dragPosition = 0);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: _thumbSize,
                          height: _thumbSize,
                          decoration: BoxDecoration(
                            color: widget.trackColor,
                            shape: BoxShape.circle,
                          ),
                          child: _pending
                              ? Center(
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
                                  color: widget.thumbColor,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_failed)
            Semantics(
              liveRegion: true,
              child: Text(
                widget.errorText ?? context.l10n.gcashActionFailed,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    },
  );
}
