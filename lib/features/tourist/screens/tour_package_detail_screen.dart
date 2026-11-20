import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';

class TourPackageDetailScreen extends StatelessWidget {
  final String packageId;
  const TourPackageDetailScreen({super.key, required this.packageId});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      AppSession.farePolicy,
      AppSession.tourPackages,
      AppSession.allSpots,
    ]),
    builder: (context, _) {
      final pkg = AppSession.tourPackages.value
          .where((p) => p.id == packageId)
          .firstOrNull;
      if (pkg == null ||
          !AppSession.farePolicy.value.packageFares.containsKey(pkg.id)) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.tourPackage)),
          body: Center(child: Text(context.l10n.packageNotFound)),
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
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeAppImage(path: pkg.imageUrl, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: .35),
                            Colors.transparent,
                            Colors.black.withValues(alpha: .15),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(pkg.name),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (pkg.duration.isNotEmpty)
                          const Icon(
                            Icons.timer,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        if (pkg.duration.isNotEmpty) const SizedBox(width: 4),
                        if (pkg.duration.isNotEmpty)
                          Flexible(
                            child: Text(
                              context.message(pkg.duration),
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            context.message(
                              '₱${AppFormatters.integer(AppSession.packageFare(pkg))}',
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context
                                  .l10n
                                  .thisPackageHasAFixedRouteTheStopsAreAlreadySelectedForYou,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (pkg.highlights.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.whatSIncluded,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...pkg.highlights.map(
                              (h) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(context.message(h))),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            context.l10n.stopsIncluded,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            context.l10n.stopsValue(
                              context.message((pkg.spotIds.length).toString()),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...pkg.spotIds.asMap().entries.map((entry) {
                      final spot = AppSession.allSpots.value
                          .where((s) => s.id == entry.value && s.isActive)
                          .firstOrNull;
                      if (spot == null) {
                        return ListTile(
                          title: Text(context.l10n.stopTemporarilyUnavailable),
                          subtitle: Text(
                            context
                                .l10n
                                .thisPackageCannotBeBookedUntilAllStopsAreAvailable,
                          ),
                        );
                      }
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Text(
                            context.message('${entry.key + 1}'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          context.message(spot.name),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          context.message(spot.categoryLabel),
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.fixedItinerary,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            context.l10n.stopsValueLabel(
                              context.message((pkg.spotIds.length).toString()),
                              context.message(
                                (AppFormatters.integer(
                                  AppSession.packageFare(pkg),
                                )).toString(),
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: context.l10n.bookThisTour,
                  onPressed: () {
                    try {
                      AppSession.selectPackage(pkg);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.message(ErrorMessages.forError(e)),
                          ),
                        ),
                      );
                      return;
                    }
                    context.push('/tourist/fare-summary');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
