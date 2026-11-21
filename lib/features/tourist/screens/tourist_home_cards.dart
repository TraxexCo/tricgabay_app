part of 'tourist_home_screen.dart';

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.onTap});

  final TouristSpotModel spot;
  final VoidCallback onTap;

  static const _imageHeight = 100.0;

  /// Image, name line and distance line, sized for the current text scale.
  static double heightFor(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return _imageHeight + 24 + 40 * scale;
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(spot.category);
    return Container(
      width: 156 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140D1B2A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SafeAppImage(
                    path: spot.imageUrls.isNotEmpty ? spot.imageUrls.first : '',
                    height: _imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .94),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            context.message(spot.categoryLabel),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(spot.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            context.l10n.kmFromTown(
                              AppFormatters.distanceKm(spot.distanceFromTown),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
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
// Why the map asks for location, shown once before the system prompt
// ─────────────────────────────────────────────────────────────────────────────

class _LocationExplainerSheet extends StatelessWidget {
  const _LocationExplainerSheet();

  @override
  Widget build(BuildContext context) {
    Widget reason(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.near_me_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.locationExplainerTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 18),
            reason(Icons.map_outlined, context.l10n.locationReasonMap),
            reason(Icons.hail_rounded, context.l10n.locationReasonPickup),
            reason(
              Icons.lock_outline_rounded,
              context.l10n.locationReasonPrivacy,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.allowLocation),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.notNow),
            ),
          ],
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
