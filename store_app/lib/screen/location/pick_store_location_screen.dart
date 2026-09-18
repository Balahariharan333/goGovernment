import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../constants/google_config.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../services/location_service.dart';

class PickStoreLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const PickStoreLocationScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<PickStoreLocationScreen> createState() => _PickStoreLocationScreenState();
}

class _PickStoreLocationScreenState extends State<PickStoreLocationScreen> {
  late final MapController _mapController;
  late LatLng _currentLocation;
  String _currentAddress = 'Detecting address...';
  String _currentPincode = '';
  String _currentArea = '';
  String _currentCity = '';
  bool _isLoadingAddress = false;
  LatLng? _userGpsPoint;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = widget.initialLocation ?? LocationService.defaultLocation;
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _currentAddress = widget.initialAddress!;
    }

    _fetchGpsAndGeocode();
  }

  Future<void> _fetchGpsAndGeocode() async {
    if (widget.initialLocation == null) {
      _useDeviceGps();
    } else {
      _geocodePosition(_currentLocation);
    }
  }

  Future<void> _useDeviceGps() async {
    setState(() => _isLoadingAddress = true);
    final pos = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (pos != null) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userGpsPoint = latLng;
        _currentLocation = latLng;
      });
      try {
        _mapController.move(latLng, 16.5);
      } catch (_) {}
      await _geocodePosition(latLng);
    } else {
      await _geocodePosition(_currentLocation);
    }
  }

  Future<void> _geocodePosition(LatLng pos) async {
    setState(() => _isLoadingAddress = true);
    final result = await LocationService.reverseGeocode(pos.latitude, pos.longitude);
    if (!mounted) return;

    setState(() {
      _isLoadingAddress = false;
      _currentAddress = result.address;
      _currentPincode = result.pincode;
      _currentArea = result.area;
      _currentCity = result.city;
    });
  }

  void _onMapTapped(LatLng tapped) {
    setState(() {
      _currentLocation = tapped;
    });
    try {
      _mapController.move(tapped, _mapController.camera.zoom);
    } catch (_) {}

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _geocodePosition(tapped);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // 1. Full Screen Interactive OpenStreetMap
              Positioned.fill(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    onTap: (_, point) => _onMapTapped(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: GoogleConfig.googleTileUrl,
                      subdomains: GoogleConfig.googleTileSubdomains,
                      maxZoom: 20,
                      userAgentPackageName: 'com.hikizo.storeapp',
                    ),
                    // Live user GPS blue dot
                    if (_userGpsPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userGpsPoint!,
                            width: 26,
                            height: 26,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Selected Store Location Pin
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation,
                          width: 52,
                          height: 52,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                              ),
                              CustomPaint(
                                size: const Size(10, 6),
                                painter: _TrianglePainter(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Top Header Bar
              Positioned(
                top: Responsive.h(12),
                left: Responsive.w(16),
                right: Responsive.w(16),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.w(12), vertical: Responsive.h(10)),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(Responsive.w(16)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      SizedBox(width: Responsive.w(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomText.title('Pinpoint Store Location', fontSize: 15, color: AppColors.black),
                            SizedBox(height: Responsive.h(2)),
                            CustomText.body(
                              'Tap map or drag to set accurate shop entrance',
                              fontSize: 11,
                              color: AppColors.grayFont,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Floating "Current GPS" Button
              Positioned(
                right: Responsive.w(16),
                bottom: Responsive.h(230),
                child: FloatingActionButton.extended(
                  heroTag: 'gps_recenter_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Responsive.w(24))),
                  icon: const Icon(Icons.my_location_rounded, size: 18, color: AppColors.primary),
                  label: CustomText.title('Current GPS', fontSize: 12, color: AppColors.primary),
                  onPressed: _useDeviceGps,
                ),
              ),

              // 4. Bottom Location Confirmation Card
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.w(20),
                    Responsive.h(20),
                    Responsive.w(20),
                    Responsive.h(28),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(Responsive.w(24))),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(Responsive.w(10)),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(Responsive.w(12)),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                          ),
                          SizedBox(width: Responsive.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText.title(
                                  _isLoadingAddress ? 'Resolving Address...' : 'Selected Store Location',
                                  fontSize: 14,
                                  color: AppColors.black,
                                ),
                                SizedBox(height: Responsive.h(4)),
                                if (_isLoadingAddress)
                                  const LinearProgressIndicator(color: AppColors.primary, minHeight: 2)
                                else
                                  CustomText.body(
                                    _currentAddress,
                                    fontSize: 12,
                                    color: AppColors.grayFont,
                                    maxLines: 2,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // GPS Coordinate & Pincode Chips
                      Wrap(
                        spacing: Responsive.w(8),
                        runSpacing: Responsive.h(6),
                        children: [
                          _buildChip(
                            Icons.explore_outlined,
                            '${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
                          ),
                          if (_currentPincode.isNotEmpty)
                            _buildChip(Icons.pin_drop_outlined, 'Pincode: $_currentPincode'),
                          if (_currentArea.isNotEmpty)
                            _buildChip(Icons.location_city_outlined, _currentArea),
                        ],
                      ),
                      SizedBox(height: Responsive.h(16)),

                      // Confirm Location Button
                      SizedBox(
                        width: double.infinity,
                        height: Responsive.h(50),
                        child: ElevatedButton(
                          onPressed: _isLoadingAddress
                              ? null
                              : () {
                                  final result = StoreLocationResult(
                                    latitude: _currentLocation.latitude,
                                    longitude: _currentLocation.longitude,
                                    address: _currentAddress,
                                    pincode: _currentPincode,
                                    area: _currentArea,
                                    city: _currentCity,
                                  );
                                  Navigator.of(context).pop(result);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Responsive.w(14)),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              SizedBox(width: Responsive.w(8)),
                              CustomText.title('Confirm Shop Location', fontSize: 15, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: Responsive.w(10), vertical: Responsive.h(5)),
      decoration: BoxDecoration(
        color: AppColors.screenColor,
        borderRadius: BorderRadius.circular(Responsive.w(8)),
        border: Border.all(color: AppColors.outliner.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          SizedBox(width: Responsive.w(4)),
          Text(
            text,
            style: TextStyle(
              fontSize: Responsive.sp(11),
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
