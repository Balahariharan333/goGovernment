import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/store/store_bloc.dart';
import 'constants/route_constants.dart';
import 'hive/hive_service.dart';
import 'routes/app_router.dart';
import 'services/notification_service.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Local Storage (Hive)
  await HiveService.init();

  // 2. Initialize Push Notifications for SMS OTPs
  await NotificationService.initialize();

  // 3. System UI Overlay & Orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const StoreApp());
}

class StoreApp extends StatelessWidget {
  const StoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
        BlocProvider<StoreBloc>(create: (_) => StoreBloc()),
      ],
      child: MaterialApp(
        title: 'GoGovernment Store Partner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: RouteConstants.initial,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
