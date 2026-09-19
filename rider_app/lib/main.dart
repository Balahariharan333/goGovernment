import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/rider_auth_bloc.dart';
import 'bloc/delivery/delivery_bloc.dart';
import 'constants/route_constants.dart';
import 'hive/hive_service.dart';
import 'network/rider_api_service.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize Hive
  await HiveService.init();

  // Initialize Local Notifications
  await NotificationService.initialize();

  // Auto-resolve backend Wi-Fi IP
  RiderApiService.resolveBaseUrl();

  runApp(const GoGovernmentRiderApp());
}

class GoGovernmentRiderApp extends StatelessWidget {
  const GoGovernmentRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RiderAuthBloc>(
          create: (_) => RiderAuthBloc.instance,
        ),
        BlocProvider<DeliveryBloc>(
          create: (_) => DeliveryBloc.instance,
        ),
      ],
      child: MaterialApp(
        title: 'GoGovernment Delivery Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: RouteConstants.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
