import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/tourist_spot_model.dart';
import '../tours_for_spot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';

class TouristSpotInfoScreen extends StatelessWidget {
  final String spotId;

  const TouristSpotInfoScreen({super.key, required this.spotId});

  @override
  Widget build(BuildContext context) {
    final spot = AppSession.allSpots.value
        .where((s) => s.id == spotId && s.isActive)
        .firstOrNull;
    if (spot == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.attraction)),
        body: Center(
          child: Text(context.l10n.thisAttractionIsNoLongerAvailable),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeAppImage(
                path: spot.imageUrls.isNotEmpty ? spot.imageUrls.first : '',
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              IconButton(
                tooltip: context.l10n.share,
                icon: const Icon(Icons.share, color: AppColors.primary),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text: context.l10n.checkOutInBustosBulacanValue(
                        context.message((spot.name).toString()),
                      ),
                      subject: spot.name,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: AppSession.favorites,
                builder: (context, favorites, _) => IconButton(
                  tooltip: context.l10n.savePlace,
                  icon: Icon(
                    favorites.contains(spotId)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: AppColors.surface,
                  ),
                  onPressed: () => AppSession.toggleFavorite(spotId),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          context.message(spot.name),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          context.message(spot.categoryLabel),
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (spot.isTemporarilyClosed) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.temporarilyClosed,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (spot.closureReason != null)
                            Text(context.message(spot.closureReason!)),
                          if (spot.closedUntil != null)
                            Text(
                              context.l10n.expectedReopeningValue(
                                context.message(
                                  (AppFormatters.dateTime(
                                    spot.closedUntil!.toLocal(),
                                  )).toString(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // The badge already shows the hours with a clock icon.
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: _buildOpenStatusBadge(
                            context,
                            spot.openingHours,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.payments,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              spot.entranceFee.toLowerCase() == 'free' ||
                                  spot.entranceFee.toLowerCase().startsWith(
                                    'free',
                                  )
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color:
                                spot.entranceFee.toLowerCase() == 'free' ||
                                    spot.entranceFee.toLowerCase().startsWith(
                                      'free',
                                    )
                                ? Colors.green
                                : Colors.amber.shade700,
                          ),
                        ),
                        child: Text(
                          context.message(spot.entranceFee),
                          style: TextStyle(
                            color:
                                spot.entranceFee.toLowerCase() == 'free' ||
                                    spot.entranceFee.toLowerCase().startsWith(
                                      'free',
                                    )
                                ? Colors.green.shade700
                                : Colors.amber.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.about,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.message(spot.description),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.localHistory,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.message(spot.history),
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.tipsReminders,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...spot.tips.map((tip) => _buildTip(context, tip)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.photoGallery,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Flexible(
                        child: TextButton(
                          onPressed: () =>
                              context.push('/tourist/spot/$spotId/gallery'),
                          child: Text(
                            context.l10n.seeAll,
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: spot.imageUrls.isNotEmpty
                          ? spot.imageUrls.length
                          : 1,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SafeAppImage(
                              path: spot.imageUrls.isNotEmpty
                                  ? spot.imageUrls[index]
                                  : '',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Places are visited only as part of a tour package.
                  if (AppSession.packagesWithSpot(spot.id).isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      context.l10n.includedInTheseTours,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final package in AppSession.packagesWithSpot(
                          spot.id,
                        ))
                          ActionChip(
                            avatar: const Icon(Icons.tour_outlined, size: 18),
                            label: Text(
                              '${package.name} · ₱${AppFormatters.integer(AppSession.packageFare(package))}',
                            ),
                            onPressed: () => context.push(
                              '/tourist/tour-packages/${package.id}',
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Where this page's details come from; there are no
                  // tourist reviews of spots yet.
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_outlined,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          context.l10n.informationProvidedByAppAdministrators(
                            AppBrand.name,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 110), // spacing for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              IconButton.outlined(
                tooltip: context.l10n.viewMap,
                style: _squareButton,
                icon: const Icon(Icons.map_outlined),
                onPressed: () {
                  AppSession.focusedSpotId.value = spot.id;
                  context.go('/tourist/home');
                },
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: context.l10n.directions,
                style: _squareButton,
                icon: const Icon(Icons.directions_rounded),
                onPressed: () => _openDirections(spot),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.tour_outlined),
                  label: Text(context.l10n.seeTours),
                  onPressed: () => openToursForSpot(context, spot.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final _squareButton = IconButton.styleFrom(
    fixedSize: const Size(52, 52),
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.border, width: 1.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  Future<void> _openDirections(TouristSpotModel spot) async {
    final uri = Uri.parse(
      'geo:${spot.latitude},${spot.longitude}?q=${spot.latitude},${spot.longitude}(${Uri.encodeComponent(spot.name)})',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: open Google Maps in the browser.
      await launchUrl(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}',
        ),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Widget _buildTip(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColors.secondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.message(text),
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenStatusBadge(BuildContext context, String openingHours) {
    final isClosed =
        openingHours.toLowerCase().contains('temporarily closed') ||
        openingHours.toLowerCase().contains('closed');
    final color = isClosed ? AppColors.danger : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isClosed ? Icons.warning_rounded : Icons.access_time_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.message(openingHours),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
