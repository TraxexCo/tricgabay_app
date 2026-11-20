import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/list_skeleton.dart';
import '../../../core/services/realtime_refresh_policy.dart';
import '../../../core/prototype/prototype_session.dart';

class TourPackagesScreen extends StatelessWidget {
  const TourPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      PrototypeSession.farePolicy,
      PrototypeSession.tourPackages,
      PrototypeSession.loadingSections,
    ]),
    builder: (context, _) {
      final publishedFares = PrototypeSession.farePolicy.value.packageFares;
      final packages = PrototypeSession.tourPackages.value
          .where((package) => publishedFares.containsKey(package.id))
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.tourPackages)),
        body:
            packages.isEmpty &&
                PrototypeSession.loadingSections.value.contains(
                  RemoteSection.spots,
                )
            ? const ListSkeleton()
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
                itemCount: packages.isEmpty ? 1 : packages.length,
                itemBuilder: (context, index) {
                  if (packages.isEmpty) {
                    return Center(child: Text(context.l10n.unavailable));
                  }
                  final pkg = packages[index];
                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: 160,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                SafeAppImage(
                                  path: pkg.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: .08),
                                        Colors.black.withValues(alpha: .58),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 18,
                                  bottom: 16,
                                  child: Text(
                                    context.l10n.curatedExperience,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      context.message(pkg.name),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              context.l10n.stopsValue(
                                                context.message(
                                                  (pkg.spotIds.length)
                                                      .toString(),
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (pkg.duration.isNotEmpty)
                                          const SizedBox(width: 8),
                                        if (pkg.duration.isNotEmpty)
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary
                                                    .withValues(alpha: 0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                context.message(pkg.duration),
                                                style: GoogleFonts.poppins(
                                                  color: AppColors.secondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.message(pkg.description),
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      context.l10n.fixedFareValue(
                                        context.message(
                                          (AppFormatters.integer(
                                            PrototypeSession.packageFare(pkg),
                                          )).toString(),
                                        ),
                                      ),
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () => context.push(
                                        '/tourist/tour-packages/${pkg.id}',
                                      ),
                                      child: Text(
                                        context.l10n.viewDetails,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  );
                },
              ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: OutlinedButton.icon(
            onPressed: () {
              PrototypeSession.startCustomItinerary();
              context.push('/tourist/itinerary');
            },
            icon: const Icon(Icons.tune_rounded),
            label: Text(context.l10n.buildYourOwnDay),
          ),
        ),
      );
    },
  );
}
