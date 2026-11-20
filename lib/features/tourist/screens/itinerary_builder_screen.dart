import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/app_button.dart';
import '../../../models/tourist_spot_model.dart';

class ItineraryBuilderScreen extends StatefulWidget {
  const ItineraryBuilderScreen({super.key});
  @override
  State<ItineraryBuilderScreen> createState() => _ItineraryBuilderScreenState();
}

class _ItineraryBuilderScreenState extends State<ItineraryBuilderScreen> {
  final categoryColors = {
    SpotCategory.church: const Color(0xFFCE1126),
    SpotCategory.nature: const Color(0xFF27AE60),
    SpotCategory.market: const Color(0xFFD4A017),
    SpotCategory.heritage: const Color(0xFF0038A8),
    SpotCategory.park: const Color(0xFF8E44AD),
    SpotCategory.other: const Color(0xFF6B7280),
  };

  IconData _spotIcon(SpotCategory cat) => switch (cat) {
    SpotCategory.church => Icons.church_rounded,
    SpotCategory.nature => Icons.park_rounded,
    SpotCategory.market => Icons.storefront_rounded,
    SpotCategory.heritage => Icons.account_balance_rounded,
    SpotCategory.park => Icons.nature_rounded,
    SpotCategory.other => Icons.place_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final selectedCount = AppSession.itinerary.value.length;
    final estimatedFare = AppSession.estimatedFare;

    bool hasEntranceFees = AppSession.itinerary.value.any(
      (spot) =>
          spot.entranceFee.toLowerCase() != 'free' &&
          !spot.entranceFee.toLowerCase().startsWith('free'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        title: Text(
          context.l10n.buildYourDay,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (AppSession.itinerary.value.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: context.l10n.clearAll,
              onPressed: () {
                AppSession.clearTripPlan();
                setState(() {});
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .16),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.makeItYourOwn,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.chooseThePlacesYouWantToVisitInOneTrip,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: .82),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              itemCount: AppSession.allSpots.value.length,
              itemBuilder: (context, index) {
                final spot = AppSession.allSpots.value[index];
                final selected = AppSession.itinerary.value.any(
                  (item) => item.id == spot.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: spot.isTemporarilyClosed
                          ? null
                          : () => setState(
                              () => AppSession.toggleItinerary(spot),
                            ),
                      child: AnimatedContainer(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withValues(alpha: .035)
                              : Colors.white,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : const Color(0xFFE4EBF0),
                            width: selected ? 1.8 : 1,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color:
                                    (selected
                                            ? AppColors.primary
                                            : AppColors.secondary)
                                        .withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _spotIcon(spot.category),
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color:
                                              categoryColors[spot.category] ??
                                              Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          context.message(spot.name),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    context.l10n.kmAwayValue(
                                      context.message(
                                        (spot.categoryLabel).toString(),
                                      ),
                                      context.message(
                                        (spot.distanceFromTown.toStringAsFixed(
                                          1,
                                        )).toString(),
                                      ),
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.message(
                                      spot.isTemporarilyClosed
                                          ? MessageCode.temporarilyClosed
                                          : spot.entranceFee,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: spot.isTemporarilyClosed
                                          ? AppColors.danger
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: selected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 17,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x150D1B2A),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.message(
                                  selectedCount == 0
                                      ? MessageCode.noDestinationsSelected
                                      : MessageCode.selectedDestinationCount(
                                          selectedCount,
                                        ),
                                ),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.fixedFare,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              if (hasEntranceFees) ...[
                                const SizedBox(height: 2),
                                Text(
                                  context.l10n.entranceFeesMayApply,
                                  style: GoogleFonts.poppins(
                                    color: Colors.orange.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          context.message(
                            selectedCount == 0
                                ? '—'
                                : '₱${AppFormatters.integer(estimatedFare)}',
                          ),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: context.l10n.reviewFare,
                      prefixIcon: Icons.arrow_forward_rounded,
                      onPressed: selectedCount == 0
                          ? null
                          : () => context.push('/tourist/fare-summary'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
