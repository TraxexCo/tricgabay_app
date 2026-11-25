import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/route_geometry.dart';
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/map_route_service.dart';
import '../../../core/widgets/app_button.dart';

import '../../../core/session/app_session.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../models/booking_model.dart';
import 'booking_detail_screen.dart';

class DriverTrackingScreen extends StatefulWidget {
  final String bookingId;
  const DriverTrackingScreen({super.key, required this.bookingId});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  BookingModel? _booking;
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _annotationManager;
  PolylineAnnotationManager? _routeManager;
  PointAnnotation? _driverPin;
  bool _creatingDriverPin = false;
  Timer? _routeRefreshDebounce;
  Timer? _freshnessTimer;
  bool get _locationFresh {
    if (_driverLocation == null) return false;
    final updated = DateTime.tryParse(
      _assignedDriver?['locationUpdatedAt'] as String? ?? '',
    );
    return updated != null &&
        DateTime.now().difference(updated).inSeconds >= 0 &&
        DateTime.now().difference(updated).inSeconds < 60;
  }

  StreamSubscription<geo.Position>? _touristPositionSubscription;
  bool _routeLoading = false;
  bool _usingRouteFallback = false;
  bool _completionHandled = false;
  MapRoutePlan? _routePlan;
  final _routeRefreshPolicy = RouteRefreshPolicy();

  double _pickupLat = MapboxConfig.bustosLat;
  double _pickupLng = MapboxConfig.bustosLng;

  Map<String, dynamic>? get _assignedDriver {
    final driverId = _booking?.driverId;
    if (driverId == null) return null;
    return AppSession.adminDrivers.value
        .where((driver) => driver['id'] == driverId)
        .firstOrNull;
  }

  ({double lat, double lng})? get _driverLocation {
    final driver = _assignedDriver;
    final lat = (driver?['lat'] as num?)?.toDouble();
    final lng = (driver?['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : (lat: lat, lng: lng);
  }

  num get _driverSpeedMetersPerSecond => _assignedDriver?['speed'] as num? ?? 0;

  double? get _distanceToRelevantPoint {
    final driverLocation = _driverLocation;
    if (driverLocation == null) return null;
    final touristLat = AppSession.userLatitude.value;
    final touristLng = AppSession.userLongitude.value;
    final trackTourist =
        _booking?.status == BookingStatus.ongoing &&
        touristLat != null &&
        touristLng != null;
    return geo.Geolocator.distanceBetween(
      driverLocation.lat,
      driverLocation.lng,
      trackTourist ? touristLat : _pickupLat,
      trackTourist ? touristLng : _pickupLng,
    );
  }

  String get _distanceLabel {
    final distance = _distanceToRelevantPoint;
    if (distance == null) return MessageCode.unavailable;
    return distance < 1000
        ? MessageCode.distanceMeters((distance.round()).toString())
        : MessageCode.distanceKilometers(
            ((distance / 1000).toStringAsFixed(1)).toString(),
          );
  }

  int? get _locationAgeSeconds {
    final updated = DateTime.tryParse(
      _assignedDriver?['locationUpdatedAt'] as String? ?? '',
    );
    if (updated == null) return null;
    return DateTime.now().difference(updated).inSeconds.clamp(0, 9999);
  }

  String _movementTitle(bool isFilipino) {
    if (!_locationFresh) {
      return MessageCode.waitingForLiveLocation;
    }
    final distance = _distanceToRelevantPoint;
    if (distance != null && distance <= 50) {
      if (_booking?.status == BookingStatus.ongoing) {
        return MessageCode.youAreTogether;
      }
      return MessageCode.driverHasArrived;
    }
    if (_driverSpeedMetersPerSecond >= 0.8) {
      return MessageCode.driverIsMoving;
    }
    return MessageCode.driverIsStopped;
  }

  String _movementSubtitle(bool isFilipino) {
    if (!_locationFresh) {
      return _locationAgeSeconds == null
          ? MessageCode.unavailable
          : MessageCode.lastLocationIsMoreThanAMinuteOld;
    }
    final age = _locationAgeSeconds ?? 0;
    final target = _booking?.status == BookingStatus.ongoing
        ? MessageCode.fromYou
        : MessageCode.fromPickup;
    return MessageCode.trackingMovementSubtitle(_distanceLabel, target, age);
  }

  @override
  void initState() {
    super.initState();
    try {
      _booking = AppSession.bookings.value.firstWhere(
        (b) => b.id == widget.bookingId,
      );
    } catch (_) {
      _booking = null;
    }

    _pickupLat = _booking?.pickupLat ?? MapboxConfig.bustosLat;
    _pickupLng = _booking?.pickupLng ?? MapboxConfig.bustosLng;

    AppSession.adminDrivers.addListener(_syncDriverLocation);
    AppSession.bookings.addListener(_onBookingUpdated);
    _ensureLocationPermission();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    AppSession.adminDrivers.removeListener(_syncDriverLocation);
    AppSession.bookings.removeListener(_onBookingUpdated);
    _freshnessTimer?.cancel();
    _routeRefreshDebounce?.cancel();
    _touristPositionSubscription?.cancel();
    _annotationManager?.deleteAll();
    _routeManager?.deleteAll();
    super.dispose();
  }

  Future<void> _ensureLocationPermission() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) return;
    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission != geo.LocationPermission.always &&
        permission != geo.LocationPermission.whileInUse) {
      return;
    }
    await _touristPositionSubscription?.cancel();
    _touristPositionSubscription =
        geo.Geolocator.getPositionStream(
          locationSettings: const geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 8,
          ),
        ).listen((position) {
          AppSession.userLatitude.value = position.latitude;
          AppSession.userLongitude.value = position.longitude;
          if (mounted) setState(() {});
          _scheduleRouteRefresh();
        });
  }

  void _onBookingUpdated() {
    final updated = AppSession.bookings.value
        .where((booking) => booking.id == widget.bookingId)
        .firstOrNull;
    if (updated == null || !mounted) return;
    setState(() => _booking = updated);
    _scheduleRouteRefresh();
    if (!updated.isActive && !_completionHandled) {
      _completionHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/tourist/bookings/${widget.bookingId}');
        }
      });
    }
  }

  void _syncDriverLocation() {
    if (!mounted) return;
    setState(() {});
    _updateDriverPin();
    _scheduleRouteRefresh();
  }

  void _scheduleRouteRefresh() {
    if (_routeRefreshDebounce?.isActive ?? false) return;
    _routeRefreshDebounce = Timer(const Duration(seconds: 6), _drawDriverRoute);
  }

  Future<void> _updateDriverPin() async {
    final manager = _annotationManager;
    final location = _driverLocation;
    if (manager == null ||
        location == null ||
        !_locationFresh ||
        !mounted ||
        _creatingDriverPin) {
      return;
    }
    if (_driverPin == null) {
      _creatingDriverPin = true;
      try {
        final bitmap = await _buildPinBitmap(
          AppColors.primary,
          Icons.electric_rickshaw,
        );
        if (!mounted) return;
        _driverPin = await manager.create(
          PointAnnotationOptions(
            geometry: Point(coordinates: Position(location.lng, location.lat)),
            image: bitmap,
            iconSize: 1,
            iconAnchor: IconAnchor.BOTTOM,
          ),
        );
      } finally {
        _creatingDriverPin = false;
      }
    } else {
      _driverPin!.geometry = Point(
        coordinates: Position(location.lng, location.lat),
      );
      await manager.update(_driverPin!);
    }
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
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
    await mapboxMap.gestures.updateSettings(
      GesturesSettings(rotateEnabled: false, pitchEnabled: false),
    );

    _annotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _routeManager = await mapboxMap.annotations
        .createPolylineAnnotationManager();
    await _addPins();
    await _drawDriverRoute(fitCamera: true);
  }

  Future<void> _addPins() async {
    if (_annotationManager == null) return;

    final userBitmap = await _buildPinBitmap(
      AppColors.danger,
      Icons.location_on_rounded,
    );
    await _annotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_pickupLng, _pickupLat)),
        image: userBitmap,
        iconSize: 1.0,
        iconAnchor: IconAnchor.BOTTOM,
      ),
    );

    await _updateDriverPin();
  }

  Future<void> _drawDriverRoute({bool fitCamera = false}) async {
    final map = _mapboxMap;
    final manager = _routeManager;
    final location = _driverLocation;
    if (map == null ||
        manager == null ||
        location == null ||
        !_locationFresh ||
        _routeLoading) {
      return;
    }
    if (_booking?.interruptedAt != null) {
      await manager.deleteAll();
      if (mounted) setState(() => _routePlan = null);
      return;
    }
    if (mounted) setState(() => _routeLoading = true);

    final waypoints = [
      Position(location.lng, location.lat),
      if (_booking?.status == BookingStatus.ongoing)
        ..._booking!.stops
            .skip(_booking!.trip.confirmedStops)
            .map((s) => Position(s.longitude, s.latitude))
      else
        Position(_pickupLng, _pickupLat),
    ];
    if (waypoints.length < 2) {
      if (mounted) setState(() => _routeLoading = false);
      return;
    }
    if (!fitCamera && _routeRefreshPolicy.canReuse(waypoints)) {
      if (mounted) setState(() => _routeLoading = false);
      return;
    }
    late final MapRoutePlan plan;
    try {
      plan = await MapRouteService.tricyclePreferred(waypoints);
    } catch (error) {
      ErrorMessages.forError(error);
      if (mounted) {
        setState(() {
          _routeLoading = false;
          _usingRouteFallback = _routePlan == null;
        });
      }
      return;
    }

    if (!mounted) return;
    _routeRefreshPolicy.remember(waypoints, plan.geometry);
    await manager.deleteAll();
    await manager.create(
      PolylineAnnotationOptions(
        geometry: LineString(coordinates: plan.geometry),
        lineColor: AppColors.primary.toARGB32(),
        lineBorderColor: Colors.white.toARGB32(),
        lineBorderWidth: 2,
        lineWidth: 7,
        lineJoin: LineJoin.ROUND,
      ),
    );
    if (fitCamera) {
      final camera = await map.cameraForCoordinatesPadding(
        waypoints.map((position) => Point(coordinates: position)).toList(),
        CameraOptions(bearing: 0, pitch: 0),
        MbxEdgeInsets(top: 170, left: 42, bottom: 350, right: 42),
        16,
        null,
      );
      await map.setCamera(camera);
    }
    if (mounted) {
      setState(() {
        _routeLoading = false;
        _usingRouteFallback = plan.restrictionViolation;
        _routePlan = plan;
      });
    }
  }

  Future<Uint8List> _buildPinBitmap(Color color, IconData iconData) async {
    const double w = 60;
    const double h = 76;
    const double cx = w / 2;
    const double r = 24.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, w, h));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4.0);
    canvas.drawOval(Rect.fromLTWH(cx - 16, h - 12, 32, 12), shadowPaint);

    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, r), radius: r));
    final pointerPath = Path()
      ..moveTo(cx - 8, r + 16)
      ..quadraticBezierTo(cx, h - 2, cx + 8, r + 16)
      ..close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);
    canvas.drawPath(pointerPath, fill);

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, border);
    canvas.drawPath(pointerPath, border);

    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: context.message(String.fromCharCode(iconData.codePoint)),
      style: TextStyle(
        fontSize: 28,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(cx - (iconPainter.width / 2), r - (iconPainter.height / 2)),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.toInt(), h.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    if (_booking == null || !_booking!.isActive || _booking!.driverId == null) {
      return BookingDetailScreen(bookingId: widget.bookingId);
    }
    final driverName = _booking?.driverName ?? MessageCode.assignedDriver;
    final driverPlate =
        _booking?.driverPlate ?? _assignedDriver?['plate'] as String?;
    final phoneNumber = _assignedDriver?['phone'] as String? ?? '';
    final routePlan = _routePlan;

    final centerLat = _booking?.pickupLat ?? MapboxConfig.bustosLat;
    final centerLng = _booking?.pickupLng ?? MapboxConfig.bustosLng;

    return ValueListenableBuilder<bool>(
      valueListenable: AppSession.isFilipino,
      builder: (context, isFilipino, _) => Scaffold(
        body: Stack(
          children: [
            kIsWeb
                ? WebMapFallback(
                    title: context.l10n.driverTrackingPreview,
                    subtitle: context
                        .l10n
                        .liveMapboxTrackingIsAvailableInTheMobileApp,
                  )
                : MapSurface(
                    builder: (context) => MapWidget(
                      styleUri: MapboxConfig.mapStyle,
                      onMapCreated: _onMapCreated,
                      viewport: CameraViewportState(
                        center: Point(
                          coordinates: Position(centerLng, centerLat),
                        ),
                        zoom: 14.0,
                      ),
                    ),
                  ),

            // Live route status
            Positioned(
              top: MediaQuery.paddingOf(context).top + 104,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
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
                      const Icon(
                        Icons.route_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      context.message(
                        _routeLoading
                            ? MessageCode.updatingRoute
                            : _usingRouteFallback
                            ? MessageCode.checkRoadRestrictions
                            : _routePlan != null
                            ? MessageCode.minValue(
                                (_routePlan!.distanceLabel).toString(),
                                (_routePlan!.etaMinutes).toString(),
                              )
                            : _locationFresh
                            ? MessageCode.preparingDriverRoute
                            : MessageCode.locationUnavailable,
                      ),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_booking?.interruptedAt != null)
              Positioned(
                top: 160,
                left: 16,
                right: 16,
                child: Material(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      context.l10n
                          .tripPausedOpenTripControlsToChooseWhetherToWaitOrEndSafelyValue(
                            context.message(
                              (_booking?.interruptionReason ??
                                      MessageCode.vehicleProblem)
                                  .toString(),
                            ),
                          ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              )
            else if (_booking?.lastRouteDeviationAt != null &&
                DateTime.now()
                        .difference(_booking!.lastRouteDeviationAt!)
                        .inMinutes <
                    10)
              Positioned(
                top: 160,
                left: 16,
                right: 16,
                child: Material(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      context
                          .l10n
                          .theDriverMovedAwayFromThePlannedRouteAndNavigationWasRecalculatedLive,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (_locationFresh
                                        ? AppColors.success
                                        : AppColors.textSecondary)
                                    .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _driverSpeedMetersPerSecond >= 0.8
                                ? Icons.electric_rickshaw_rounded
                                : Icons.location_searching_rounded,
                            color: _locationFresh
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.message(_movementTitle(isFilipino)),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.message(_movementSubtitle(isFilipino)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 300,
              child: FloatingActionButton.small(
                heroTag: 'tourist_tracking_recenter',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                onPressed: _locationFresh
                    ? () => _drawDriverRoute(fitCamera: true)
                    : null,
                child: const Icon(Icons.center_focus_strong_rounded),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.message(driverName),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (driverPlate != null &&
                                        driverPlate.isNotEmpty)
                                      Text(
                                        driverPlate,
                                        style: GoogleFonts.poppins(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: context.l10n.call,
                                icon: const Icon(
                                  Icons.phone,
                                  color: AppColors.primary,
                                ),
                                onPressed: phoneNumber.toString().isEmpty
                                    ? null
                                    : () async {
                                        final uri = Uri(
                                          scheme: 'tel',
                                          path: phoneNumber,
                                        );
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  context
                                                      .l10n
                                                      .couldNotOpenPhoneDialer,
                                                ),
                                              ),
                                            );
                                          }
                                        }
                                      },
                              ),
                              IconButton(
                                tooltip: context.l10n.sendMessage,
                                icon: const Icon(
                                  Icons.message,
                                  color: AppColors.primary,
                                ),
                                onPressed: phoneNumber.toString().isEmpty
                                    ? null
                                    : () async {
                                        final uri = Uri(
                                          scheme: 'sms',
                                          path: phoneNumber,
                                        );
                                        if (!await launchUrl(uri) &&
                                            context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                context
                                                    .l10n
                                                    .couldNotOpenMessages,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  context.l10n.eta,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  context.message(
                                    !_locationFresh
                                        ? MessageCode.unavailable
                                        : routePlan == null
                                        ? _distanceLabel
                                        : MessageCode.minValueLabel(
                                            routePlan.etaMinutes.toString(),
                                            routePlan.distanceLabel,
                                          ),
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: context.l10n.emergency,
                                  type: AppButtonType.outline,
                                  onPressed: () =>
                                      context.push('/tourist/emergency'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: AppButton(
                                  label: context.l10n.tripPayment,
                                  type: AppButtonType.primary,
                                  onPressed: () => context.push(
                                    '/tourist/bookings/${widget.bookingId}',
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
            ),
          ],
        ),
      ),
    );
  }
}
