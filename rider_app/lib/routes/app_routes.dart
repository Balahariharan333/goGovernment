import 'package:flutter/material.dart';
import '../constants/route_constants.dart';
import '../hive/hive_service.dart';
import '../model/delivery_order_model.dart';
import '../screen/auth/rider_login_screen.dart';
import '../screen/auth/rider_otp_screen.dart';
import '../screen/auth/rider_profile_screen.dart';
import '../screen/delivery/active_delivery_screen.dart';
import '../screen/earnings/rider_earnings_screen.dart';
import '../screen/home/rider_dashboard_screen.dart';
import '../screen/profile/rider_profile_view_screen.dart';

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        final bool loggedIn = HiveService.isLoggedIn;
        return MaterialPageRoute(
          builder: (_) => loggedIn ? const RiderDashboardScreen() : const RiderLoginScreen(),
        );

      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const RiderLoginScreen());

      case RouteConstants.otp:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => RiderOtpScreen(
            phone: args['phone']?.toString() ?? '',
            initialOtp: args['otp']?.toString(),
          ),
        );

      case RouteConstants.profileSetup:
        return MaterialPageRoute(builder: (_) => const RiderProfileScreen());

      case RouteConstants.dashboard:
        return MaterialPageRoute(builder: (_) => const RiderDashboardScreen());

      case RouteConstants.activeDelivery:
        final order = settings.arguments as DeliveryOrder;
        return MaterialPageRoute(builder: (_) => ActiveDeliveryScreen(order: order));

      case RouteConstants.earnings:
        return MaterialPageRoute(builder: (_) => const RiderEarningsScreen());

      case RouteConstants.profile:
        return MaterialPageRoute(builder: (_) => const RiderProfileViewScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
