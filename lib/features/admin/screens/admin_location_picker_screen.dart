import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/config/mapbox_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/place_search_service.dart';
import '../../../core/widgets/map_surface.dart';
import '../../../core/widgets/web_map_fallback.dart';

/// Pick a place like in a maps app: search by name, or drag the map until
/// the pin sits on the spot. Returns a [PlaceHit] with the coordinates and
/// the address found there.
class AdminLocationPickerScreen extends StatefulWidget {
  const AdminLocationPickerScreen({super.key, this.latitude, this.longitude});

  final double? latitude;
  final double? longitude;

  @override
  State<AdminLocationPickerScreen> createState() =>
      _AdminLocationPickerScreenState();
}

class _AdminLocationPickerScreenState extends State<AdminLocationPickerScreen> {
  MapboxMap? _map;
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce, _addressDebounce;
  List<PlaceHit> _results = const [];
  bool _searching = false;
  String? _searchError;

  late double _lat = widget.latitude ?? MapboxConfig.bustosLat;
  late double _lng = widget.longitude ?? MapboxConfig.bustosLng;

  /// Where the map opens. Fixed for the life of the screen: building the map
  /// from [_lat]/[_lng] let the map's first (default) camera report drag the
  /// view to the middle of the USA.
  late final double _startLat = _lat, _startLng = _lng;
  late final double _startZoom = widget.latitude == null ? 14 : 17.5;

  /// False until the map has been moved to the start position; camera
  /// reports before that are the SDK's default view and must be ignored.
  bool _mapReady = false;
  String? _address;
  String? _pickedName;
  bool _loadingAddress = false;

  @override
  void initState() {
    super.initState();
    _lookUpAddress();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressDebounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _searching = true);
      try {
        final hits = await PlaceSearchService.search(value);
        if (!mounted || _search.text != value) return;
        setState(() {
          _results = hits;
          _searchError = hits.isEmpty ? context.l10n.pickerNoResults : null;
        });
      } catch (_) {
        if (mounted) {
          setState(() => _searchError = context.l10n.pickerSearchFailed);
        }
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _choose(PlaceHit hit) async {
    _searchFocus.unfocus();
    setState(() {
      _results = const [];
      _lat = hit.latitude;
      _lng = hit.longitude;
      _pickedName = hit.name;
      _address = hit.address.isEmpty ? null : hit.address;
    });
    await _map?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(hit.longitude, hit.latitude)),
        zoom: 17.5,
      ),
      MapAnimationOptions(duration: 600),
    );
  }

  void _onCameraChanged(CameraChangedEventData event) {
    if (!_mapReady) return;
    final center = event.cameraState.center.coordinates;
    final lat = center.lat.toDouble(), lng = center.lng.toDouble();
    if ((lat - _lat).abs() < 1e-6 && (lng - _lng).abs() < 1e-6) return;
    _lat = lat;
    _lng = lng;
    _pickedName = null;
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 500), _lookUpAddress);
    setState(() {});
  }

  Future<void> _lookUpAddress() async {
    setState(() => _loadingAddress = true);
    final lat = _lat, lng = _lng;
    final address = await PlaceSearchService.addressAt(lat, lng);
    if (!mounted || lat != _lat || lng != _lng) return;
    setState(() {
      _address = address;
      _loadingAddress = false;
    });
  }

  Future<void> _myLocation() async {
    try {
      var permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
      }
      if (permission == geo.LocationPermission.denied ||
          permission == geo.LocationPermission.deniedForever) {
        return;
      }
      final position =
          await geo.Geolocator.getLastKnownPosition() ??
          await geo.Geolocator.getCurrentPosition();
      await _map?.flyTo(
        CameraOptions(
          center: Point(
            coordinates: Position(position.longitude, position.latitude),
          ),
          zoom: 17.5,
        ),
        MapAnimationOptions(duration: 600),
      );
    } catch (_) {
      // The map stays where it is.
    }
  }

  void _confirm() => Navigator.pop(
    context,
    PlaceHit(
      name: _pickedName ?? '',
      address: _address ?? '',
      latitude: _lat,
      longitude: _lng,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.pickerTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: kIsWeb
                ? const WebMapFallback()
                : MapSurface(
                    builder: (context) => MapWidget(
                      styleUri: MapboxConfig.mapStyle,
                      onMapCreated: (map) async {
                        _map = map;
                        await map.setCamera(
                          CameraOptions(
                            center: Point(
                              coordinates: Position(_startLng, _startLat),
                            ),
                            zoom: _startZoom,
                          ),
                        );
                        // Let the move above settle before listening.
                        await Future<void>.delayed(
                          const Duration(milliseconds: 300),
                        );
                        _mapReady = true;
                        if (mounted) unawaited(_lookUpAddress());
                        await map.compass.updateSettings(
                          CompassSettings(enabled: false),
                        );
                        await map.scaleBar.updateSettings(
                          ScaleBarSettings(enabled: false),
                        );
                        await map.location.updateSettings(
                          LocationComponentSettings(enabled: true),
                        );
                      },
                      onCameraChangeListener: _onCameraChanged,
                      viewport: CameraViewportState(
                        center: Point(
                          coordinates: Position(_startLng, _startLat),
                        ),
                        zoom: _startZoom,
                      ),
                    ),
                  ),
          ),
          // The pin always marks the middle of the map.
          IgnorePointer(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: AppColors.danger,
                  shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(16),
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    onChanged: _onQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: l.pickerSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.clearSearch,
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _search.clear();
                                _onQuery('');
                              },
                            ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_results.isNotEmpty || _searchError != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(blurRadius: 12, color: Colors.black26),
                      ],
                    ),
                    child: _searchError != null
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(_searchError!),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: _results.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1, indent: 56),
                            itemBuilder: (context, index) {
                              final hit = _results[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.place_outlined,
                                  color: AppColors.primary,
                                ),
                                title: Text(
                                  hit.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: hit.address.isEmpty
                                    ? null
                                    : Text(
                                        hit.address,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                onTap: () => _choose(hit),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 196,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: l.pickerMyLocation,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: _myLocation,
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(blurRadius: 16, color: Colors.black26),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _pickedName ?? l.pickerPinnedSpot,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _loadingAddress
                          ? l.pickerFindingAddress
                          : _address ?? l.pickerNoAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      context.message(
                        '${_lat.toStringAsFixed(6)}, ${_lng.toStringAsFixed(6)}',
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l.pickerUseLocation),
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
}
