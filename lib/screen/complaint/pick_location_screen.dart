import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../service/location_service.dart';

/// Screen allowing citizens to pick or search any location where a complaint occurred.
class PickLocationScreen extends StatefulWidget {
  final LatLng? initialLatLng;
  final String? initialAddress;

  const PickLocationScreen({
    super.key,
    this.initialLatLng,
    this.initialAddress,
  });

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  late LatLng _selectedLatLng;
  String _selectedAddress = '';
  bool _isLoadingAddress = false;
  bool _isSearching = false;
  LatLng? _userGpsLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLatLng = widget.initialLatLng ?? LocationService.defaultLocation;
    _selectedAddress = widget.initialAddress ?? 'Loading address...';

    if (widget.initialAddress == null || widget.initialAddress!.isEmpty) {
      _reverseGeocode(_selectedLatLng);
    }
    _detectUserGps();
  }

  Future<void> _detectUserGps() async {
    final Position? pos = await LocationService.getCurrentPosition(requestPermission: false);
    if (pos != null && mounted) {
      setState(() {
        _userGpsLocation = LatLng(pos.latitude, pos.longitude);
      });
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() => _isLoadingAddress = true);
    final addr = await LocationService.getAddressFromCoordinates(point.latitude, point.longitude);
    if (!mounted) return;
    setState(() {
      _selectedAddress = addr;
      _isLoadingAddress = false;
    });
  }

  void _onMapTapped(LatLng point) {
    setState(() {
      _selectedLatLng = point;
    });
    _mapController.move(point, _mapController.camera.zoom);
    _reverseGeocode(point);
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    final LatLng? coords = await LocationService.getCoordinatesFromAddress(query);
    if (!mounted) return;

    setState(() => _isSearching = false);

    if (coords != null) {
      setState(() {
        _selectedLatLng = coords;
      });
      _mapController.move(coords, 16.0);
      _reverseGeocode(coords);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not find "$query". Try entering a landmark or city name.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _recenterOnUserGps() async {
    setState(() => _isLoadingAddress = true);
    final Position? pos = await LocationService.getCurrentPosition(requestPermission: true);
    if (!mounted) return;
    if (pos != null) {
      final userPoint = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userGpsLocation = userPoint;
        _selectedLatLng = userPoint;
      });
      _mapController.move(userPoint, 16.0);
      _reverseGeocode(userPoint);
    } else {
      setState(() => _isLoadingAddress = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
                    initialCenter: _selectedLatLng,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                    onTap: (_, point) => _onMapTapped(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hikizo.gogovernment',
                      maxZoom: 19,
                    ),
                    // Live user GPS location dot if available
                    if (_userGpsLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userGpsLocation!,
                            width: 24,
                            height: 24,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    // Selected Complaint Location Pin
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLatLng,
                          width: 48,
                          height: 48,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Top Navigation Bar & Search Overlay
              Positioned(
                top: Responsive.h(10),
                left: Responsive.w(16),
                right: Responsive.w(16),
                child: Column(
                  children: [
                    // Header Row with Back Button & Title
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: Responsive.w(44),
                            height: Responsive.w(44),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.outliner,
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: AppColors.black,
                              size: 24,
                            ),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.w(16),
                              vertical: Responsive.h(10),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(Responsive.w(20)),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.outliner,
                                width: 1.2,
                              ),
                            ),
                            child: CustomText.title(
                              'Pick Complaint Location',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(10)),

                    // Search Input Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(24)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.outliner,
                          width: 1.2,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: Responsive.w(12)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppColors.primary,
                            size: Responsive.w(20),
                          ),
                          SizedBox(width: Responsive.w(8)),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchLocation(),
                              decoration: InputDecoration(
                                hintText: 'Search landmark, area or street...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: Responsive.sp(13),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: Responsive.h(10)),
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: const Icon(Icons.close, color: Colors.grey, size: 18),
                            ),
                          SizedBox(width: Responsive.w(4)),
                          GestureDetector(
                            onTap: _searchLocation,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: Responsive.w(12),
                                vertical: Responsive.h(6),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(Responsive.w(16)),
                              ),
                              child: _isSearching
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Find',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Floating "Snap to My GPS" Action Button
              Positioned(
                right: Responsive.w(16),
                bottom: Responsive.h(190),
                child: FloatingActionButton.small(
                  heroTag: 'recenter_gps_fab',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: _recenterOnUserGps,
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ),

              // 4. Bottom Location Confirmation Card
              Positioned(
                bottom: Responsive.h(20),
                left: Responsive.w(16),
                right: Responsive.w(16),
                child: Container(
                  padding: EdgeInsets.all(Responsive.w(16)),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(Responsive.w(20)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.outliner,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: Responsive.w(10)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: CustomText.title(
                                        'Selected Location',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: Responsive.w(8)),
                                    Text(
                                      '${_selectedLatLng.latitude.toStringAsFixed(4)}, ${_selectedLatLng.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: Responsive.h(4)),
                                _isLoadingAddress
                                    ? Row(
                                        children: [
                                          const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          SizedBox(width: Responsive.w(8)),
                                          const Text(
                                            'Resolving street address...',
                                            style: TextStyle(color: Colors.grey, fontSize: 12),
                                          ),
                                        ],
                                      )
                                    : CustomText.subtitle(
                                        _selectedAddress,
                                        fontSize: 12,
                                        color: const Color(0xFF333333),
                                        maxLines: 2,
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Responsive.h(14)),
                      const Text(
                        'Tip: Tap anywhere on the map or search to place the complaint pin.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: Responsive.h(12)),

                      // Confirm Location Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, {
                            'latLng': _selectedLatLng,
                            'address': _selectedAddress,
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          height: Responsive.h(46),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(Responsive.w(23)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Confirm Complaint Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }
}
