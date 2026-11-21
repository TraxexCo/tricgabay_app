import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';
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

import '../../../core/navigation/launch_preferences.dart';
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

  // How far the Explore sheet is pulled up, as a fraction of the screen.
  // Null until the tourist drags it; the resting height is used then.
  // Map buttons and the legend ride just above it.
  final _sheetExtent = ValueNotifier<double?>(null);
  double _sheetMinExtent = 0.3;
  double _sheetInitialExtent = 0.46;
  double _sheetMaxExtent = 0.85;

  /// The sheet runs behind the floating menu bar to the bottom of the
  /// screen. Its resting height shows the header, the filters and one full
  /// row of spot cards; collapsed, it still shows the header and filters
  /// above the menu bar.
  void _measureSheet(double height) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final menuBar = MediaQuery.paddingOf(context).bottom;
    final header = 104 + 44 * scale;
    final collapsed = (menuBar + header) / height;
    final resting = (menuBar + header + _spotRowHeight(context) + 8) / height;
    // Fully open, the sheet stops just under the greeting row.
    final greeting = MediaQuery.paddingOf(context).top + 28 + 58 * scale;
    _sheetMaxExtent = ((height - greeting) / height).clamp(0.65, 0.92);
    _sheetMinExtent = collapsed.clamp(0.18, 0.5);
    _sheetInitialExtent = resting.clamp(_sheetMinExtent, 0.55);
  }

  /// Places [overlay] just above the sheet. `compact` is true when the map
  /// strip between the search bar and the sheet is too short for the
  /// stacked map buttons.
  Widget _aboveSheet(Widget Function(double bottom, bool compact) overlay) {
    return ValueListenableBuilder<double?>(
      valueListenable: _sheetExtent,
      builder: (context, dragged, _) => LayoutBuilder(
        builder: (context, constraints) {
          final extent = dragged ?? _sheetInitialExtent;
          // Out of the way while the sheet covers most of the map.
          if (extent > _sheetInitialExtent + 0.08) {
            return const SizedBox.shrink();
          }
          final bottom = constraints.maxHeight * extent + 14;
          final topBar =
              MediaQuery.paddingOf(context).top +
              84 +
              84 * MediaQuery.textScalerOf(context).scale(1);
          final compact = constraints.maxHeight - bottom - topBar < 180;
          return Stack(children: [overlay(bottom, compact)]);
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
            _measureSheet(canvasHeight);
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
                    // Runs behind the floating menu bar to the screen edge;
                    // its list is padded so the last cards clear the bar.
                    NotificationListener<DraggableScrollableNotification>(
                      onNotification: (n) {
                        _sheetExtent.value = n.extent;
                        return false;
                      },
                      child: _exploreSheet(),
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

  /// Before Android's own prompt, say once why the map wants location. A
  /// "Not now" is remembered; the my-location button can still ask later.
  Future<bool> _explainLocationFirst() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) return false;
    final permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.always ||
        permission == geo.LocationPermission.whileInUse) {
      return true;
    }
    if (permission == geo.LocationPermission.deniedForever) return false;
    if (await LaunchPreferences.locationExplained()) return false;
    // Let the first frame and any sign-in prompts settle first.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? true)) return false;
    final allow = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => const _LocationExplainerSheet(),
    );
    await LaunchPreferences.markLocationExplained();
    return allow == true;
  }

  Future<void> _startLocationTracking() async {
    try {
      if (!await _explainLocationFirst() || !mounted) return;
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
