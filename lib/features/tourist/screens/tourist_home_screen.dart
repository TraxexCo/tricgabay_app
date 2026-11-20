import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import '../../../core/services/error_messages.dart';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;

import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../models/tourist_spot_model.dart';

import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../spot_filters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class TouristHomeScreen extends StatefulWidget {
  final Widget? mapPlaceholder;
  const TouristHomeScreen({super.key}) : mapPlaceholder = null;
  @visibleForTesting
  const TouristHomeScreen.withMapPlaceholder({super.key, required Widget map})
    : mapPlaceholder = map;

  @override
  State<TouristHomeScreen> createState() => _TouristHomeScreenState();
}

class _TouristHomeScreenState extends State<TouristHomeScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  StreamSubscription<geo.Position>? _positionSubscription;

  /// Maps annotation.id → TouristSpotModel so we can look up which spot was tapped.
  final Map<String, TouristSpotModel> _annotationSpotMap = {};

  List<TouristSpotModel> get _spots => AppSession.allSpots.value;
  String _selectedCategory = MessageCode.all;
  late List<TouristSpotModel> _filteredSpots;
  final _pinBitmaps = <Color, Future<Uint8List>>{};
  List<TouristSpotModel>? _pendingPins;
  bool _updatingPins = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _filteredSpots = _spots;
    AppSession.allSpots.addListener(_catalogChanged);
    AppSession.focusedSpotId.addListener(_onFocusedSpotChanged);
    if (widget.mapPlaceholder == null) _startLocationTracking();
  }

  @override
  void dispose() {
    AppSession.allSpots.removeListener(_catalogChanged);
    AppSession.focusedSpotId.removeListener(_onFocusedSpotChanged);
    _annotationManager?.deleteAll();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _onFocusedSpotChanged() async {
    final spotId = AppSession.focusedSpotId.value;
    if (spotId != null) {
      final spot = _spots.where((s) => s.id == spotId).firstOrNull;
      if (spot == null) return;
      // Wait for navigation stack to settle
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(spot.longitude, spot.latitude)),
          zoom: 16.0,
        ),
      );
      _showSpotBottomSheet(spot);
      AppSession.focusedSpotId.value = null;
    }
  }

  void _showSpotBottomSheet(TouristSpotModel spot) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SpotInfoSheet(spot: spot),
    );
  }

  // ── Map callbacks ──────────────────────────────────────────────────────────

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;

    // Hide compass & scale — keep UI clean
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );

    // Disable rotation & pitch for a simple 2‑D tourist view
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );

    await _addSpotAnnotations(mapboxMap);
  }

  Future<void> _addSpotAnnotations(MapboxMap mapboxMap) async {
    final manager = await mapboxMap.annotations.createPointAnnotationManager();
    _annotationManager = manager;
    await manager.setIconAllowOverlap(false);
    await manager.setTextAllowOverlap(false);

    // Register tap listener using tapEvents method API (v2.30)
    manager.tapEvents(onTap: _onAnnotationTapped);

    await _recreatePins(_filteredSpots);
  }

  void _onAnnotationTapped(PointAnnotation annotation) {
    final spot = _annotationSpotMap[annotation.id];
    if (spot == null || !mounted) return;

    // Fly camera to the spot (offset upward so the bottom sheet doesn't cover it)
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

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.isFilipino,
      builder: (context, isFilipino, _) => Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context);
            final needsScrolling =
                constraints.maxHeight < 500 || scale.scale(14) > 18;
            final canvasHeight = needsScrolling
                ? constraints.maxHeight.clamp(
                    480 + scale.scale(300),
                    double.infinity,
                  )
                : constraints.maxHeight;
            return SingleChildScrollView(
              child: SizedBox(
                height: canvasHeight,
                child: Stack(
                  children: [
                    // ── Full-screen Mapbox map ───────────────────────────────────────
                    widget.mapPlaceholder ??
                        (kIsWeb
                            ? const WebMapFallback()
                            : MapSurface(
                                builder: (context) => MapWidget(
                                  styleUri: MapboxConfig.mapStyle,
                                  onMapCreated: _onMapCreated,
                                  viewport: CameraViewportState(
                                    center: Point(
                                      coordinates: Position(
                                        MapboxConfig.bustosLng,
                                        MapboxConfig.bustosLat,
                                      ),
                                    ),
                                    zoom: MapboxConfig.defaultZoom,
                                  ),
                                ),
                              )),

                    // ── Top bar ───────────────────────────────────────────────────
                    SafeArea(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ValueListenableBuilder<String>(
                                          valueListenable:
                                              AppSession.currentUserName,
                                          builder: (ctx, name, _) {
                                            final hour = DateTime.now().hour;
                                            String greeting =
                                                context.l10n.goodMorning;
                                            if (hour >= 12 && hour < 17) {
                                              greeting =
                                                  context.l10n.goodAfternoon;
                                            }
                                            if (hour >= 17) {
                                              greeting =
                                                  context.l10n.goodEvening;
                                            }
                                            return Text(
                                              context.message(
                                                '$greeting, $name',
                                              ),
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
                                    () =>
                                        context.push('/tourist/notifications'),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
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
                                      const Icon(
                                        Icons.search_rounded,
                                        color: AppColors.primary,
                                      ),
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
                    ),

                    // ── Left-side Map Legend ──────────────────────────────────────
                    Positioned(
                      left: 16,
                      bottom: 300,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                    ),

                    // ── Right-side map controls ───────────────────────────────────
                    Positioned(
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
                          _mapButton(
                            Icons.center_focus_strong_rounded,
                            () {
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
                            },
                            tooltip: context.l10n.resetMap,
                          ),
                          const SizedBox(height: 10),
                          _mapButton(
                            Icons.sos_rounded,
                            () => context.push('/tourist/emergency'),
                            foreground: AppColors.danger,
                            tooltip: context.l10n.emergency,
                          ),
                        ],
                      ),
                    ),

                    // ── Bottom draggable sheet ────────────────────────────────────
                    DraggableScrollableSheet(
                      initialChildSize: 0.36,
                      minChildSize: 0.22,
                      maxChildSize: 0.86,
                      builder: (ctx, ctrl) => Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F7FC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                    context.l10n.spotCount(
                                      _filteredSpots.length,
                                    ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Row(
                                children: spotFilters
                                    .map(
                                      (cat) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
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
                              height:
                                  96 +
                                  120 *
                                      MediaQuery.textScalerOf(context).scale(1),
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 8,
                                ),
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
                                        duration:
                                            MediaQuery.disableAnimationsOf(
                                              context,
                                            )
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                          color: Colors.white.withValues(
                                            alpha: .18,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.route_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 13),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ValueListenableBuilder<
                                              List<TouristSpotModel>
                                            >(
                                              valueListenable:
                                                  AppSession.itinerary,
                                              builder: (context, itinerary, child) {
                                                return Text(
                                                  context.message(
                                                    itinerary.isEmpty
                                                        ? context
                                                              .l10n
                                                              .buildADayYouLlRemember
                                                        : context.l10n
                                                              .buildYourDayWithStops(
                                                                itinerary
                                                                    .length,
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
                                              context
                                                  .l10n
                                                  .choosePlacesSeeYourFareBookARide,
                                              style: GoogleFonts.poppins(
                                                color: Colors.white.withValues(
                                                  alpha: .85,
                                                ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                    onPressed: () =>
                                        context.go('/tourist/search'),
                                    child: Text(context.l10n.explore),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              height:
                                  96 +
                                  120 *
                                      MediaQuery.textScalerOf(context).scale(1),
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 8,
                                ),
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
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Future<bool> _ensureLocationPermission() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) return false;
    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    return permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse;
  }

  Future<void> _startLocationTracking() async {
    try {
      if (!await _ensureLocationPermission() || !mounted) return;
      _positionSubscription =
          geo.Geolocator.getPositionStream(
            locationSettings: const geo.LocationSettings(
              accuracy: geo.LocationAccuracy.high,
              distanceFilter: 8,
            ),
          ).listen((position) {
            AppSession.userLatitude.value = position.latitude;
            AppSession.userLongitude.value = position.longitude;
          }, onError: (Object error) => ErrorMessages.forError(error));
    } catch (error) {
      ErrorMessages.forError(error);
    }
  }

  Widget _mapButton(
    IconData icon,
    VoidCallback onTap, {
    Color foreground = AppColors.textPrimary,
    String? tooltip,
  }) => Semantics(
    label: tooltip,
    button: true,
    onTap: onTap,
    excludeSemantics: true,
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        onPressed: onTap,
        tooltip: context.optionalMessage(tooltip),
        icon: Icon(icon, color: foreground),
        splashRadius: 24,
      ),
    ),
  );

  Widget _actionCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
    Color color,
  ) => SizedBox(
    width: 152 * MediaQuery.textScalerOf(context).scale(1),
    child: Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE5F2), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x180D1B2A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const Spacer(),
              Text(
                context.message(title),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                context.message(subtitle),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _flyToMyLocation() async {
    try {
      if (!await geo.Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.locationServicesAreDisabledPleaseEnableGps,
              ),
            ),
          );
        }
        return;
      }
      if (!await _ensureLocationPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.locationPermissionDeniedEnableItInSettings,
              ),
            ),
          );
        }
        return;
      }
      final pos = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      AppSession.userLatitude.value = pos.latitude;
      AppSession.userLongitude.value = pos.longitude;
      await _mapboxMap?.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: 15.0,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.message(ErrorMessages.forError(e)))),
        );
      }
    }
  }

  void _catalogChanged() => _filterPins(_selectedCategory);

  void _filterPins(String category) {
    final filtered = filterSpots(_spots, category);
    setState(() {
      _selectedCategory = category;
      _filteredSpots = filtered;
    });
    _recreatePins(filtered);
  }

  Future<void> _recreatePins(List<TouristSpotModel> spots) async {
    _pendingPins = spots;
    if (_annotationManager == null || _updatingPins) return;
    _updatingPins = true;
    try {
      while (mounted && _pendingPins != null) {
        final batch = _pendingPins!;
        _pendingPins = null;
        final manager = _annotationManager!;
        final options = await Future.wait(
          batch.map((spot) async {
            final color = _categoryColor(spot.category);
            return PointAnnotationOptions(
              geometry: Point(
                coordinates: Position(spot.longitude, spot.latitude),
              ),
              image: await _pinBitmaps.putIfAbsent(
                color,
                () => _buildPinBitmap(color),
              ),
              iconSize: 1.0,
              iconAnchor: IconAnchor.BOTTOM,
              textField: spot.name,
              textOffset: [0.0, 0.5],
              textColor: AppColors.textPrimary.toARGB32(),
              textHaloColor: Colors.white.toARGB32(),
              textHaloWidth: 1.5,
              textSize: 12.0,
            );
          }),
        );
        if (!mounted) return;
        if (_pendingPins != null) continue;
        _annotationSpotMap.clear();
        await manager.deleteAll();
        if (!mounted || options.isEmpty) continue;
        final created = await manager.createMulti(options);
        for (var index = 0; index < created.length; index++) {
          final annotation = created[index];
          if (annotation != null) {
            _annotationSpotMap[annotation.id] = batch[index];
          }
        }
      }
    } catch (error) {
      _pinBitmaps.clear();
      ErrorMessages.forError(error);
    } finally {
      _updatingPins = false;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Horizontal spot card
// ─────────────────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  const _SpotCard({required this.spot, required this.onTap});

  final TouristSpotModel spot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148 * MediaQuery.textScalerOf(context).scale(1),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A0D1B2A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: SafeAppImage(
                path: spot.imageUrls.isNotEmpty ? spot.imageUrls.first : '',
                height: 96,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.message(spot.name),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _categoryColor(
                            spot.category,
                          ).withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.message(spot.categoryLabel),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor(spot.category),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: AppColors.textSecondary,
                      ),
                      Text(
                        context.l10n.kmValue(
                          context.message((spot.distanceFromTown).toString()),
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spot info bottom sheet (shown on pin tap or card tap)
// ─────────────────────────────────────────────────────────────────────────────

class _SpotInfoSheet extends StatelessWidget {
  const _SpotInfoSheet({required this.spot});
  final TouristSpotModel spot;

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(spot.category);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x330D1B2A),
                blurRadius: 30,
                offset: Offset(0, -6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCED6E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),

                // Hero image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Stack(
                      children: [
                        SafeAppImage(
                          path: spot.imageUrls.isNotEmpty
                              ? spot.imageUrls.first
                              : '',
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Category badge overlay
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.message(spot.categoryLabel),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 12,
                          right: 12,
                          child: IconButton(
                            tooltip: context.l10n.closeAttractionDetails,
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .45),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Info body
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.message(spot.name),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Meta row
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              context.message(spot.openingHours),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.payments_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.message(spot.entranceFee),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.message(spot.description),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.push('/tourist/spot/${spot.id}');
                              },
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                              ),
                              label: Text(
                                context.l10n.viewDetails,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: spot.isTemporarilyClosed
                                  ? null
                                  : () {
                                      AppSession.startCustomItinerary();
                                      AppSession.toggleItinerary(
                                        spot,
                                      ); // ADD THE SPOT FIRST
                                      Navigator.pop(context);
                                      context.push('/tourist/itinerary');
                                    },
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: Text(
                                context.message(
                                  spot.isTemporarilyClosed
                                      ? MessageCode.closed
                                      : MessageCode.addToTripLabel,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin bitmap builder — draws a coloured teardrop pin with dart:ui
// ─────────────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildPinBitmap(Color color) async {
  const double w = 48;
  const double h = 64;
  const double cx = w / 2;
  const double r = 19.0; // circle radius

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

  // Drop shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0);
  canvas.drawOval(Rect.fromLTWH(cx - 14, h - 10, 28, 10), shadowPaint);

  // Teardrop path: circle top + triangle pointer at bottom
  final path = Path()
    ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r));

  final pointerPath = Path()
    ..moveTo(cx - 7, r + 12)
    ..quadraticBezierTo(cx, h - 2, cx + 7, r + 12)
    ..close();

  // Fill
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawPath(path, fill);
  canvas.drawPath(pointerPath, fill);

  // White border
  final border = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  canvas.drawPath(path, border);
  canvas.drawPath(pointerPath, border);

  // White inner dot
  canvas.drawCircle(
    Offset(cx, r),
    8,
    Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..style = PaintingStyle.fill,
  );

  final picture = recorder.endRecording();
  final img = await picture.toImage(w.toInt(), h.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

// ─────────────────────────────────────────────────────────────────────────────
// Category helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _categoryColor(SpotCategory cat) => switch (cat) {
  SpotCategory.church => const Color(0xFFCE1126), // red
  SpotCategory.nature => const Color(0xFF27AE60), // green
  SpotCategory.market => const Color(0xFFD4A017), // gold
  SpotCategory.heritage => const Color(0xFF0038A8), // brand blue
  SpotCategory.park => const Color(0xFF8E44AD), // purple
  SpotCategory.other => const Color(0xFF6B7280), // gray
};
