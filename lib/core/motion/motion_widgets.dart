import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'motion.dart';

/// Fades and slides its child into place once, after an optional [delay].
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.long,
    this.offset = const Offset(0, 0.08),
  });

  /// Position of the stagger. Use [FadeSlideIn.staggered] for lists.
  /// Only the first screenful staggers; items further down (reached by
  /// scrolling) appear immediately so scrolling never feels laggy.
  factory FadeSlideIn.staggered({
    Key? key,
    required int index,
    required Widget child,
    int maxStaggered = 8,
  }) => FadeSlideIn(
    key: key,
    delay: index > maxStaggered ? Duration.zero : Motion.stagger * index,
    duration: index > maxStaggered ? Duration.zero : Motion.long,
    child: child,
  );

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Start offset as a fraction of the child's size.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  // The delay is part of the animation (an Interval), not a Timer, so nothing
  // is left pending when the widget goes away.
  late final _total = widget.delay + widget.duration;
  late final _controller = AnimationController(vsync: this, duration: _total);
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      _total.inMicroseconds == 0
          ? 0
          : widget.delay.inMicroseconds / _total.inMicroseconds,
      1,
      curve: Motion.enter,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _curve,
    // Content stays available to screen readers while it fades in.
    alwaysIncludeSemantics: true,
    child: SlideTransition(
      position: Tween(begin: widget.offset, end: Offset.zero).animate(_curve),
      child: widget.child,
    ),
  );
}

/// Shrinks its child slightly while pressed, for tappable cards and tiles.
/// It only gives visual feedback; the child keeps its own tap handling.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = 0.97});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down && !Motion.reduced(context) ? widget.scale : 1,
      duration: Motion.short,
      curve: Motion.enter,
      child: widget.child,
    ),
  );
}

/// A circle that pops in and draws a check mark, for confirmations.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({
    super.key,
    this.size = 72,
    this.color = AppColors.success,
    this.semanticLabel,
  });

  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final circle = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .55, curve: Motion.pop),
    );
    final stroke = CurvedAnimation(
      parent: _controller,
      curve: const Interval(.4, 1, curve: Motion.enter),
    );
    return Semantics(
      label: widget.semanticLabel,
      image: widget.semanticLabel != null,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Transform.scale(
            scale: circle.value,
            child: CustomPaint(
              painter: _CheckPainter(widget.color, stroke.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.color, this.progress);

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, r, Paint()..color = color);
    final path = Path()
      ..moveTo(center.dx - r * .42, center.dy + r * .02)
      ..lineTo(center.dx - r * .1, center.dy + r * .34)
      ..lineTo(center.dx + r * .45, center.dy - r * .3);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.progress != progress || old.color != color;
}

/// A placeholder block with a moving sheen, shown while content loads.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 10,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 3 - 1;
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: const [
                AppColors.surfaceVariant,
                Color(0xFFF7F9FD),
                AppColors.surfaceVariant,
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// A card-shaped skeleton for lists that are still loading.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SkeletonBox(height: 48, width: 48, radius: 14),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 8),
                SkeletonBox(height: 12, width: 140),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// Counts up to [value] when it first appears or changes.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  final num value;
  final String Function(num value) format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: Motion.of(context, const Duration(milliseconds: 900)),
    curve: Motion.enter,
    builder: (context, current, _) => Text(
      format(value is int ? current.round() : current),
      style: style,
      semanticsLabel: format(value),
    ),
  );
}
