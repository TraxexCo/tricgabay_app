import 'package:flutter/material.dart';

/// Blocks access without disposing the router, pending sign-in, or form state.
/// The hidden subtree cannot receive input, focus, semantics, or animations.
class RetainedGate extends StatefulWidget {
  final Widget child;
  final Widget? barrier;
  const RetainedGate({super.key, required this.child, this.barrier});

  @override
  State<RetainedGate> createState() => _RetainedGateState();
}

class _RetainedGateState extends State<RetainedGate> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    _revealed = _revealed || widget.barrier == null;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: widget.barrier != null,
          child: TickerMode(
            enabled: widget.barrier == null,
            child: ExcludeFocus(
              excluding: widget.barrier != null,
              child: _revealed ? widget.child : const SizedBox.shrink(),
            ),
          ),
        ),
        if (widget.barrier != null) Positioned.fill(child: widget.barrier!),
      ],
    );
  }
}
