import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../models/booking_model.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/driver_availability_controller.dart';
import '../../../core/services/location_gateway.dart';

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
  late final DriverAvailabilityController _availabilityController;

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
      _checkLocationPermission();
    }
  }

  @override
  void dispose() {
    unawaited(_availabilityController.dispose());
    super.dispose();
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
    _updateCamera();
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
    _updateCamera();
  }

  void _updateCamera() {
    mapboxMap?.setCamera(
      CameraOptions(
        center: Point(
          coordinates: Position(
            AppSession.userLongitude.value ?? 120.91,
            AppSession.userLatitude.value ?? 14.95,
          ),
        ),
        zoom: 14.0,
      ),
    );
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
                                return Container(
                                  height:
                                      108 *
                                      MediaQuery.textScalerOf(context).scale(1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .10),
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
                                                      builder: (context) =>
                                                          MapWidget(
                                                            onMapCreated:
                                                                _onMapCreated,
                                                            styleUri: MapboxStyles
                                                                .MAPBOX_STREETS,
                                                          ),
                                                    ),
                                            ),
                                            if (!isOnline)
                                              Container(
                                                color: Colors.black.withValues(
                                                  alpha: 0.3,
                                                ),
                                              ),
                                            Positioned(
                                              left: 14,
                                              bottom: 12,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  context.l10n.bustosTownCentre,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isOnline)
                                              Positioned(
                                                right: 12,
                                                top: 12,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.success,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    context
                                                        .l10n
                                                        .sharingLocation,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                          return Row(
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
              const SizedBox(height: 12),
              Text(
                context.message(value),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                context.message(label),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
