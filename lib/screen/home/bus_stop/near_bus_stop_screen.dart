import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_map.dart';
import '../../../bloc/bus_stop/bus_stop_bloc.dart';
import '../../../bloc/bus_stop/bus_stop_event.dart';
import '../../../bloc/bus_stop/bus_stop_state.dart';

enum BusStopFlowState { list, directions, navigation }

class NearBusStopScreen extends StatefulWidget {
  const NearBusStopScreen({super.key});

  @override
  State<NearBusStopScreen> createState() => _NearBusStopScreenState();
}

class _NearBusStopScreenState extends State<NearBusStopScreen> {
  final List<Map<String, dynamic>> _busStops = [
    {'title': 'Bus Stop', 'distance': '120.0 m'},
    {'title': 'Bus Stop', 'distance': '240.0 m'},
    {'title': 'Bus Stop', 'distance': '380.0 m'},
    {'title': 'Bus Stop', 'distance': '450.0 m'},
    {'title': 'Bus Stop', 'distance': '610.0 m'},
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<BusStopBloc, BusStopState>(
      builder: (context, state) {
        final BusStopFlowState flowState = state.flowState;
        final bool isWalkMode = state.isWalkMode;
        final int selectedBusStopIndex = state.selectedIndex;

        return Scaffold(
          backgroundColor: AppColors.screenColor,
          body: CommonBackground(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // 1. Map underlay using CommonMap
                  Positioned.fill(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: flowState == BusStopFlowState.list
                              ? Responsive.h(280)
                              : MediaQuery.of(context).size.height - Responsive.h(100),
                          child: CommonMap(
                            mapState: flowState == BusStopFlowState.list
                                ? MapState.list
                                : flowState == BusStopFlowState.directions
                                    ? MapState.directions
                                    : MapState.navigation,
                            isWalkMode: isWalkMode,
                          ),
                        ),
                        if (flowState == BusStopFlowState.list) const Spacer(),
                      ],
                    ),
                  ),

                  // 2. Circle Back Button & Title Overlay
                  if (flowState != BusStopFlowState.navigation)
                    Positioned(
                      top: Responsive.h(10),
                      left: Responsive.w(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (flowState == BusStopFlowState.directions) {
                                context.read<BusStopBloc>().add(ChangeBusStopFlowStateEvent(BusStopFlowState.list));
                              } else {
                                Navigator.pop(context);
                              }
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
                          SizedBox(width: Responsive.w(12)),
                          if (flowState == BusStopFlowState.list)
                            CustomText.header(
                              'Near Bus Stop',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          if (flowState == BusStopFlowState.directions)
                            CustomText.header(
                              'Directions',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                        ],
                      ),
                    ),

                  // 3. Conditional Flow Layout Overlays
                  _buildContentOverlay(context, screenWidth, flowState, isWalkMode, selectedBusStopIndex),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentOverlay(BuildContext context, double screenWidth, BusStopFlowState flowState, bool isWalkMode, int selectedIndex) {
    switch (flowState) {
      case BusStopFlowState.list:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          top: Responsive.h(290), // Sits below the map
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(20),
              vertical: Responsive.h(12),
            ),
            itemCount: _busStops.length,
            itemBuilder: (context, index) {
              final busStop = _busStops[index];
              return Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(12)),
                child: _buildBusStopCard(context, busStop, index),
              );
            },
          ),
        );

      case BusStopFlowState.directions:
        return Stack(
          children: [
            // Top Location search overview card
            Positioned(
              top: Responsive.h(70),
              left: Responsive.w(20),
              right: Responsive.w(20),
              child: Container(
                padding: EdgeInsets.all(Responsive.w(16)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Responsive.w(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: Responsive.w(10),
                          height: Responsive.w(10),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: Responsive.w(16)),
                        CustomText.title('Your Location', fontSize: 14),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: Responsive.w(4)),
                      child: Container(
                        width: Responsive.w(2),
                        height: Responsive.h(16),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: Responsive.w(14),
                        ),
                        SizedBox(width: Responsive.w(14)),
                        CustomText.title(_busStops[selectedIndex]['title'], fontSize: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation details card
            Positioned(
              bottom: Responsive.h(20),
              left: Responsive.w(20),
              right: Responsive.w(20),
              child: Container(
                padding: EdgeInsets.all(Responsive.w(20)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Responsive.w(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText.header(
                      isWalkMode ? 'Walk' : 'Two-wheeler',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(16)),

                    // Mode selectors
                    Row(
                      children: [
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.motorcycle,
                            label: '1 min',
                            isSelected: !isWalkMode,
                            onTap: () {
                              context.read<BusStopBloc>().add(ChangeBusStopWalkModeEvent(false));
                            },
                          ),
                        ),
                        SizedBox(width: Responsive.w(12)),
                        Expanded(
                          child: _buildModeTab(
                            icon: Icons.directions_walk,
                            label: '1 min',
                            isSelected: isWalkMode,
                            onTap: () {
                              context.read<BusStopBloc>().add(ChangeBusStopWalkModeEvent(true));
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Responsive.h(12)),

                    // Distance/Time summary text
                    CustomText.title(
                      isWalkMode ? '4 min (350 m)' : '1 min (350 m)',
                      color: const Color(0xFF4CAF50),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: Responsive.h(20)),

                    // Action Start button
                    GestureDetector(
                      onTap: () {
                        context.read<BusStopBloc>().add(ChangeBusStopFlowStateEvent(BusStopFlowState.navigation));
                      },
                      child: Container(
                        width: double.infinity,
                        height: Responsive.h(50),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(Responsive.w(25)),
                          border: Border.all(
                            color: AppColors.primary,
                            width: Responsive.w(1.5),
                          ),
                        ),
                        child: Center(
                          child: CustomText.title(
                            'Start',
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );

      case BusStopFlowState.navigation:
        return Stack(
          children: [
            // Top Instruction Card Overlay
            Positioned(
              top: Responsive.h(20),
              left: Responsive.w(20),
              right: Responsive.w(20),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(20),
                  vertical: Responsive.h(16),
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(Responsive.w(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: Responsive.w(36),
                      height: Responsive.w(36),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF2EC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.navigation_outlined,
                        color: AppColors.primary,
                        size: Responsive.w(18),
                      ),
                    ),
                    SizedBox(width: Responsive.w(16)),
                    Expanded(
                      child: CustomText.title(
                        'towards 15th Cross Road',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation details overlay
            Positioned(
              bottom: Responsive.h(20),
              left: Responsive.w(20),
              right: Responsive.w(20),
              child: Row(
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: () {
                      context.read<BusStopBloc>().add(ChangeBusStopFlowStateEvent(BusStopFlowState.directions));
                    },
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                          )
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomText.title(
                              isWalkMode ? '4 min' : '1 min',
                              color: const Color(0xFF4CAF50),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            SizedBox(width: Responsive.w(8)),
                            CustomText.subtitle(
                              isWalkMode ? '(350 m) - 12:35 pm' : '(350 m) - 12:31 pm',
                              fontSize: 12,
                              color: AppColors.grayFont,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.w(12)),

                  // Compass/Layers button
                  Container(
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
                      Icons.gps_fixed,
                      color: AppColors.primary,
                      size: Responsive.w(20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildModeTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Responsive.h(48),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF2EC) : AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(16)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outliner.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.grayFont,
              size: Responsive.w(20),
            ),
            SizedBox(width: Responsive.w(8)),
            CustomText.title(
              label,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.primary : AppColors.grayFont,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusStopCard(BuildContext context, Map<String, dynamic> busStop, int index) {
    return Container(
      padding: EdgeInsets.all(Responsive.w(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(20)),
        border: Border.all(
          color: AppColors.outliner,
          width: Responsive.w(1.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.title(
            busStop['title'],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: Responsive.h(4)),
          CustomText.subtitle(
            'Bus Stop - ${busStop['distance']}',
            fontSize: 12,
            color: AppColors.grayFont,
          ),
          SizedBox(height: Responsive.h(12)),
          GestureDetector(
            onTap: () {
              context.read<BusStopBloc>().add(ChangeBusStopFlowStateEvent(BusStopFlowState.directions));
              context.read<BusStopBloc>().add(SelectBusStopEvent(index));
            },
            child: Container(
              height: Responsive.h(36),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(Responsive.w(18)),
                border: Border.all(
                  color: AppColors.primary,
                  width: Responsive.w(1.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.navigation,
                    color: AppColors.primary,
                    size: Responsive.w(14),
                  ),
                  SizedBox(width: Responsive.w(8)),
                  CustomText.title(
                    'Directions',
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
