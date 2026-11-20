import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: AppSession.favorites,
      builder: (context, favoriteIds, _) {
        final favorites = AppSession.allSpots.value
            .where((spot) => favoriteIds.contains(spot.id))
            .toList();
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.savedPlaces)),
          body: favorites.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.favorite_border_rounded,
                  title: context.l10n.savePlacesYouLove,
                  subtitle:
                      context.l10n.tapTheHeartOnAnyTouristSpotToKeepItHere,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width < 360 ||
                            MediaQuery.textScalerOf(context).scale(14) > 20
                        ? 1
                        : 2,
                    mainAxisExtent:
                        240 + MediaQuery.textScalerOf(context).scale(14) * 5,
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
                                    child: IconButton(
                                      tooltip: context.l10n.removeSavedPlace,
                                      onPressed: () =>
                                          AppSession.toggleFavorite(spot.id),
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.favorite_rounded),
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
                                    context.message(spot.name),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    context.message(spot.categoryLabel),
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
                                      AppSession.toggleItinerary(spot);
                                      AppSnackbar.showSuccess(
                                        context,
                                        MessageCode.addedToItinerary,
                                      );
                                    },
                                    child: Text(
                                      context.l10n.addToTrip,
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
