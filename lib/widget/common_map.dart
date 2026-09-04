import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';
import '../service/location_service.dart';

enum MapState { list, directions, navigation }

/// High-fidelity, real-time interactive map powered by OpenStreetMap & FlutterMap.
class CommonMap extends StatefulWidget {
  final MapState mapState;
  final bool isWalkMode;
  final double? width;
  final double? height;
  final LatLng? center;
  final double? zoom;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final bool showUserLocation;
  final bool interactive;
  final bool showControls;
  final void Function(LatLng)? onTap;
  final MapController? mapController;

  const CommonMap({
    super.key,
    this.mapState = MapState.list,
    this.isWalkMode = false,
    this.width,
    this.height,
    this.center,
    this.zoom,
    this.markers,
    this.polylines,
    this.showUserLocation = true,
    this.interactive = true,
    this.showControls = false,
    this.onTap,
    this.mapController,
  });

  @override
  State<CommonMap> createState() => _CommonMapState();
}

class _CommonMapState extends State<CommonMap> {
  late final MapController _mapController;
  LatLng _currentCenter = LocationService.defaultLocation;
  LatLng? _userGpsLocation;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
    _currentCenter = widget.center ?? LocationService.defaultLocation;
    _detectUserPosition();
  }

  @override
  void didUpdateWidget(covariant CommonMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.center != null && widget.center != oldWidget.center) {
      _currentCenter = widget.center!;
      _mapController.move(_currentCenter, widget.zoom ?? 15.0);
    }
  }

  Future<void> _detectUserPosition() async {
    if (!widget.showUserLocation && widget.center != null) return;
    setState(() => _isLoadingGps = true);
    final Position? pos = await LocationService.getCurrentPosition(requestPermission: false);
    if (!mounted) return;
    if (pos != null) {
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userGpsLocation = userLatLng;
        if (widget.center == null) {
          _currentCenter = userLatLng;
          _mapController.move(_currentCenter, widget.zoom ?? 15.0);
        }
        _isLoadingGps = false;
      });
    } else {
      setState(() => _isLoadingGps = false);
    }
  }

  void _recenterOnUser() async {
    setState(() => _isLoadingGps = true);
    final Position? pos = await LocationService.getCurrentPosition(requestPermission: true);
    if (!mounted) return;
    if (pos != null) {
      final userLatLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userGpsLocation = userLatLng;
        _currentCenter = userLatLng;
        _isLoadingGps = false;
      });
      _mapController.move(userLatLng, 16.0);
    } else {
      setState(() => _isLoadingGps = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to detect current GPS location. Please check permissions.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Responsive.w(12)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Marker> allMarkers = [];

    // 1. Add User live GPS marker if available
    if (widget.showUserLocation && _userGpsLocation != null) {
      allMarkers.add(
        Marker(
          point: _userGpsLocation!,
          width: Responsive.w(44),
          height: Responsive.w(44),
          child: _buildUserLocationMarker(),
        ),
      );
    }

    // 2. Add screen-provided custom markers
    if (widget.markers != null) {
      allMarkers.addAll(widget.markers!);
    } else if (widget.center != null && (_userGpsLocation == null || widget.center != _userGpsLocation)) {
      // Default pin at center if no markers provided
      allMarkers.add(
        Marker(
          point: widget.center!,
          width: Responsive.w(40),
          height: Responsive.w(40),
          child: const Icon(
            Icons.location_on,
            color: AppColors.primary,
            size: 38,
          ),
        ),
      );
    }

    // 3. Fallback demo markers for near stores / toilets / stops if screen didn't pass custom markers
    if (allMarkers.isEmpty) {
      allMarkers.addAll(_buildFallbackMarkers());
    }

    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: widget.zoom ?? 15.0,
              interactionOptions: InteractionOptions(
                flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
              onTap: (tapPosition, point) => widget.onTap?.call(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hikizo.gogovernment',
                maxZoom: 19,
              ),
              if (widget.polylines != null && widget.polylines!.isNotEmpty)
                PolylineLayer(polylines: widget.polylines!),
              MarkerLayer(markers: allMarkers),
            ],
          ),

          // Recenter & GPS Controls
          // if (widget.showControls || widget.interactive)
          //   Positioned(
          //     right: Responsive.w(14),
          //     bottom: Responsive.h(14),
          //     child: Column(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         FloatingActionButton.small(
          //           heroTag: 'map_recenter_${widget.hashCode}',
          //           backgroundColor: Colors.white,
          //           elevation: 3,
          //           onPressed: _recenterOnUser,
          //           child: _isLoadingGps
          //               ? SizedBox(
          //                   width: Responsive.w(16),
          //                   height: Responsive.w(16),
          //                   child: const CircularProgressIndicator(
          //                     strokeWidth: 2,
          //                     color: AppColors.primary,
          //                   ),
          //                 )
          //               : const Icon(
          //                   Icons.my_location,
          //                   color: AppColors.primary,
          //                   size: 20,
          //                 ),
          //         ),
          //       ],
          //     ),
          //   ),
       
       
        ],
      ),
    );
  }

  Widget _buildUserLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: Responsive.w(40),
          height: Responsive.w(40),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: Responsive.w(18),
          height: Responsive.w(18),
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Marker> _buildFallbackMarkers() {
    // Relative points around center for default visualization
    final center = _currentCenter;
    return [
      Marker(
        point: LatLng(center.latitude + 0.002, center.longitude + 0.002),
        width: 36,
        height: 36,
        child: const Icon(Icons.location_on, color: AppColors.primary, size: 34),
      ),
      Marker(
        point: LatLng(center.latitude - 0.0025, center.longitude + 0.0015),
        width: 36,
        height: 36,
        child: const Icon(Icons.location_on, color: AppColors.primary, size: 34),
      ),
    ];
  }
}
