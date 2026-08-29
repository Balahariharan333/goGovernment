import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';
import '../../../widget/common_map.dart';
import '../../../bloc/toilet/toilet_bloc.dart';
import '../../../bloc/toilet/toilet_event.dart';
import '../../../bloc/toilet/toilet_state.dart';

enum ToiletFlowState { list, directions, navigation }

class NearToiletScreen extends StatefulWidget {
  const NearToiletScreen({super.key});

  @override
  State<NearToiletScreen> createState() => _NearToiletScreenState();
}

class _NearToiletScreenState extends State<NearToiletScreen> {
  final List<Map<String, dynamic>> _toilets = [
    {'title': 'Public toilet', 'distance': '260.0 m'},
    {'title': 'Public toilet', 'distance': '310.0 m'},
    {'title': 'Public toilet', 'distance': '450.0 m'},
    {'title': 'Public toilet', 'distance': '520.0 m'},
    {'title': 'Public toilet', 'distance': '680.0 m'},
  ];

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<ToiletBloc, ToiletState>(
      builder: (context, state) {
        final ToiletFlowState flowState = state.flowState;
        final bool isWalkMode = state.isWalkMode;
        final int selectedToiletIndex = state.selectedIndex;

        return Scaffold(
          backgroundColor: AppColors.screenColor,
          body: CommonBackground(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  // 1. Map Canvas (Full screen underlay)
                  Positioned.fill(
                    child: Column(
                      children: [
                        // Dynamic Map Height depending on flow state
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: flowState == ToiletFlowState.list
                              ? Responsive.h(280)
                              : MediaQuery.of(context).size.height - Responsive.h(100),
                          child: CommonMap(
                            mapState: flowState == ToiletFlowState.list
                                ? MapState.list
                                : flowState == ToiletFlowState.directions
                                    ? MapState.directions
                                    : MapState.navigation,
                            isWalkMode: isWalkMode,
                          ),
                        ),
                        if (flowState == ToiletFlowState.list) const Spacer(),
                      ],
                    ),
                  ),

                  // 2. Circle Back Button overlay (visible in list & directions modes)
                  if (flowState != ToiletFlowState.navigation)
                    Positioned(
                      top: Responsive.h(10),
                      left: Responsive.w(20),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (flowState == ToiletFlowState.directions) {
                                context.read<ToiletBloc>().add(ChangeToiletFlowStateEvent(ToiletFlowState.list));
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
                          if (flowState == ToiletFlowState.list)
                            CustomText.header(
                              'Near Toilet',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          if (flowState == ToiletFlowState.directions)
                            CustomText.header(
                              'Directions',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                        ],
                      ),
                    ),

                  // 3. Dynamic Card Overlays based on state
                  _buildContentOverlay(context, screenWidth, flowState, isWalkMode, selectedToiletIndex),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentOverlay(BuildContext context, double screenWidth, ToiletFlowState flowState, bool isWalkMode, int selectedIndex) {
    switch (flowState) {
      case ToiletFlowState.list:
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
            itemCount: _toilets.length,
            itemBuilder: (context, index) {
              final toilet = _toilets[index];
              return Padding(
                padding: EdgeInsets.only(bottom: Responsive.h(12)),
                child: _buildToiletCard(context, toilet, index),
              );
            },
          ),
        );

      case ToiletFlowState.directions:
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
                        CustomText.title(_toilets[selectedIndex]['title'], fontSize: 14),
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
                              context.read<ToiletBloc>().add(ChangeToiletWalkModeEvent(false));
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
                              context.read<ToiletBloc>().add(ChangeToiletWalkModeEvent(true));
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
                        context.read<ToiletBloc>().add(ChangeToiletFlowStateEvent(ToiletFlowState.navigation));
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

      case ToiletFlowState.navigation:
        return Stack(
          children: [
            // Top Navigation Instruction bar
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

            // Bottom Navigation Active Progress bar
            Positioned(
              bottom: Responsive.h(20),
              left: Responsive.w(20),
              right: Responsive.w(20),
              child: Row(
                children: [
                  // Cancel button
                  GestureDetector(
                    onTap: () {
                      context.read<ToiletBloc>().add(ChangeToiletFlowStateEvent(ToiletFlowState.directions));
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

  Widget _buildToiletCard(BuildContext context, Map<String, dynamic> toilet, int index) {
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
            toilet['title'],
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          SizedBox(height: Responsive.h(4)),
          CustomText.subtitle(
            'Toilet - ${toilet['distance']}',
            fontSize: 12,
            color: AppColors.grayFont,
          ),
          SizedBox(height: Responsive.h(12)),
          GestureDetector(
            onTap: () {
              context.read<ToiletBloc>().add(ChangeToiletFlowStateEvent(ToiletFlowState.directions));
              context.read<ToiletBloc>().add(SelectToiletEvent(index));
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
