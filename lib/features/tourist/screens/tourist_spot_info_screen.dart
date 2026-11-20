import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/app_button.dart';
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
                      const Icon(
                        Icons.access_time,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.message(spot.openingHours),
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            _buildOpenStatusBadge(context, spot.openingHours),
                          ],
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
                    children: [
                      Flexible(
                        child: Text(
                          context.l10n.ratingsReviews,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            context.l10n.informationProvidedByAppAdministrators(
                              AppBrand.name,
                            ),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          context.message('4.8'),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          context.l10n.reviewCountSummary,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  const SizedBox(height: 100), // spacing for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.l10n.viewMap,
                  type: AppButtonType.outline,
                  onPressed: () {
                    AppSession.focusedSpotId.value = spot.id;
                    context.go('/tourist/home');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.directions_rounded),
                  label: Text(context.l10n.directions),
                  onPressed: () async {
                    final uri = Uri.parse(
                      'geo:${spot.latitude},${spot.longitude}?q=${spot.latitude},${spot.longitude}(${Uri.encodeComponent(spot.name)})',
                    );
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      // Fallback: open Google Maps in browser
                      final webUri = Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}',
                      );
                      await launchUrl(
                        webUri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppButton(
                  label: spot.isTemporarilyClosed
                      ? MessageCode.closed
                      : MessageCode.itinerary,
                  onPressed: spot.isTemporarilyClosed
                      ? null
                      : () {
                          final alreadyAdded = AppSession.itinerary.value.any(
                            (item) => item.id == spot.id,
                          );
                          AppSession.toggleItinerary(spot);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.message(
                                  alreadyAdded
                                      ? MessageCode.removedFromYourItinerary
                                      : MessageCode.addedToYourItinerary,
                                ),
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
