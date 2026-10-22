import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: PrototypeSession.favorites,
      builder: (context, favoriteIds, _) {
        final favorites = PrototypeSession.allSpots.value
            .where((spot) => favoriteIds.contains(spot.id))
            .toList();
        return Scaffold(
          backgroundColor: const Color(0xFFF5F8FB),
          appBar: AppBar(
            title: Text(
              'Saved Places',
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.surface,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
          ),
          body: favorites.isEmpty
              ? const EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: 'Save places you love',
                  subtitle:
                      'Tap the heart on any tourist spot to keep it here.',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75, // adjusted for the new button
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final spot = favorites[index];
                    return GestureDetector(
                      onTap: () => context.push('/tourist/spot/${spot.id}'),
                      child: AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  SafeAppImage(
                                    path: spot.imageUrls.isNotEmpty
                                        ? spot.imageUrls.first
                                        : '',
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () =>
                                          PrototypeSession.toggleFavorite(
                                            spot.id,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(
                                            alpha: 0.9,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.favorite_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    spot.name,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    spot.categoryLabel,
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      alignment: Alignment.centerLeft,
                                    ),
                                    onPressed: () {
                                      PrototypeSession.toggleItinerary(spot);
                                      AppSnackbar.showSuccess(
                                        context,
                                        'Added to itinerary!',
                                      );
                                    },
                                    child: const Text(
                                      '+ Add to Trip',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
