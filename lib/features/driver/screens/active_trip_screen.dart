import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../models/trip_record.dart';
import '../../tourist/screens/booking_detail_screen.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/services/map_route_service.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const ActiveTripScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  MapboxMap? _mapboxMap;
  PolylineAnnotationManager? _routeManager;
  bool _routeLoading = false;
  bool _routeReady = false;
  bool _usingRouteFallback = false;
  MapRoutePlan? _routePlan;
  DateTime? _deviationSince;
  DateTime? _lastDeviationReport;
  bool _offRoute = false;
  StreamSubscription<geo.Position>? _driverPositionSubscription;
  Timer? _routeRefreshTimer;

  geo.LocationSettings get _liveTripLocationSettings {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationTitle: 'Tric-Gabay live trip',
          notificationText: 'Sharing your location with the assigned tourist',
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
    PrototypeSession.bookings.addListener(_bookingChanged);
    _startDriverLocationTracking();
  }

  void _bookingChanged() {
    final booking = PrototypeSession.bookings.value
        .where((b) => b.id == widget.bookingId)
        .firstOrNull;
    if (booking == null || !booking.isActive) {
      _driverPositionSubscription?.cancel();
      _routeRefreshTimer?.cancel();
      return;
    }
    if (mounted) _drawRoute(booking);
  }

  @override
  void dispose() {
    PrototypeSession.bookings.removeListener(_bookingChanged);
    _driverPositionSubscription?.cancel();
    _routeRefreshTimer?.cancel();
    _routeManager?.deleteAll();
    super.dispose();
  }

  Future<void> _startDriverLocationTracking() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) return;
    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission != geo.LocationPermission.always &&
        permission != geo.LocationPermission.whileInUse) {
      return;
    }
    await _driverPositionSubscription?.cancel();
    _driverPositionSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: _liveTripLocationSettings,
        ).listen((position) {
          PrototypeSession.userLatitude.value = position.latitude;
          PrototypeSession.userLongitude.value = position.longitude;
          _checkRouteDeviation(position);
          if (BackendConfig.isConfigured) {
            unawaited(
              BackendRepository.publishLocation(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                heading: position.heading,
                speed: position.speed,
                recordedAt: position.timestamp,
              ).catchError((Object _) {
                // Realtime/GPS updates continue; a later position retries.
              }),
            );
          }
          final driverName = PrototypeSession.currentDriverName.value;
          PrototypeSession.adminDrivers.value = PrototypeSession
              .adminDrivers
              .value
              .map(
                (driver) => driver['name'] == driverName
                    ? {
                        ...driver,
                        'lat': position.latitude,
                        'lng': position.longitude,
                        'locationUpdatedAt': DateTime.now().toIso8601String(),
                        'heading': position.heading,
                        'speed': position.speed,
                      }
                    : driver,
              )
              .toList();
          if (_routeRefreshTimer?.isActive ?? false) return;
          _routeRefreshTimer = Timer(const Duration(seconds: 6), () {
            final booking = PrototypeSession.bookings.value
                .where((item) => item.id == widget.bookingId)
                .firstOrNull;
            if (booking != null) _drawRoute(booking);
          });
        });
  }

  void _checkRouteDeviation(geo.Position position) {
    final booking = PrototypeSession.bookings.value
        .where((item) => item.id == widget.bookingId)
        .firstOrNull;
    final geometry = _routePlan?.geometry;
    if (booking?.status != BookingStatus.ongoing ||
        booking?.interruptedAt != null ||
        geometry == null ||
        geometry.isEmpty) {
      _deviationSince = null;
      if (_offRoute && mounted) setState(() => _offRoute = false);
      return;
    }
    var nearest = double.infinity;
    for (var i = 0; i < geometry.length; i += 3) {
      final point = geometry[i];
      final distance = geo.Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.lat.toDouble(),
        point.lng.toDouble(),
      );
      if (distance < nearest) nearest = distance;
    }
    if (nearest <= 150) {
      _deviationSince = null;
      if (_offRoute && mounted) setState(() => _offRoute = false);
      return;
    }
    _deviationSince ??= DateTime.now();
    if (DateTime.now().difference(_deviationSince!).inSeconds < 30) return;
    if (!_offRoute && mounted) setState(() => _offRoute = true);
    final mayReport = _lastDeviationReport == null ||
        DateTime.now().difference(_lastDeviationReport!).inMinutes >= 5;
    if (mayReport) {
      _lastDeviationReport = DateTime.now();
      unawaited(
        PrototypeSession.reportRouteDeviation(booking!.id, nearest).catchError(
          (Object _) {},
        ),
      );
    }
  }

  List<Position> _waypointsFor(BookingModel booking) {
    final points = <Position>[];
    final currentLat = PrototypeSession.userLatitude.value;
    final currentLng = PrototypeSession.userLongitude.value;
    if (currentLat != null && currentLng != null) {
      points.add(Position(currentLng, currentLat));
    } else {
      return points;
    }

    if (booking.status == BookingStatus.accepted) {
      points.add(Position(booking.pickupLng, booking.pickupLat));
    } else if (booking.stops.isNotEmpty) {
      points.addAll(
        booking.stops
            .skip(booking.trip.confirmedStops)
            .map((stop) => Position(stop.longitude, stop.latitude)),
      );
    } else {
      points.add(Position(booking.pickupLng, booking.pickupLat));
    }
    return points;
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap, BookingModel booking) async {
    _mapboxMap = mapboxMap;
    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );
    _routeManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _drawRoute(booking, fitCamera: true);
  }

  Future<void> _drawRoute(
    BookingModel booking, {
    bool fitCamera = false,
  }) async {
    final map = _mapboxMap;
    final manager = _routeManager;
    if (map == null || manager == null || _routeLoading || !mounted) return;

    if (mounted) {
      setState(() {
        _routeLoading = true;
        _routeReady = false;
        _usingRouteFallback = false;
        _routePlan = null;
      });
    }

    final waypoints = _waypointsFor(booking);
    if (waypoints.length < 2) {
      await manager.deleteAll();
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _routeReady = false;
        });
      }
      return;
    }
    late final MapRoutePlan plan;
    try {
      plan = await MapRouteService.tricyclePreferred(waypoints);
    } catch (error) {
      await manager.deleteAll();
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _routeReady = false;
          _usingRouteFallback = false;
          _routePlan = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Road route unavailable: $error')),
        );
      }
      return;
    }

    if (!mounted) return;

    await manager.deleteAll();
    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: plan.geometry),
        lineColor: AppColors.primary.toARGB32(),
        lineBorderColor: Colors.white.toARGB32(),
        lineBorderWidth: 2.0,
        lineWidth: 7.0,
        lineJoin: LineJoin.ROUND,
      ),
    );

    if (fitCamera) {
      final camera = await map.cameraForCoordinatesPadding(
        waypoints.map((position) => Point(coordinates: position)).toList(),
        CameraOptions(bearing: 0, pitch: 0),
        MbxEdgeInsets(top: 130, left: 48, bottom: 430, right: 48),
        16.0,
        null,
      );
      await map.setCamera(camera);
    }

    if (mounted) {
      setState(() {
        _routeLoading = false;
        _routeReady = true;
        _usingRouteFallback = plan.restrictionViolation;
        _routePlan = plan;
      });
    }
  }

  Future<void> _openNavigation(BookingModel booking) async {
    final nextStop = booking.stops
        .skip(booking.trip.confirmedStops)
        .firstOrNull;
    if (booking.status == BookingStatus.ongoing && nextStop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All stops are confirmed. Open Trip controls to finish.',
          ),
        ),
      );
      return;
    }
    final destinationLat = booking.status == BookingStatus.accepted
        ? booking.pickupLat
        : (nextStop?.latitude ?? booking.pickupLat);
    final destinationLng = booking.status == BookingStatus.accepted
        ? booking.pickupLng
        : (nextStop?.longitude ?? booking.pickupLng);
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$destinationLat,$destinationLng',
      'travelmode': 'driving',
      'avoid': 'highways,tolls',
      'dir_action': 'navigate',
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open navigation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<BookingModel>>(
      valueListenable: PrototypeSession.bookings,
      builder: (context, bookings, _) {
        final booking = bookings
            .where((b) => b.id == widget.bookingId)
            .firstOrNull;

        if (booking == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Active Trip')),
            body: const EmptyStateWidget(
              title: 'No Active Trip',
              subtitle: 'This trip could not be found or has been removed.',
              icon: Icons.error_outline,
            ),
          );
        }

        if (!PrototypeSession.ownsDriverBooking(booking) || !booking.isActive) {
          return BookingDetailScreen(
            bookingId: booking.id,
            viewer: TripActor.driver,
          );
        }
        final isAccepted = booking.status == BookingStatus.accepted;

        return Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: kIsWeb
                    ? const WebMapFallback(
                        title: 'Active trip route',
                        subtitle:
                            'Turn-by-turn mapping is available in the mobile app.',
                      )
                    : MapWidget(
                        styleUri: MapboxConfig.mapStyle,
                        onMapCreated: (mapboxMap) {
                          _onMapCreated(mapboxMap, booking);
                        },
                        viewport: CameraViewportState(
                          center: Point(
                            coordinates: Position(
                              booking.pickupLng,
                              booking.pickupLat,
                            ),
                          ),
                          zoom: 15.0,
                          pitch: 0.0,
                          bearing: 0.0,
                        ),
                      ),
              ),
              Positioned(
                top: 92,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      if (_routeLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          _routeReady
                              ? Icons.route_rounded
                              : Icons.route_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        _routeLoading
                            ? 'Calculating local-road route...'
                            : _usingRouteFallback
                            ? 'Check road restrictions'
                            : _routeReady
                            ? '${_routePlan!.distanceLabel} | ${_routePlan!.etaMinutes} min'
                            : 'Preparing route...',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_offRoute)
                Positioned(
                  top: 142,
                  left: 16,
                  right: 16,
                  child: Material(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Off the planned route · navigation is recalculating. Follow legal local roads and stop safely if unsure.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isAccepted
                            ? AppColors.secondary
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        isAccepted ? 'Heading to Pickup' : 'Trip Ongoing',
                        style: GoogleFonts.poppins(
                          color: isAccepted
                              ? AppColors.textOnSecondary
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 100,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'driver_emergency',
                  backgroundColor: AppColors.danger,
                  mini: true,
                  onPressed: () => context.push('/driver/emergency'),
                  child: const Icon(Icons.emergency, color: Colors.white),
                ),
              ),
              Positioned(
                top: 158,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'driver_recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  onPressed: () => _drawRoute(booking, fitCamera: true),
                  child: const Icon(Icons.center_focus_strong_rounded),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  booking.touristName.isNotEmpty
                                      ? booking.touristName[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.touristName,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'Tourist',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.phone,
                                  color: AppColors.success,
                                ),
                                onPressed: () async {
                                  final phone =
                                      PrototypeSession.adminTourists.value
                                              .where(
                                                (u) =>
                                                    u['id'] ==
                                                    booking.touristId,
                                              )
                                              .firstOrNull?['phoneNumber']
                                          as String?;
                                  if (phone == null || phone.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No verified contact number is available for this tourist.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  final uri = Uri(scheme: 'tel', path: phone);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Could not launch phone dialer',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.danger,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Heading to',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      isAccepted
                                          ? booking.pickupAddress
                                          : (booking.stops.isNotEmpty
                                                ? booking
                                                      .stops[booking
                                                          .trip
                                                          .confirmedStops
                                                          .clamp(
                                                            0,
                                                            booking
                                                                    .stops
                                                                    .length -
                                                                1,
                                                          )]
                                                      .spotName
                                                : 'Destination'),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Bustos, Bulacan',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_routePlan != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.07,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.alt_route_rounded,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_routePlan!.distanceLabel} | ${_routePlan!.etaMinutes} min',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _routePlan!.nextInstruction ??
                                              'Local roads are preferred. Follow road signs and your approved TODA or LGU route.',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Fare',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '₱ ${booking.totalFare.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: AppButton(
                                  label: 'Navigate',
                                  onPressed: booking.interruptedAt == null
                                      ? () => _openNavigation(booking)
                                      : null,
                                  type: AppButtonType.outline,
                                  prefixIcon: Icons.navigation,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: AppButton(
                                  label: isAccepted
                                      ? 'Verify pickup'
                                      : 'Trip controls',
                                  prefixIcon: Icons.fact_check_outlined,
                                  onPressed: () => context.push(
                                    '/driver/bookings/${booking.id}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
