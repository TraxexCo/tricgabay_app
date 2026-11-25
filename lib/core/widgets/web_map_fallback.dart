import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Map-like surface used by the browser build while Mapbox runs on mobile.
class WebMapFallback extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const WebMapFallback({
    super.key,
    this.title = MessageCode.bustosTourMap,
    this.subtitle = MessageCode.interactiveMapsAreAvailableInTheMobileApp,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8F1EA),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _MapPatternPainter()),
          Positioned(
            left: compact ? 12 : 24,
            right: compact ? 12 : 24,
            bottom: compact ? 10 : 92,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16,
                vertical: compact ? 7 : 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(compact ? 12 : 18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220D1B2A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map_rounded,
                    color: AppColors.primary,
                    size: compact ? 18 : 24,
                  ),
                  SizedBox(width: compact ? 7 : 11),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.message(title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: compact ? 10 : 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 2),
                          Text(
                            context.message(subtitle),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  const _MapPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final minorRoad = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 3;
    final majorRoad = Paint()
      ..color = const Color(0xFFF7D98A)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final water = Paint()
      ..color = const Color(0xFFB9DFF2)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    for (double y = 24; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 28), minorRoad);
    }
    for (double x = 20; x < size.width; x += 72) {
      canvas.drawLine(Offset(x, 0), Offset(x + 36, size.height), minorRoad);
    }

    final mainPath = Path()
      ..moveTo(-20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.34,
        size.width * 0.62,
        size.height * 0.76,
        size.width + 20,
        size.height * 0.28,
      );
    canvas.drawPath(mainPath, majorRoad);

    final riverPath = Path()
      ..moveTo(size.width * 0.08, -10)
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.2,
        size.width * 0.30,
        size.height * 0.72,
        size.width * 0.72,
        size.height + 10,
      );
    canvas.drawPath(riverPath, water);

    final pinPaint = Paint()..color = AppColors.primary;
    for (final point in <Offset>[
      Offset(size.width * 0.28, size.height * 0.32),
      Offset(size.width * 0.61, size.height * 0.46),
      Offset(size.width * 0.76, size.height * 0.22),
      Offset(size.width * 0.44, size.height * 0.68),
    ]) {
      canvas.drawCircle(point, 8, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, pinPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
