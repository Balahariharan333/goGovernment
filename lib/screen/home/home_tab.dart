import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/custom_text.dart';
import 'notification/notification_screen.dart';
import 'feedback/feedback_survey_screen.dart';
import 'toilet/near_toilet_screen.dart';
import 'bus_stop/near_bus_stop_screen.dart';
import 'stores/near_stores_screen.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Custom Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText.header(
                    'Good Morning, Ramesha..',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: Responsive.h(4)),
                  CustomText.subtitle(
                    'Here are today\'s actions for you',
                    fontSize: 14,
                    color: AppColors.grayFont,
                  ),
                ],
              ),
            ),
            SizedBox(width: Responsive.w(12)),
            _buildNotificationBell(context),
          ],
        ),
        SizedBox(height: Responsive.h(24)),

        // 2. Action Grid (2x2)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: Responsive.w(16),
          mainAxisSpacing: Responsive.w(16),
          childAspectRatio: 1.2,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackSurveyScreen(),
                  ),
                );
              },
              child: _buildActionCard(
                imagePath: 'assets/images/feedback.png',
                label: 'Near Feedback',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearStoresScreen(),
                  ),
                );
              },
              child: _buildActionCard(
                imagePath: 'assets/images/stores.png',
                label: 'Near Stores',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearBusStopScreen(),
                  ),
                );
              },
              child: _buildActionCard(
                imagePath: 'assets/images/Bus.png',
                label: 'Near Bus Stop',
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearToiletScreen(),
                  ),
                );
              },
              child: _buildActionCard(
                imagePath: 'assets/images/toilet.png',
                label: 'Near Toilet',
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.h(28)),

        // 3. Complaint Section Heading
        CustomText.header(
          'Road Damage',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: Responsive.h(4)),
        CustomText.subtitle(
          'ID: wertyu98765',
          fontSize: 13,
          color: AppColors.grayFont,
        ),
        SizedBox(height: Responsive.h(16)),

        // 4. Detail Info Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Responsive.w(28)),
            border: Border.all(
              color: AppColors.outliner,
              width: Responsive.w(1.5),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(16),
            vertical: Responsive.h(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text box container (grey bubble)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(Responsive.w(16)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.w(16),
                  vertical: Responsive.h(14),
                ),
                child: CustomText.body(
                  'The road is completely damaged and it is difficult for us to ride our vehicles safely. Kindly repair the road and resolve this issue as soon as possible.',
                  color: const Color(0xFF4A4A4A),
                  height: 1.35,
                ),
              ),
              SizedBox(height: Responsive.h(14)),
              // Location detail row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: Responsive.w(42),
                    height: Responsive.h(42),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF2EC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: Responsive.w(20),
                    ),
                  ),
                  SizedBox(width: Responsive.w(12)),
                  Expanded(
                    child: CustomText.subtitle(
                      '552, 2nd Floor 16th Main, 15th Cross Rd, 4th Sector, HSR Layout, Bengaluru, Karnataka 560102',
                      fontSize: 13,
                      color: const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.h(14)),
              // View Status & Overlapping Floating Button
              Stack(
                alignment: Alignment.centerLeft,
                clipBehavior: Clip.none,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.86,
                    child: Container(
                      height: Responsive.h(52),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(26)),
                        border: Border.all(
                          color: AppColors.primary,
                          width: Responsive.w(1.5),
                        ),
                      ),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(Responsive.w(26)),
                        child: Center(
                          child: CustomText.title(
                            'View Status',
                            color: AppColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: Container(
                      width: Responsive.w(54),
                      height: Responsive.h(54),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(Responsive.w(20)),
                        border: Border.all(
                          color: AppColors.primary,
                          width: Responsive.w(1.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: Responsive.w(8),
                            offset: Offset(0, Responsive.h(4)),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: AppColors.primary,
                        size: Responsive.w(32),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationScreen(),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(Responsive.w(10)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(Responsive.w(14)),
          border: Border.all(
            color: AppColors.outliner,
            width: Responsive.w(1.5),
          ),
        ),
        child: Icon(
          Icons.notifications_outlined,
          color: AppColors.black,
          size: Responsive.w(26),
        ),
      ),
    );
  }

  Widget _buildActionCard({required String imagePath, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Responsive.w(28)),
        border: Border.all(color: AppColors.outliner, width: Responsive.w(1.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: Responsive.w(40),
            height: Responsive.w(40),
            fit: BoxFit.contain,
          ),
          SizedBox(height: Responsive.h(12)),
          CustomText.title(
            label,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ],
      ),
    );
  }
}
