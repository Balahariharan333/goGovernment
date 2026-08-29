import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_text.dart';
import '../complaint/add_complaint_screen.dart'; // To reuse the MapPainter!
import '../../widget/common_directions_button.dart';

class ComplaintDetailsScreen extends StatelessWidget {
  final String userName;
  final String status;
  final Color statusColor;

  const ComplaintDetailsScreen({
    super.key,
    required this.userName,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: Responsive.w(70),
        leading: Padding(
          padding: EdgeInsets.only(left: Responsive.w(20)),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
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
          ),
        ),
        title: CustomText.header(
          'Complaint Details',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: false,
      ),
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.w(20),
                vertical: Responsive.h(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Header Section (Rounded on all sides, text inside gradient overlay)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Responsive.w(28)),
                    child: Container(
                      height: Responsive.h(280),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.outliner,
                          width: Responsive.w(1.5),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/report1.png',
                            fit: BoxFit.cover,
                          ),
                          // Dark gradient overlay at the bottom
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: Responsive.h(90),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.85),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Citizen avatar + details row inside image
                          Positioned(
                            bottom: Responsive.h(16),
                            left: Responsive.w(16),
                            child: Row(
                              children: [
                                Container(
                                  width: Responsive.w(44),
                                  height: Responsive.w(44),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person,
                                      color: AppColors.primary,
                                      size: Responsive.w(24),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Responsive.w(12)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText.title(
                                      userName,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    CustomText.subtitle(
                                      '5 days ago',
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),

                  // 2. Complaint details card (Holds details, map, directions, divider, and reactions)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.w(16)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(24)),
                      border: Border.all(
                        color: AppColors.outliner,
                        width: Responsive.w(1.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status
                        Row(
                          children: [
                            CustomText.title(
                              'Status: ',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            CustomText.title(
                              status,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(12)),

                        // Title
                        CustomText.header(
                          'Road Damage',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: Responsive.h(8)),

                        // Description
                        CustomText.body(
                          'The road is completely damaged and it is difficult for us to ride our vehicles safely. Kindly repair the road and resolve this issue as soon as possible.',
                          color: const Color(0xFF4A4A4A),
                          fontSize: 10,
                          height: 1.4,
                        ),
                        SizedBox(height: Responsive.h(16)),

                        // Metadata rows with spaces around colons matching screenshot
                        Row(
                          children: [
                            CustomText.title(
                              'ID: ',
                              fontSize: 13,
                              color: AppColors.grayFont,
                              fontWeight: FontWeight.bold,
                            ),
                            CustomText.body(
                              'ertyuiuhgf',
                              fontSize: 13,
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(8)),
                        Row(
                          children: [
                            CustomText.title(
                              'Engineer\'s Name : ',
                              fontSize: 13,
                              color: AppColors.grayFont,
                              fontWeight: FontWeight.bold,
                            ),
                            Expanded(
                              child: CustomText.body(
                                'HSR Layout 174',
                                fontSize: 13,
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(8)),
                        Row(
                          children: [
                            CustomText.title(
                              'Engineer\'s Content : ',
                              fontSize: 13,
                              color: AppColors.grayFont,
                              fontWeight: FontWeight.bold,
                            ),
                            Expanded(
                              child: CustomText.body(
                                '+91 12345 54321',
                                fontSize: 13,
                                color: AppColors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(16)),

                        // Miniature Map outline
                        Container(
                          height: Responsive.h(90),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(Responsive.w(20)),
                            border: Border.all(
                              color: AppColors.outliner,
                              width: Responsive.w(1.5),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CustomPaint(
                            painter: MapPainter(),
                          ),
                        ),
                        SizedBox(height: Responsive.h(16)),

                        // Directions button
                        CommonDirectionsButton(
                          title: 'Road Damage Location',
                          address: 'HSR Layout, Bengaluru, Karnataka',
                          style: DirectionsButtonStyle.wide,
                        ),
                        SizedBox(height: Responsive.h(16)),

                        // Divider
                        Divider(
                          color: AppColors.outliner,
                          height: 1,
                          thickness: Responsive.w(1.2),
                        ),
                        SizedBox(height: Responsive.h(12)),

                        // Bottom toolbar reactions (left and right ends)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.thumb_up_alt_outlined,
                                  color: AppColors.black,
                                  size: Responsive.w(20),
                                ),
                                SizedBox(width: Responsive.w(6)),
                                CustomText.title(
                                  '0',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_outlined,
                                  color: AppColors.black,
                                  size: Responsive.w(20),
                                ),
                                SizedBox(width: Responsive.w(6)),
                                CustomText.title(
                                  '1',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),

                  // 3. Comments heading
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Responsive.w(4)),
                    child: CustomText.header(
                      'Comments',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: Responsive.h(12)),

                  // 4. BBMP Comment card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Responsive.w(16)),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(Responsive.w(24)),
                      border: Border.all(
                        color: AppColors.outliner,
                        width: Responsive.w(1.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: Responsive.w(42),
                              height: Responsive.w(42),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5F5F5),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.grayFont,
                                  size: Responsive.w(24),
                                ),
                              ),
                            ),
                            SizedBox(width: Responsive.w(12)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText.title(
                                  'BBMP( M Corp)',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                CustomText.subtitle(
                                  '5 days ago',
                                  fontSize: 11,
                                  color: AppColors.grayFont,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.h(12)),
                        CustomText.body(
                          'We are start the work...',
                          color: const Color(0xFF333333),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.h(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
