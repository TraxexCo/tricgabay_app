import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/core/widgets/map_surface.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/services/backend_repository.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/session/app_session.dart';
import '../../../core/widgets/web_map_fallback.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapboxMap? _mapboxMap;
  final _streetCtrl = TextEditingController();
  String _selectedBarangay = 'Poblacion';
  bool _hasSelectedPin = false;

  final List<String> _barangays = [
    MessageCode.bongaMayor,
    MessageCode.bongaMenor,
    'Buisan',
    'Camachilihan',
    'Cambaog',
    'Catacte',
    'Liciada',
    'Malamig',
    'Malawak',
    'Poblacion',
    MessageCode.sanPedro,
    'Talampas',
    'Tanawan',
    'Tibagan',
  ];

  @override
  void initState() {
    super.initState();
    final parts = (AppSession.draft.pickupAddress.value ?? '').split(',');
    _hasSelectedPin =
        AppSession.draft.pickupLat != null &&
        AppSession.draft.pickupLng != null;
    if (parts.isNotEmpty &&
        parts[0].isNotEmpty &&
        parts[0] != MessageCode.currentLocation) {
      _streetCtrl.text = parts[0].trim();
    }
  }

  @override
  void dispose() {
    _streetCtrl.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    final lat =
        AppSession.draft.pickupLat ?? AppSession.userLatitude.value ?? 14.9520;
    final lng =
        AppSession.draft.pickupLng ??
        AppSession.userLongitude.value ??
        120.9180;

    await mapboxMap.compass.updateSettings(CompassSettings(enabled: false));
    await mapboxMap.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        puckBearingEnabled: true,
      ),
    );
    await mapboxMap.setCamera(
      CameraOptions(center: Point(coordinates: Position(lng, lat)), zoom: 15.0),
    );
  }

  Future<void> _goToCurrentLocation() async {
    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.turnOnLocationServicesToUseYourCurrentPosition,
            ),
          ),
        );
      }
      return;
    }

    var permission = await geo.Geolocator.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == geo.LocationPermission.denied ||
        permission == geo.LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.locationPermissionIsNeededToUseYourCurrentPosition,
            ),
          ),
        );
      }
      return;
    }

    final position = await geo.Geolocator.getCurrentPosition(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
      ),
    );
    AppSession.userLatitude.value = position.latitude;
    AppSession.userLongitude.value = position.longitude;
    if (mounted) setState(() => _hasSelectedPin = true);
    if (!mounted) return;
    await _mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(position.longitude, position.latitude),
        ),
        zoom: 16,
      ),
      MapAnimationOptions(
        duration: MediaQuery.disableAnimationsOf(context) ? 0 : 700,
      ),
    );
  }

  void _onSaveLocation() async {
    try {
      if (_mapboxMap == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context
                  .l10n
                  .waitForTheMobileMapToLoadBeforeConfirmingAnExactPickupPin,
            ),
          ),
        );
        return;
      }
      if (_streetCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pleaseEnterYourStreetOrHouseNumber),
          ),
        );
        return;
      }
      if (!_hasSelectedPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.moveTheMapPinOrUseYourCurrentLocationBeforeSaving,
            ),
          ),
        );
        return;
      }

      double lat = 14.9520;
      double lng = 120.9180;

      if (_mapboxMap != null) {
        final cameraState = await _mapboxMap!.getCameraState();
        final point = cameraState.center;
        lng = point.coordinates.lng.toDouble();
        lat = point.coordinates.lat.toDouble();
      }

      final area = await BackendRepository.loadPickupServiceArea();
      if (!area.contains(lat, lng)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context
                    .l10n
                    .thisPickupPinIsOutsideTheServiceAreaMoveThePinCloserTo,
              ),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.confirmThePickupPin),
          content: Text(
            context
                .l10n
                .theDriverWillFollowTheSelectedPinConfirmThatItMatchesTheAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.adjustPin),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.addressMatchesPin),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      final fullAddress =
          '${_streetCtrl.text.trim()}, $_selectedBarangay, Bustos, Bulacan';

      AppSession.draft.pickupAddress.value = fullAddress;
      AppSession.draft.pickupLat = lat;
      AppSession.draft.pickupLng = lng;

      if (mounted) {
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.selectAddress,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 40% Map area
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                if (kIsWeb)
                  WebMapFallback(
                    title: context.l10n.pickupLocationPreview,
                    subtitle: context.l10n.enterThePickupAddressBelow,
                  )
                else
                  MapSurface(
                    builder: (context) => MapWidget(
                      key: const ValueKey('locationPickerMap'),
                      onMapCreated: _onMapCreated,
                      onScrollListener: (scrollEventData) {
                        if (!_hasSelectedPin) {
                          setState(() => _hasSelectedPin = true);
                        }
                      },
                    ),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.location_on,
                      size: 50,
                      color: AppColors.primary,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.message(
                              kIsWeb
                                  ? MessageCode
                                        .chooseABarangayAndEnterTheExactAddressBelow
                                  : MessageCode
                                        .dragTheMapToPinYourExactLocation,
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!kIsWeb)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'pickupCurrentLocation',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      tooltip: MessageCode.useMyCurrentLocation,
                      onPressed: _goToCurrentLocation,
                      child: const Icon(Icons.my_location_rounded),
                    ),
                  ),
              ],
            ),
          ),

          // 60% Form area
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.addressDetails,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLockedDropdown(
                            MessageCode.province,
                            'Bulacan',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildLockedDropdown(
                            MessageCode.municipality,
                            'Bustos',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.barangay,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBarangay,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                          ),
                          items: _barangays
                              .map(
                                (b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(
                                    context.message(b),
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedBarangay = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.streetNameBuildingHouseNo,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      controller: _streetCtrl,
                      label: context.l10n.streetHouseNo,
                      hint: context.l10n.eG123RizalStNearTheBakery,
                    ),
                    const SizedBox(height: 32),
                    AppButton(
                      label: context.l10n.confirmLocation,
                      onPressed: _onSaveLocation,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedDropdown(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.message(label),
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.message(value),
            style: GoogleFonts.poppins(color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}
