import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show Size;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/sharing_location_chip.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../models/booking_model.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/consent_state.dart';
import '../../../core/services/driver_availability_controller.dart';
import '../../../core/services/driver_location_guard.dart';
import '../../../core/services/location_gateway.dart';
import '../../../core/services/pickup_service_area.dart';
import '../../../core/services/place_name_service.dart';
import '../../../core/config/mapbox_config.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  MapboxMap? mapboxMap;
  bool _isLocating = false;
  bool _isChangingAvailability = false;
  String? _locationMessage;
  // The map follows the driver until they pan it; the recenter button
  // turns following back on.
  bool _followDriver = true;
  String? _townName;
  late final DriverAvailabilityController _availabilityController;
  PickupServiceArea _serviceArea = const PickupServiceArea(
    MapboxConfig.bustosLat,
    MapboxConfig.bustosLng,
    8,
  );

  geo.LocationSettings get _onlineLocationSettings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationTitle: currentAppL10n.appDriverIsOnline(AppBrand.name),
          notificationText: currentAppL10n.liveLocationIsActiveForTripMatching,
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  @override
  void initState() {
    super.initState();
    _availabilityController = DriverAvailabilityController(
      location: const GeolocatorLocationGateway(),
      writeOnline: (value) async {
        if (BackendConfig.isConfigured) {
          await BackendRepository.setDriverOnline(value);
        }
      },
      publish: _publishDriverLocation,
      onPosition: _receiveDriverPosition,
      currentSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
      streamSettings: _onlineLocationSettings,
    );
    if (AppSession.isDriverOnline.value) {
      // Never raise the system permission prompt over the privacy notice.
      unawaited(
        ConsentState.whenClear().then((_) {
          if (mounted) _checkLocationPermission();
        }),
      );
    }
    AppSession.isDriverOnline.addListener(_onlineStateChanged);
    if (BackendConfig.isConfigured) unawaited(_loadServiceArea());
  }

  Future<void> _loadServiceArea() async {
    try {
      final area = await BackendRepository.loadPickupServiceArea();
      if (mounted) setState(() => _serviceArea = area);
    } catch (_) {
      // Keep the built-in Bustos centre; the label is only informational.
    }
  }

  @override
  void dispose() {
    AppSession.isDriverOnline.removeListener(_onlineStateChanged);
    unawaited(_availabilityController.dispose());
    super.dispose();
  }

  /// The app can put the driver back online by itself once location returns;
  /// start sharing again so the home screen keeps publishing.
  void _onlineStateChanged() {
    if (AppSession.isDriverOnline.value &&
        !_availabilityController.isSharing &&
        !_availabilityController.isBusy &&
        mounted) {
      unawaited(_checkLocationPermission());
    }
  }

  bool get _hasActiveTrip {
    final activeId = AppSession.activeDriverBookingId;
    if (activeId == null) return false;
    return AppSession.bookings.value.any(
      (booking) =>
          booking.id == activeId &&
          (booking.status == BookingStatus.accepted ||
              booking.status == BookingStatus.ongoing),
    );
  }

  Future<bool> _checkLocationPermission() async {
    if (_isLocating) return false;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      final result = await _availabilityController.resumeSharing();
      _locationMessage = result.message;
      return result.success;
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _receiveDriverPosition(geo.Position position) {
    AppSession.userLatitude.value = position.latitude;
    AppSession.userLongitude.value = position.longitude;
    if (_followDriver) _updateCamera(animate: true);
    unawaited(_lookUpTown(position.latitude, position.longitude));
  }

  Future<void> _lookUpTown(double lat, double lng) async {
    final name = await PlaceNameService.townName(lat, lng);
    if (mounted && name != null && name != _townName) {
      setState(() => _townName = name);
    }
  }

  void _recenter() {
    setState(() => _followDriver = true);
    _updateCamera(animate: true);
  }

  Future<void> _publishDriverLocation(geo.Position position) async {
    if (BackendConfig.isConfigured) {
      try {
        await BackendRepository.publishLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          heading: position.heading,
          speed: position.speed,
          recordedAt: position.timestamp,
          isMocked: position.isMocked,
        );
        if (mounted &&
            _locationMessage ==
                MessageCode.liveLocationIsReconnectingKeepTheAppOpen) {
          setState(() => _locationMessage = null);
        }
      } catch (_) {
        if (mounted &&
            _locationMessage !=
                MessageCode.liveLocationIsReconnectingKeepTheAppOpen) {
          setState(
            () => _locationMessage =
                MessageCode.liveLocationIsReconnectingKeepTheAppOpen,
          );
        }
      }
    }
    final driverName = AppSession.currentDriverName.value;
    AppSession.adminDrivers.value = AppSession.adminDrivers.value
        .map(
          (driver) => driver['name'] == driverName
              ? {
                  ...driver,
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'heading': position.heading,
                  'speed': position.speed,
                  'locationUpdatedAt': DateTime.now().toIso8601String(),
                }
              : driver,
        )
        .toList();
  }

  Future<void> _setDriverAvailability(bool value) async {
    if (_isChangingAvailability) return;
    if (!value && _hasActiveTrip) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.finishOrCancelTheActiveTripBeforeGoingOffline,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isChangingAvailability = true);
    try {
      final result = await _availabilityController.setOnline(value);
      if (!result.success || !mounted) {
        if (mounted && result.message != null) {
          setState(() => _locationMessage = result.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.message(result.message!))),
          );
        }
        return;
      }
      AppSession.isDriverOnline.value = value;
      if (!value) unawaited(DriverLocationGuard.driverChoseOffline());
      _locationMessage = null;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isChangingAvailability = false);
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;
    mapboxMap.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    _updateCamera(zoom: 15);
    final lat = AppSession.userLatitude.value;
    final lng = AppSession.userLongitude.value;
    if (lat != null && lng != null) unawaited(_lookUpTown(lat, lng));
  }

  /// Moves the camera to the driver without touching the zoom the driver
  /// chose, so pinch-zooming isn't undone by the next GPS update.
  void _updateCamera({bool animate = false, double? zoom}) {
    final map = mapboxMap;
    if (map == null) return;
    final camera = CameraOptions(
      center: Point(
        coordinates: Position(
          AppSession.userLongitude.value ?? MapboxConfig.bustosLng,
          AppSession.userLatitude.value ?? MapboxConfig.bustosLat,
        ),
      ),
      zoom: zoom,
    );
    if (animate) {
      map.easeTo(camera, MapAnimationOptions(duration: 600));
    } else {
      map.setCamera(camera);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const AppLogo(size: 48, showShadow: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: AppSession.currentDriverName,
                          builder: (context, driverName, _) {
                            return Text(
                              context.l10n.goodMorningValue(
                                context.message((driverName).toString()),
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.verifiedAppDriver(AppBrand.name),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: context.l10n.notifications,
                    button: true,
                    onTap: () => context.push('/driver/notifications'),
                    excludeSemantics: true,
                    child: IconButton(
                      tooltip: context.l10n.notifications,
                      onPressed: () => context.push('/driver/notifications'),
                      icon: const Icon(Icons.notifications_none_rounded),
                    ),
                  ),
                  Semantics(
                    label: context.l10n.emergencyHelp,
                    button: true,
                    onTap: () => context.push('/driver/emergency'),
                    excludeSemantics: true,
                    child: IconButton(
                      tooltip: context.l10n.emergencyHelp,
                      onPressed: () => context.push('/driver/emergency'),
                      icon: const Icon(
                        Icons.sos_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ValueListenableBuilder<bool>(
                valueListenable: AppSession.isDriverOnline,
                builder: (context, isOnline, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
                          ),
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.message(
                                          isOnline
                                              ? MessageCode.youReReadyToRide
                                              : MessageCode.youReOffline,
                                        ),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        context.message(
                                          isOnline
                                              ? MessageCode
                                                    .weLlSendNearbyBookingsYourWay
                                              : MessageCode
                                                    .goOnlineToStartReceivingBookingRequests,
                                        ),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Semantics(
                                  label: context.l10n.goOnline,
                                  child: Switch.adaptive(
                                    value: isOnline,
                                    activeTrackColor: AppColors.success,
                                    onChanged: _isChangingAvailability
                                        ? null
                                        : _setDriverAvailability,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ValueListenableBuilder<double?>(
                              valueListenable: AppSession.userLatitude,
                              builder: (context, lat, _) {
                                final scale = MediaQuery.textScalerOf(
                                  context,
                                ).scale(1);
                                final showsMap = isOnline && lat != null;
                                return Container(
                                  // Online with a fix, the map is the
                                  // driver's main view; otherwise a slim
                                  // status panel.
                                  height: showsMap
                                      ? (MediaQuery.sizeOf(context).height *
                                                0.3)
                                            .clamp(200, 300)
                                      : 108 * scale,
                                  decoration: BoxDecoration(
                                    // Opaque, so the white status text stays
                                    // readable wherever the panel sits.
                                    color: AppColors.darkSurface,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: !isOnline
                                      ? _isChangingAvailability
                                            // Getting a GPS fix can take
                                            // several seconds; show it.
                                            ? _locationPlaceholder(
                                                icon: Icons.my_location_rounded,
                                                title: MessageCode
                                                    .findingYourLocation,
                                                subtitle: MessageCode
                                                    .checkingGpsAndPermission,
                                                loading: true,
                                              )
                                            : _locationPlaceholder(
                                                icon:
                                                    Icons.location_off_outlined,
                                                title: MessageCode
                                                    .locationSharingIsOff,
                                                subtitle:
                                                    // Say why going online failed;
                                                    // otherwise the switch just
                                                    // seems to ignore the tap.
                                                    _locationMessage ??
                                                    MessageCode
                                                        .goOnlineToActivateTheDriverMap,
                                              )
                                      : lat == null
                                      ? InkWell(
                                          onTap: _isLocating
                                              ? null
                                              : _checkLocationPermission,
                                          child: _locationPlaceholder(
                                            icon: _isLocating
                                                ? Icons.my_location_rounded
                                                : Icons.gps_off_rounded,
                                            title: _isLocating
                                                ? MessageCode
                                                      .findingYourLocation
                                                : MessageCode
                                                      .locationUnavailable,
                                            subtitle:
                                                _locationMessage ??
                                                MessageCode
                                                    .checkingGpsAndPermission,
                                            loading: _isLocating,
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            Positioned.fill(
                                              child: kIsWeb
                                                  ? WebMapFallback(
                                                      title: context
                                                          .l10n
                                                          .bustosTownCentre,
                                                      compact: true,
                                                    )
                                                  : MapSurface(
                                                      builder: (context) => MapWidget(
                                                        onMapCreated:
                                                            _onMapCreated,
                                                        styleUri: MapboxStyles
                                                            .MAPBOX_STREETS,
                                                        // The map gets every
                                                        // drag; without this
                                                        // the page scrolls.
                                                        gestureRecognizers: {
                                                          Factory<
                                                            OneSequenceGestureRecognizer
                                                          >(
                                                            EagerGestureRecognizer
                                                                .new,
                                                          ),
                                                        },
                                                        onScrollListener: (_) {
                                                          if (_followDriver) {
                                                            setState(
                                                              () =>
                                                                  _followDriver =
                                                                      false,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ),
                                            ),
                                            Positioned(
                                              left: 12,
                                              bottom: 12,
                                              right: 12,
                                              child: Row(
                                                children: [
                                                  Flexible(
                                                    child: _mapChip(
                                                      icon: Icons.place_rounded,
                                                      label: _areaLabel(
                                                        context,
                                                        lat,
                                                        AppSession
                                                            .userLongitude
                                                            .value,
                                                      ),
                                                      background: Colors.white,
                                                      foreground:
                                                          AppColors.textPrimary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              right: 12,
                                              top: 12,
                                              child:
                                                  const SharingLocationChip(),
                                            ),
                                            if (!_followDriver && !kIsWeb)
                                              Positioned(
                                                right: 12,
                                                top: 50,
                                                child: Material(
                                                  color: Colors.white,
                                                  shape: const CircleBorder(),
                                                  elevation: 3,
                                                  child: IconButton(
                                                    tooltip: context
                                                        .l10n
                                                        .centerOnMyLocation,
                                                    onPressed: _recenter,
                                                    icon: const Icon(
                                                      Icons.my_location_rounded,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.l10n.yourActivity,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder(
                        valueListenable: AppSession.bookings,
                        builder: (context, bookings, child) {
                          final earnings = AppSession.driverEarnings;
                          final trips = AppSession.driverTripsCompleted;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _stat(
                                  '₱${AppFormatters.amount(earnings)}',
                                  MessageCode.earnings,
                                  Icons.account_balance_wallet_outlined,
                                  AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                _stat(
                                  '$trips',
                                  MessageCode.completedTrips,
                                  Icons.route_outlined,
                                  AppColors.secondary,
                                ),
                                const SizedBox(width: 10),
                                _stat(
                                  isOnline
                                      ? MessageCode.online
                                      : MessageCode.offline,
                                  MessageCode.availability,
                                  Icons.timer_outlined,
                                  AppColors.success,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      Text(
                        context.l10n.driverTools,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tool(
                        context,
                        Icons.assignment_turned_in_outlined,
                        MessageCode.myBookings,
                        MessageCode.reviewActiveAndCompletedTrips,
                        '/driver/bookings',
                      ),
                      _tool(
                        context,
                        Icons.insights_outlined,
                        MessageCode.earningsInsights,
                        MessageCode.seeYourDailyTripSummary,
                        '/driver/earnings',
                      ),
                      if (isOnline) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const material.Size.fromHeight(52),
                          ),
                          onPressed: () => context.go('/driver/bookings'),
                          icon: const Icon(Icons.bolt_rounded),
                          label: Text(context.l10n.viewBookingRequests),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Where the driver really is: the town from reverse geocoding plus the
  /// distance to Bustos. The pickup area is a wide circle around Bustos, so
  /// "inside the area" alone said nothing about the driver's actual town.
  String _areaLabel(BuildContext context, double lat, double? lng) {
    final area = _serviceArea;
    final km = lng == null ? null : area.distanceKmTo(lat, lng);
    if (km == null) return context.l10n.locationUnavailable;
    final distance = km < 1
        ? context.l10n.driverNearBustosCentre
        : context.l10n.driverOutsideServiceArea(
            AppFormatters.integer(km.round()),
          );
    final parts = [
      ?_townName,
      distance,
      if (km > area.radiusKm) context.l10n.outsideThePickupArea,
    ];
    return parts.join('  ·  ');
  }

  Widget _mapChip({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(8, 5, 10, 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x290D1B2A),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: foreground),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: foreground,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stat(String value, String label, IconData icon, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFE6EDF2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: color),
              const Spacer(),
              const SizedBox(height: 10),
              Text(
                context.message(value),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.message(label),
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  height: 1.3,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
  Widget _locationPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    bool loading = false,
  }) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            loading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.message(title),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.message(subtitle),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _tool(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(title),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
