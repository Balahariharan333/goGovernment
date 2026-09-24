import 'package:flutter/material.dart';
import '../constants/route_constants.dart';
import '../utils/app_colors.dart';
import '../utils/responsive_helper.dart';

class RiderBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const RiderBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteConstants.dashboard,
          (route) => false,
        );
        break;
      case 1:
        if (currentIndex == 0) {
          Navigator.pushNamed(context, RouteConstants.earnings);
        } else {
          Navigator.pushReplacementNamed(context, RouteConstants.earnings);
        }
        break;
      case 2:
        if (currentIndex == 0) {
          Navigator.pushNamed(context, RouteConstants.profile);
        } else {
          Navigator.pushReplacementNamed(context, RouteConstants.profile);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Responsive.h(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                index: 0,
                icon: Icons.dashboard_rounded,
                label: 'Deliveries',
              ),
              _buildNavItem(
                context: context,
                index: 1,
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
              ),
              _buildNavItem(
                context: context,
                index: 2,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    IconData? activeIcon,
    required String label,
  }) {
    final bool isActive = currentIndex == index;
    final Color color = isActive ? AppColors.primary : AppColors.grayFont;

    return InkWell(
      onTap: () => _onTap(context, index),
      borderRadius: BorderRadius.circular(Responsive.w(12)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.w(16),
          vertical: Responsive.h(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? (activeIcon ?? icon) : icon,
              color: color,
              size: 24,
            ),
            SizedBox(height: Responsive.h(3)),
            Text(
              label,
              style: TextStyle(
                fontSize: Responsive.sp(11),
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
