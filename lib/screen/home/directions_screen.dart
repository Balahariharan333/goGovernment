import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_government/utils/responsive_helper.dart';
import '../../utils/app_colors.dart';
import 'package:go_government/bloc/direction/direction_bloc.dart';
import 'package:go_government/bloc/direction/direction_event.dart';
import 'package:go_government/bloc/direction/direction_state.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../../widget/common_map.dart';
import '../../service/location_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class DirectionsScreen extends StatefulWidget {
  final String title;
  final String address;

  const DirectionsScreen({
    super.key,
    required this.title,
    required this.address,
  });

  @override
  State<DirectionsScreen> createState() => _DirectionsScreenState();
}

class _DirectionsScreenState extends State<DirectionsScreen> {
  LatLng? _destinationLatLng;

  @override
  void initState() {
    super.initState();
    _geocodeDestination();
    // Fetch directions after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DirectionBloc>().add(FetchDirections(
            origin: 'Current Location',
            destination: widget.address,
          ));
    });
  }

  Future<void> _geocodeDestination() async {
    final latLng = await LocationService.getCoordinatesFromAddress(widget.address);
    if (latLng != null && mounted) {
      setState(() {
        _destinationLatLng = latLng;
      });
    }
  }

  bool _isNavigating = false;
  bool _isWalkMode = false;
  Timer? _navTimer;
  int _remainingSeconds = 360;
  String _currentInstruction = 'Head north on 16th Main Rd (200m)';
  IconData _currentManeuverIcon = Icons.arrow_upward;

  void _startNavigation() async {
    // Launch external native navigation (Google Maps / Apple Maps)
    await LocationService.launchTurnByTurnNavigation(
      destLat: _destinationLatLng?.latitude,
      destLng: _destinationLatLng?.longitude,
      address: widget.address,
      isWalking: _isWalkMode,
    );

    if (!mounted) return;

    setState(() {
      _isNavigating = true;
      _remainingSeconds = _isWalkMode ? 720 : 360;
      _currentInstruction = 'Head north on 16th Main Rd (200m)';
      _currentManeuverIcon = Icons.arrow_upward;
    });

    _navTimer?.cancel();
    _navTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 30) {
          _remainingSeconds -= 30;
          if (_remainingSeconds <= 90) {
            _currentInstruction = 'Destination is on your left (50m)';
            _currentManeuverIcon = Icons.turn_left;
          } else if (_remainingSeconds <= 200) {
            _currentInstruction = 'Turn right onto 15th Cross Rd (300m)';
            _currentManeuverIcon = Icons.turn_right;
          } else {
            _currentInstruction = 'Continue straight toward Sector 4 (600m)';
            _currentManeuverIcon = Icons.straight;
          }
        } else {
          timer.cancel();
          _isNavigating = false;
          _showArrivalDialog();
        }
      });
    });
  }

  void _stopNavigation() {
    _navTimer?.cancel();
    setState(() {
      _isNavigating = false;
    });
  }

  void _showArrivalDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('You have arrived!'),
          ],
        ),
        content: Text('You have reached ${widget.title}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<DirectionBloc, DirectionState>(
        builder: (context, directionState) {
          return Stack(

            children: [
              // 1. Map Canvas
              Positioned.fill(
                child: CommonMap(
                  mapState: _isNavigating ? MapState.navigation : MapState.directions,
                  isWalkMode: _isWalkMode,
                  center: _destinationLatLng,
                  markers: _destinationLatLng != null
                      ? [
                          Marker(
                            point: _destinationLatLng!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ]
                      : null,
                ),
              ),

              // 1b. Navigation HUD Turn Banner
              if (_isNavigating)
                Positioned(
                  top: Responsive.h(64),
                  left: Responsive.w(20),
                  right: Responsive.w(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.w(16),
                      vertical: Responsive.h(12),
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(Responsive.w(16)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: Responsive.w(38),
                          height: Responsive.w(38),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentManeuverIcon,
                            color: Colors.white,
                            size: Responsive.w(22),
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomText.title(
                                _currentInstruction,
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: Responsive.h(2)),
                              Text(
                                '${_remainingSeconds ~/ 60}m remaining · GPS active',
                                style: const TextStyle(
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
                ),

              // 2. Custom Back Button & Header overlay
              Positioned(
                top: Responsive.h(10),
                left: Responsive.w(20),
                right: Responsive.w(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: Responsive.w(44),
                        height: Responsive.w(44),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.outliner,
                            width: Responsive.w(1.5),
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: AppColors.black,
                          size: Responsive.w(24),
                        ),
                      ),
                    ),
                    
                    // Travel Mode Toggle Selector (Walk vs Drive)
                    if (!_isNavigating)
                      Container(
                        height: Responsive.h(40),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Responsive.w(20)),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isWalkMode = true;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                                decoration: BoxDecoration(
                                  color: _isWalkMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(Responsive.w(20)),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.directions_walk,
                                  color: _isWalkMode ? Colors.white : AppColors.black,
                                  size: Responsive.w(20),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isWalkMode = false;
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
                                decoration: BoxDecoration(
                                  color: !_isWalkMode ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(Responsive.w(20)),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.directions_car,
                                  color: !_isWalkMode ? Colors.white : AppColors.black,
                                  size: Responsive.w(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            // Loading indicator
            if (directionState is DirectionLoading)
              const Center(child: CircularProgressIndicator()),

              // 3. Bottom Panel Overlay
              Positioned(
                bottom: Responsive.h(20),
                left: Responsive.w(20),
                right: Responsive.w(20),
                child: _isNavigating ? _buildActiveNavigationPanel() : _buildDirectionsPanel(),
              ),
          ],
        );
        },
      ),
        ),
      )
    );
  }

  Widget _buildDirectionsPanel() {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
        border: Border.all(color: AppColors.outliner, width: 1.2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.header(
            widget.title,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: Responsive.h(4)),
          CustomText.subtitle(
            widget.address,
            fontSize: 12,
            color: AppColors.grayFont,
            maxLines: 2,
          ),
          SizedBox(height: Responsive.h(16)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.title(
                    _isWalkMode ? '12 mins' : '6 mins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4CAF50),
                  ),
                  CustomText.subtitle(
                    _isWalkMode ? 'Distance: 900m' : 'Distance: 1.8km',
                    fontSize: 11,
                    color: AppColors.grayFont,
                  ),
                ],
              ),
              GestureDetector(
                onTap: _startNavigation,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.w(20),
                    vertical: Responsive.h(12),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(Responsive.w(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.white, size: 16),
                      SizedBox(width: Responsive.w(8)),
                      CustomText.title(
                        'Start Navigation',
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveNavigationPanel() {
    return Row(
      children: [
        // Cancel button
        GestureDetector(
          onTap: _stopNavigation,
          child: Container(
            width: Responsive.w(48),
            height: Responsive.w(48),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                )
              ],
            ),
            child: Icon(
              Icons.close,
              color: AppColors.black,
              size: Responsive.w(20),
            ),
          ),
        ),
        SizedBox(width: Responsive.w(12)),

        // Center time progress bubble
        Expanded(
          child: Container(
            height: Responsive.h(48),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(Responsive.w(24)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                )
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: Responsive.w(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.navigation,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                    SizedBox(width: Responsive.w(8)),
                    CustomText.title(
                      'Navigating...',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ],
                ),
                CustomText.title(
                  '${_remainingSeconds ~/ 60}m left',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
