import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
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
    final selectedCount = PrototypeSession.itinerary.value.length;
    final estimatedFare = PrototypeSession.estimatedFare;

    bool hasEntranceFees = PrototypeSession.itinerary.value.any(
      (spot) =>
          spot.entranceFee.toLowerCase() != 'free' &&
          !spot.entranceFee.toLowerCase().startsWith('free'),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        title: Text(
          'Build Your Day',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (PrototypeSession.itinerary.value.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all_rounded),
              tooltip: 'Clear All',
              onPressed: () {
                PrototypeSession.clearTripPlan();
                setState(() {});
              },
            ),
        ],
      ),
      body: Column(
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
                    child: const Icon(Icons.route_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make it your own',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose the places you want to visit in one trip.',
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              itemCount: PrototypeSession.allSpots.value.length,
              itemBuilder: (context, index) {
                final spot = PrototypeSession.allSpots.value[index];
                final selected = PrototypeSession.itinerary.value.any(
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
                              () => PrototypeSession.toggleItinerary(spot),
                            ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
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
                                          spot.name,
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
                                    '${spot.categoryLabel} • ${spot.distanceFromTown.toStringAsFixed(1)} km away',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spot.isTemporarilyClosed
                                        ? 'Temporarily closed'
                                        : spot.entranceFee,
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
                              duration: const Duration(milliseconds: 180),
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
                              selectedCount == 0
                                  ? 'No destinations selected'
                                  : '$selectedCount ${selectedCount == 1 ? 'destination' : 'destinations'}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fixed fare',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                            if (hasEntranceFees) ...[
                              const SizedBox(height: 2),
                              Text(
                                '+ entrance fees may apply',
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
                        selectedCount == 0
                            ? '—'
                            : '₱${estimatedFare.toStringAsFixed(0)}',
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
                    label: 'Review Fare',
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
    );
  }
}
