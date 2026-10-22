import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/prototype/prototype_session.dart';

class TourPackagesScreen extends StatelessWidget {
  const TourPackagesScreen({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PrototypeSession.farePolicy,
    builder: (context, _) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: AppBar(
          title: Text(
            'Tour Packages',
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.surface,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
          itemCount: TourPackageModel.catalog.length,
          itemBuilder: (context, index) {
            final pkg = TourPackageModel.catalog[index];
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
                          SafeAppImage(path: pkg.imageUrl, fit: BoxFit.cover),
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
                              'CURATED EXPERIENCE',
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                pkg.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${pkg.spotIds.length} Stops',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    pkg.duration,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pkg.description,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fixed fare: ₱${PrototypeSession.packageFare(pkg).toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push(
                                '/tourist/tour-packages/${pkg.id}',
                              ),
                              child: Text(
                                'View Details',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
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
            label: const Text('Build Your Own Day'),
          ),
        ),
      );
    },
  );
}
