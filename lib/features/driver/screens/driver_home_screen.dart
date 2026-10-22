import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../models/booking_model.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});
  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  MapboxMap? mapboxMap;
  bool _isLocating = false;
  String? _locationMessage;
  StreamSubscription<geo.Position>? _locationSubscription;

  geo.LocationSettings get _onlineLocationSettings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationTitle: 'Tric-Gabay driver is online',
          notificationText: 'Live location is active for trip matching',
          enableWakeLock: true,
        ),
      );
    }
    return const geo.LocationSettings(
      accuracy: geo.LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );
  }

  @override
  void initState() {
    super.initState();
    if (PrototypeSession.isDriverOnline.value) {
      _checkLocationPermission();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  bool get _hasActiveTrip {
    final activeId = PrototypeSession.activeDriverBookingId;
    if (activeId == null) return false;
    return PrototypeSession.bookings.value.any(
      (booking) =>
          booking.id == activeId &&
          (booking.status == BookingStatus.accepted ||
              booking.status == BookingStatus.ongoing),
    );
  }

  Future<void> _checkLocationPermission() async {
    if (_isLocating) return;
    setState(() {
      _isLocating = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationMessage = 'Turn on GPS to share your location.';
        return;
      }

      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.deniedForever) {
        _locationMessage = 'Allow location access in Android settings.';
        return;
      }
      if (permission == geo.LocationPermission.denied) {
        _locationMessage = 'Location permission is needed to receive rides.';
        return;
      }

      final position = await geo.Geolocator.getCurrentPosition(
        locationSettings: const geo.LocationSettings(
          accuracy: geo.LocationAccuracy.high,
        ),
      );
      PrototypeSession.userLatitude.value = position.latitude;
      PrototypeSession.userLongitude.value = position.longitude;
      _publishDriverLocation(position);
      _startDriverLocationStream();
      _updateCamera();
    } catch (_) {
      _locationMessage = 'Could not find your location. Tap to try again.';
    } finally {
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _startDriverLocationStream() {
    _locationSubscription?.cancel();
    _locationSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: _onlineLocationSettings,
        ).listen((position) {
          PrototypeSession.userLatitude.value = position.latitude;
          PrototypeSession.userLongitude.value = position.longitude;
          _publishDriverLocation(position);
        });
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
        );
        if (mounted &&
            _locationMessage ==
                'Live location is reconnecting. Keep the app open.') {
          setState(() => _locationMessage = null);
        }
      } catch (_) {
        if (mounted &&
            _locationMessage !=
                'Live location is reconnecting. Keep the app open.') {
          setState(
            () => _locationMessage =
                'Live location is reconnecting. Keep the app open.',
          );
        }
      }
    }
    final driverName = PrototypeSession.currentDriverName.value;
    PrototypeSession.adminDrivers.value = PrototypeSession.adminDrivers.value
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
            PrototypeSession.userLongitude.value ?? 120.91,
            PrototypeSession.userLatitude.value ?? 14.95,
          ),
        ),
        zoom: 14.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
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
                          valueListenable: PrototypeSession.currentDriverName,
                          builder: (context, driverName, _) {
                            return Text(
                              'Good morning, $driverName',
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
                            Text(
                              'Verified Tric-Gabay driver',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.push('/driver/notifications'),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                  IconButton(
                    onPressed: () => context.push('/driver/emergency'),
                    icon: const Icon(
                      Icons.sos_outlined,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ValueListenableBuilder<bool>(
                valueListenable: PrototypeSession.isDriverOnline,
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
                                        isOnline
                                            ? 'You’re ready to ride'
                                            : 'You’re offline',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 21,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        isOnline
                                            ? 'We’ll send nearby bookings your way.'
                                            : 'Go online to start receiving booking requests.',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: isOnline,
                                  activeTrackColor: AppColors.success,
                                  onChanged: (value) async {
                                    if (!value && _hasActiveTrip) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Finish or cancel the active trip before going offline.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    try {
                                      if (BackendConfig.isConfigured) {
                                        await BackendRepository.setDriverOnline(
                                          value,
                                        );
                                      }
                                      PrototypeSession.isDriverOnline.value =
                                          value;
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('$error')),
                                        );
                                      }
                                      return;
                                    }
                                    if (value &&
                                        PrototypeSession.userLatitude.value ==
                                            null) {
                                      _checkLocationPermission();
                                    } else if (value) {
                                      _startDriverLocationStream();
                                    } else {
                                      _locationSubscription?.cancel();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ValueListenableBuilder<double?>(
                              valueListenable: PrototypeSession.userLatitude,
                              builder: (context, lat, _) {
                                return Container(
                                  height: 108,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .10),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: !isOnline
                                      ? _locationPlaceholder(
                                          icon: Icons.location_off_outlined,
                                          title: 'Location sharing is off',
                                          subtitle:
                                              'Go online to activate the driver map.',
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
                                                ? 'Finding your location…'
                                                : 'Location unavailable',
                                            subtitle:
                                                _locationMessage ??
                                                'Checking GPS and permission.',
                                            loading: _isLocating,
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            Positioned.fill(
                                              child: kIsWeb
                                                  ? const WebMapFallback(
                                                      title:
                                                          'Bustos town centre',
                                                      compact: true,
                                                    )
                                                  : MapWidget(
                                                      onMapCreated:
                                                          _onMapCreated,
                                                      styleUri: MapboxStyles
                                                          .MAPBOX_STREETS,
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
                                                  'Bustos town centre',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11,
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
                                                    'SHARING LOCATION',
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
                        'Your activity',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ValueListenableBuilder(
                        valueListenable: PrototypeSession.bookings,
                        builder: (context, bookings, child) {
                          final earnings = PrototypeSession.driverEarnings;
                          final trips = PrototypeSession.driverTripsCompleted;
                          return Row(
                            children: [
                              _stat(
                                '₱${earnings.toStringAsFixed(2)}',
                                'Earnings',
                                Icons.account_balance_wallet_outlined,
                                AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              _stat(
                                '$trips',
                                'Completed trips',
                                Icons.route_outlined,
                                AppColors.secondary,
                              ),
                              const SizedBox(width: 10),
                              _stat(
                                isOnline ? 'Online' : 'Offline',
                                'Availability',
                                Icons.timer_outlined,
                                AppColors.success,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 25),
                      Text(
                        'Driver tools',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _tool(
                        context,
                        Icons.assignment_turned_in_outlined,
                        'My bookings',
                        'Review active and completed trips',
                        '/driver/bookings',
                      ),
                      _tool(
                        context,
                        Icons.insights_outlined,
                        'Earnings insights',
                        'See your daily trip summary',
                        '/driver/earnings',
                      ),
                      if (isOnline) ...[
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => context.push('/driver/bookings'),
                          icon: const Icon(Icons.bolt_rounded),
                          label: const Text('View booking requests'),
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
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9,
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
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
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
