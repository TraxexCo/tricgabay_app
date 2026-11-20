part of 'tourist_home_screen.dart';

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.onTap});

  final TouristSpotModel spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148 * MediaQuery.textScalerOf(context).scale(1),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0D1B2A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SafeAppImage(
                path: spot.imageUrls.isNotEmpty ? spot.imageUrls.first : '',
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.message(spot.name),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor(
                            spot.category,
                          ).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.message(spot.categoryLabel),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor(spot.category),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        context.l10n.kmValue(
                          context.message((spot.distanceFromTown).toString()),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spot info bottom sheet (shown on pin tap or card tap)
// ─────────────────────────────────────────────────────────────────────────────

class _SpotInfoSheet extends StatelessWidget {
  const _SpotInfoSheet({required this.spot});
  final TouristSpotModel spot;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(spot.category);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330D1B2A),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCED6E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                // Hero image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        SafeAppImage(
                          path: spot.imageUrls.isNotEmpty
                              ? spot.imageUrls.first
                              : '',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Category badge overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.message(spot.categoryLabel),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            tooltip: context.l10n.closeAttractionDetails,
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Info body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message(spot.name),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Meta row
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              context.message(spot.openingHours),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.payments_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.message(spot.entranceFee),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.message(spot.description),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/tourist/spot/${spot.id}');
                              },
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                context.l10n.viewDetails,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: spot.isTemporarilyClosed
                                  ? null
                                  : () {
                                      AppSession.startCustomItinerary();
                                      AppSession.toggleItinerary(
                                        spot,
                                      ); // ADD THE SPOT FIRST
                                      Navigator.pop(context);
                                      context.push('/tourist/itinerary');
                                    },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                context.message(
                                  spot.isTemporarilyClosed
                                      ? MessageCode.closed
                                      : MessageCode.addToTripLabel,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin bitmap builder — draws a coloured teardrop pin with dart:ui
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildPinBitmap(Color color) async {
  const double w = 48;
  const double h = 64;
  const double cx = w / 2;
  const double r = 19.0; // circle radius

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

  // Drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0);
  canvas.drawOval(Rect.fromLTWH(cx - 14, h - 10, 28, 10), shadowPaint);

  // Teardrop path: circle top + triangle pointer at bottom
  final path = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r));

  final pointerPath = Path()
    ..moveTo(cx - 7, r + 12)
    ..quadraticBezierTo(cx, h - 2, cx + 7, r + 12)
    ..close();

  // Fill
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, fill);
  canvas.drawPath(pointerPath, fill);

  // White border
  final border = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawPath(path, border);
  canvas.drawPath(pointerPath, border);

  // White inner dot
  canvas.drawCircle(
    Offset(cx, r),
    8,
    Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.fill,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// ─────────────────────────────────────────────────────────────────────────────
// Category helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _categoryColor(SpotCategory cat) => switch (cat) {
  SpotCategory.church => const Color(0xFFCE1126), // red
  SpotCategory.nature => const Color(0xFF27AE60), // green
  SpotCategory.market => const Color(0xFFD4A017), // gold
  SpotCategory.heritage => const Color(0xFF0038A8), // brand blue
  SpotCategory.park => const Color(0xFF8E44AD), // purple
  SpotCategory.other => const Color(0xFF6B7280), // gray
};
