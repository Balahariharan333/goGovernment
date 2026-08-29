import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widget/common_background.dart';
import '../../widget/custom_bottom_bar.dart';
import '../complaint/complaint_screen.dart';
import '../report/report_screen.dart';
import 'home_tab.dart';
import '../transaction/transaction_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Default to 2 (Home, which is the center storefront icon)

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColors.screenColor,
      body: CommonBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Independent scroll-state wrappers via IndexedStack
              IndexedStack(
                index: _currentIndex,
                children: [
                  _buildTabWrapper(const ComplaintScreen()),
                  _buildTabWrapper(const ReportScreen()),
                  _buildTabWrapper(const HomeTab()),
                  _buildTabWrapper(const TransactionScreen()),
                  _buildTabWrapper(const ProfileScreen(), isScrollable: false),
                ],
              ),

              // 5. Floating Bottom Navigation Bar
              Positioned(
                bottom: Responsive.h(24),
                left: Responsive.w(16),
                right: Responsive.w(16),
                child: CustomBottomBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabWrapper(Widget child, {bool isScrollable = true}) {
    final Widget content = Padding(
      padding: EdgeInsets.only(
        left: Responsive.w(20.0),
        right: Responsive.w(20.0),
        top: Responsive.h(16.0),
        bottom: Responsive.h(120.0), // Space for floating bottom bar
      ),
      child: child,
    );

    if (!isScrollable) {
      return content;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: content,
    );
  }
}
