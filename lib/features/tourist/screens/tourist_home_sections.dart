part of 'tourist_home_screen.dart';

/// Overlay sections drawn on top of the home map.
extension _TouristHomeSections on _TouristHomeScreenState {
  Widget _topBar() => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Greeting row
            Row(
              children: [
                const AppLogo(size: 46, showShadow: true),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: AppSession.currentUserName,
                        builder: (ctx, name, _) {
                          final hour = DateTime.now().hour;
                          String greeting = context.l10n.goodMorning;
                          if (hour >= 12 && hour < 17) {
                            greeting = context.l10n.goodAfternoon;
                          }
                          if (hour >= 17) {
                            greeting = context.l10n.goodEvening;
                          }
                          return Text(
                            context.message('$greeting, $name'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                      Text(
                        context.l10n.bustosBulacan,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _mapButton(
                  Icons.notifications_none_rounded,
                  () => context.push('/tourist/notifications'),
                  tooltip: context.l10n.notifications,
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Search bar
            GestureDetector(
              onTap: () => context.go('/tourist/search'),
              child: Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220D1B2A),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.whereWouldYouLikeToGo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.tune_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x220D1B2A),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => context.go('/tourist/search'),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.format_list_bulleted_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          context.l10n.listView,
                          style: GoogleFonts.poppins(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _mapLegend() => Positioned(
    left: 16,
    bottom: 300,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180D1B2A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.touristSpot,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _mapControls() => Positioned(
    right: 16,
    bottom: 300,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mapButton(
          Icons.my_location_rounded,
          _flyToMyLocation,
          tooltip: context.l10n.myLocation,
        ),
        const SizedBox(height: 10),
        _mapButton(Icons.center_focus_strong_rounded, () {
          _mapboxMap?.setCamera(
            CameraOptions(
              center: Point(
                coordinates: Position(
                  MapboxConfig.bustosLng,
                  MapboxConfig.bustosLat,
                ),
              ),
              zoom: MapboxConfig.defaultZoom,
            ),
          );
        }, tooltip: context.l10n.resetMap),
        const SizedBox(height: 10),
        _mapButton(
          Icons.sos_rounded,
          () => context.push('/tourist/emergency'),
          foreground: AppColors.danger,
          tooltip: context.l10n.emergency,
        ),
      ],
    ),
  );

  Widget _exploreSheet() => DraggableScrollableSheet(
    initialChildSize: 0.36,
    minChildSize: 0.22,
    maxChildSize: 0.86,
    builder: (ctx, ctrl) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x280D1B2A),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFCED6E0),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // Section header — Explore Bustos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(
                  context.l10n.exploreBustos,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  context.l10n.spotCount(_filteredSpots.length),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: spotFilters
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(context.message(cat)),
                        selected: _selectedCategory == cat,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) _filterPins(cat);
                        },
                        selectedColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedCategory == cat
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: _selectedCategory == cat
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: _selectedCategory == cat
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal spot cards
          SizedBox(
            height: 96 + 120 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 8),
              itemCount: _filteredSpots.length,
              itemBuilder: (_, i) => _SpotCard(
                spot: _filteredSpots[i],
                onTap: () {
                  // Fly map to spot then open sheet
                  _mapboxMap?.flyTo(
                    CameraOptions(
                      center: Point(
                        coordinates: Position(
                          _filteredSpots[i].longitude,
                          _filteredSpots[i].latitude,
                        ),
                      ),
                      zoom: MapboxConfig.spotZoom,
                    ),
                    MapAnimationOptions(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? 0
                          : 900,
                    ),
                  );
                  _showSpotBottomSheet(_filteredSpots[i]);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Build itinerary CTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                AppSession.startCustomItinerary();
                context.push('/tourist/itinerary');
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x440038A8),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ValueListenableBuilder<List<TouristSpotModel>>(
                            valueListenable: AppSession.itinerary,
                            builder: (context, itinerary, child) {
                              return Text(
                                context.message(
                                  itinerary.isEmpty
                                      ? context.l10n.buildADayYouLlRemember
                                      : context.l10n.buildYourDayWithStops(
                                          itinerary.length,
                                        ),
                                ),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              );
                            },
                          ),
                          Text(
                            context.l10n.choosePlacesSeeYourFareBookARide,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: .85),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Plan your trip section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(
                  context.l10n.planYourTrip,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/tourist/search'),
                  child: Text(context.l10n.explore),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 96 + 120 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20, right: 8),
              children: [
                _actionCard(
                  context,
                  Icons.auto_awesome_outlined,
                  context.l10n.tourPackages,
                  context.l10n.readyMadeTrips,
                  '/tourist/tour-packages',
                  AppColors.secondary,
                ),
                _actionCard(
                  context,
                  Icons.favorite_outline_rounded,
                  context.l10n.savedPlaces,
                  context.l10n.placesYouSaved,
                  '/tourist/favorites',
                  const Color(0xFFE8675D),
                ),
                _actionCard(
                  context,
                  Icons.receipt_long_outlined,
                  context.l10n.myBookings,
                  context.l10n.rideUpdates,
                  '/tourist/bookings',
                  AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
