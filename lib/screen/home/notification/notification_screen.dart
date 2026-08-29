import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/responsive_helper.dart';
import '../../../widget/common_background.dart';
import '../../../widget/custom_text.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

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
          'Notifications',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.black,
        ),
        centerTitle: false,
      ),
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.w(20),
              vertical: Responsive.h(10),
            ),
            children: [
              _buildNotificationItem(
                messageWidget: CustomText.body(
                  "Welcome to the app! We're happy to have you with us.",
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: AppColors.black,
                  height: 1.4,
                ),
                timestamp: "• 20/01/2026 - 10:01 pm",
              ),
              SizedBox(height: Responsive.h(16)),
              _buildNotificationItem(
                messageWidget: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: Responsive.sp(14),
                      color: AppColors.black,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: "Your complaint has been successfully registered.\n\n",
                      ),
                      const TextSpan(
                        text: "Reference ID: ",
                      ),
                      TextSpan(
                        text: "#45821.",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                timestamp: "• 20/01/2026 - 10:01 pm",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required Widget messageWidget,
    required String timestamp,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.w(20),
            vertical: Responsive.h(18),
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(Responsive.w(20)),
          ),
          child: messageWidget,
        ),
        SizedBox(height: Responsive.h(8)),
        Padding(
          padding: EdgeInsets.only(right: Responsive.w(16)),
          child: CustomText.subtitle(
            timestamp,
            fontSize: 11,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
