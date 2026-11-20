import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

List<DeviceOrientation> orientationPolicy(double shortestSide) =>
    shortestSide >= 600
    ? DeviceOrientation.values
    : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown];

/// Shared by the real app and the screen matrix; never clamps text scaling.
class ResponsiveAppFrame extends StatefulWidget {
  static const maxContentWidth = 840.0;
  final Widget child;
  const ResponsiveAppFrame({super.key, required this.child});
  @override
  State<ResponsiveAppFrame> createState() => _ResponsiveAppFrameState();
}

class _ResponsiveAppFrameState extends State<ResponsiveAppFrame>
    with WidgetsBindingObserver {
  bool? _large;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_revealFocus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeListener(_revealFocus);
    super.dispose();
  }

  @override
  void didChangeMetrics() => _revealFocus();
  void _revealFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final focus = FocusManager.instance.primaryFocus?.context;
      if (focus == null || !focus.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          focus,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = MediaQuery.sizeOf(context), large = size.shortestSide >= 600;
      if (_large != large) {
        _large = large;
        unawaited(
          SystemChrome.setPreferredOrientations(
            orientationPolicy(size.shortestSide),
          ),
        );
      }
      final width = constraints.maxWidth >= 600
          ? constraints.maxWidth.clamp(0.0, ResponsiveAppFrame.maxContentWidth)
          : constraints.maxWidth;
      return GestureDetector(
        excludeFromSemantics: true,
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(size: Size(width, size.height)),
              child: TickerMode(
                enabled: !MediaQuery.disableAnimationsOf(context),
                child: widget.child,
              ),
            ),
          ),
        ),
      );
    },
  );
}
