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
part 'tourist_home_cards.dart';
part 'tourist_home_sections.dart';

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

  static const _labelZoom = 15.0;
  bool _showPinLabels = false;

  void _onCameraChanged(CameraChangedEventData event) {
    final show = event.cameraState.zoom >= _labelZoom;
    if (show == _showPinLabels) return;
    _showPinLabels = show;
    unawaited(_recreatePins(_filteredSpots));
  }

  // How far the Explore sheet is pulled up (fraction of the space above
  // the menu bar). Map buttons and the legend ride just above it.
  final _sheetExtent = ValueNotifier<double>(_sheetInitialExtent);
  static const _sheetInitialExtent = 0.36;

  Widget _aboveSheet(Widget Function(double bottom) overlay) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return ValueListenableBuilder<double>(
      valueListenable: _sheetExtent,
      builder: (context, extent, _) => LayoutBuilder(
        builder: (context, constraints) {
          // Out of the way while the sheet covers most of the map.
          if (extent > 0.55) return const SizedBox.shrink();
          final space = constraints.maxHeight - inset;
          return Stack(children: [overlay(inset + space * extent + 16)]);
        },
      ),
    );
  }

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
    _sheetExtent.dispose();
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
                                  onCameraChangeListener: _onCameraChanged,
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
                    _topBar(),

                    // ── Left-side Map Legend ──────────────────────────────────────
                    _aboveSheet(_mapLegend),

                    // ── Right-side map controls ───────────────────────────────────
                    _aboveSheet(_mapControls),

                    // ── Bottom draggable sheet ────────────────────────────────────
                    // The sheet ends at the top of the floating menu bar, so
                    // its cards are never hidden behind it.
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom,
                      ),
                      child:
                          NotificationListener<DraggableScrollableNotification>(
                            onNotification: (n) {
                              _sheetExtent.value = n.extent;
                              return false;
                            },
                            child: _exploreSheet(),
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
              // Names only when zoomed in: at town level 29 labels pile
              // into an unreadable cluster in the centre.
              textField: _showPinLabels ? spot.name : null,
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
