import 'package:tricgabay_app/core/widgets/map_surface.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/web_map_fallback.dart';
import '../../../core/utils/map_coordinate_validator.dart';

class AdminLiveMapScreen extends StatefulWidget {
  const AdminLiveMapScreen({super.key});

  @override
  State<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends State<AdminLiveMapScreen> {
  PointAnnotationManager? _pointAnnotationManager;
  Uint8List? _pinImage;

  @override
  void initState() {
    super.initState();
    _initPinImage();
    AppSession.adminDrivers.addListener(_updateMarkers);
  }

  Future<void> _initPinImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // Draw a simple pin
    canvas.drawCircle(const Offset(50, 40), 30, paint);

    final path = Path()
      ..moveTo(25, 55)
      ..lineTo(75, 55)
      ..lineTo(50, 95)
      ..close();
    canvas.drawPath(path, paint);

    // Inner circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(50, 40), 12, whitePaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(100, 100);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (mounted && byteData != null) {
      setState(() {
        _pinImage = byteData.buffer.asUint8List();
      });
      if (_pointAnnotationManager != null) {
        _updateMarkers();
      }
    }
  }

  @override
  void dispose() {
    AppSession.adminDrivers.removeListener(_updateMarkers);
    super.dispose();
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _pointAnnotationManager = await mapboxMap.annotations
        .createPointAnnotationManager();
    _updateMarkers();
  }

  void _updateMarkers() async {
    if (_pointAnnotationManager == null || _pinImage == null) return;

    final drivers = AppSession.adminDrivers.value;
    final activeDrivers = drivers
        .where((d) => d['status'] == 'active')
        .toList();

    await _pointAnnotationManager!.deleteAll();

    if (activeDrivers.isEmpty) return;

    List<PointAnnotationOptions> options = [];
    for (var driver in activeDrivers) {
      if (!MapCoordinateValidator.isValid(
        latitude: driver['lat'],
        longitude: driver['lng'],
      )) {
        continue;
      }
      final lat = MapCoordinateValidator.finiteNumber(driver['lat'])!;
      final lng = MapCoordinateValidator.finiteNumber(driver['lng'])!;

      options.add(
        PointAnnotationOptions(
          geometry: Point(coordinates: Position(lng, lat)),
          image: _pinImage,
          iconSize: 0.6,
          textField: driver['name'] as String?,
          textColor: 0xFF000000,
          textHaloColor: 0xFFFFFFFF,
          textHaloWidth: 2.0,
          textOffset: [0.0, 1.5],
        ),
      );
    }
    await _pointAnnotationManager!.createMulti(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const RemotePageControls(directory: true),
      appBar: AppBar(
        title: Text(
          context.l10n.liveDriverTracking,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        centerTitle: true,
      ),
      body: kIsWeb
          ? WebMapFallback(
              title: context.l10n.liveDriverTracking,
              subtitle: context
                  .l10n
                  .theInteractiveOperationsMapIsAvailableInTheMobileApp,
            )
          : MapSurface(
              builder: (context) => MapWidget(
                onMapCreated: _onMapCreated,
                viewport: CameraViewportState(
                  center: Point(coordinates: Position(120.9200, 14.9500)),
                  zoom: 13.0,
                ),
              ),
            ),
    );
  }
}
