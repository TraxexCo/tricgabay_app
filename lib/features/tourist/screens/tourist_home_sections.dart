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
          ],
        ),
      ),
    ),
  );

  Widget _mapLegend(double bottom, bool compact) => compact
      ? const Positioned(left: 0, bottom: 0, child: SizedBox.shrink())
      : Positioned(
          left: 16,
          bottom: bottom,
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

  Widget _mapControls(double bottom, bool compact) => Positioned(
    right: 16,
    bottom: bottom,
    child: Flex(
      // A row when the map strip is short, so the buttons never reach the
      // search bar.
      direction: compact ? Axis.horizontal : Axis.vertical,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        _mapButton(
          Icons.my_location_rounded,
          _flyToMyLocation,
          tooltip: context.l10n.myLocation,
        ),
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
    initialChildSize: _sheetInitialExtent,
    minChildSize: _sheetMinExtent,
    maxChildSize: _sheetMaxExtent,
    snap: true,
    snapSizes: [_sheetInitialExtent],
    builder: (ctx, ctrl) => DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x240D1B2A),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: ctrl,
        // Clear the floating menu bar so the last section is reachable.
        padding: EdgeInsets.fromLTRB(
          0,
          10,
          0,
          MediaQuery.paddingOf(context).bottom + 20,
        ),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFC5D0DE),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          _sectionHeader(
            context.l10n.exploreBustos,
            fontSize: 20,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.spotCount(_filteredSpots.length),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _categoryChips(),
          const SizedBox(height: 6),
          SizedBox(
            height: _spotRowHeight(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 14),
              itemCount: _filteredSpots.length,
              itemBuilder: (_, i) => _SpotCard(
                spot: _filteredSpots[i],
                onTap: () => _openSpot(_filteredSpots[i]),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildDayCard(),
          ),
          const SizedBox(height: 24),
          _sectionHeader(
            context.l10n.planYourTrip,
            trailing: TextButton(
              onPressed: () => context.go('/tourist/search'),
              child: Text(context.l10n.explore),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _planShortcuts(),
          ),
        ],
      ),
    ),
  );

  void _openSpot(TouristSpotModel spot) {
    _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(spot.longitude, spot.latitude)),
        zoom: MapboxConfig.spotZoom,
      ),
      MapAnimationOptions(
        duration: MediaQuery.disableAnimationsOf(context) ? 0 : 900,
      ),
    );
    _showSpotBottomSheet(spot);
  }

  Widget _sectionHeader(
    String title, {
    double fontSize = 17,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _categoryChips() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        for (final cat in spotFilters)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(context.message(cat)),
              selected: _selectedCategory == cat,
              showCheckmark: false,
              onSelected: (selected) {
                if (selected) _filterPins(cat);
              },
              selectedColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              labelStyle: GoogleFonts.poppins(
                color: _selectedCategory == cat
                    ? Colors.white
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: _selectedCategory == cat
                    ? FontWeight.w600
                    : FontWeight.w500,
              ),
              backgroundColor: AppColors.surface,
              shape: const StadiumBorder(),
              side: BorderSide(
                color: _selectedCategory == cat
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildDayCard() => Material(
    color: Colors.transparent,
    child: Ink(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          AppSession.startCustomItinerary();
          context.push('/tourist/itinerary');
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<List<TouristSpotModel>>(
                      valueListenable: AppSession.itinerary,
                      builder: (context, itinerary, child) => Text(
                        itinerary.isEmpty
                            ? context.l10n.buildADayYouLlRemember
                            : context.l10n.buildYourDayWithStops(
                                itinerary.length,
                              ),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.choosePlacesSeeYourFareBookARide,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: .86),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  /// Three equal shortcuts side by side. With large text they stack as
  /// rows so the labels stay readable.
  Widget _planShortcuts() {
    final shortcuts = [
      (
        Icons.auto_awesome_outlined,
        context.l10n.tourPackages,
        context.l10n.readyMadeTrips,
        '/tourist/tour-packages',
        AppColors.secondaryDark,
      ),
      (
        Icons.favorite_outline_rounded,
        context.l10n.savedPlaces,
        context.l10n.placesYouSaved,
        '/tourist/favorites',
        AppColors.danger,
      ),
      (
        Icons.receipt_long_outlined,
        context.l10n.myBookings,
        context.l10n.rideUpdates,
        '/tourist/bookings',
        AppColors.primary,
      ),
    ];
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.25;
    Widget tile((IconData, String, String, String, Color) item) {
      final (icon, title, subtitle, route, color) = item;
      final badge = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      );
      final text = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            style: GoogleFonts.poppins(
              fontSize: 12,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
      return Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: stacked
                ? Row(
                    children: [
                      badge,
                      const SizedBox(width: 12),
                      Expanded(child: text),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [badge, const SizedBox(height: 10), text],
                  ),
          ),
        ),
      );
    }

    if (stacked) {
      return Column(
        children: [
          for (final item in shortcuts) ...[
            tile(item),
            if (item != shortcuts.last) const SizedBox(height: 10),
          ],
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in shortcuts) ...[
            Expanded(child: tile(item)),
            if (item != shortcuts.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

/// Height of the horizontal spot-card row, including room for its shadow.
double _spotRowHeight(BuildContext context) =>
    _SpotCard.heightFor(context) + 20;
