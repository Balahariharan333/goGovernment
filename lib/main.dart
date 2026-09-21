import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_government/bloc/coupon/coupon_bloc.dart';
import 'package:go_government/bloc/direction/direction_bloc.dart';
import 'package:go_government/bloc/product/product_bloc.dart';
import 'utils/app_theme.dart';
import 'utils/responsive_helper.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/cart/cart_bloc.dart';
import 'bloc/toilet/toilet_bloc.dart';
import 'bloc/bus_stop/bus_stop_bloc.dart';
import 'bloc/profile/profile_bloc.dart';
import 'bloc/report/report_bloc.dart';
import 'bloc/feedback/feedback_bloc.dart';
import 'bloc/transaction/transaction_bloc.dart';
import 'bloc/complaint/complaint_bloc.dart';
import 'bloc/order_tracking/order_tracking_bloc.dart';
import 'bloc/rider_chat/rider_chat_bloc.dart';
import 'bloc/address/address_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'services/notification_service.dart';
import 'services/translation_service.dart';
import 'service/socket_service.dart';
import 'hive/hive_service.dart';
import 'constants/route_constants.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local notifications (for OTP test alerts without Firebase)
  await NotificationService.initialize();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('[Main] Firebase initialized successfully');
  } catch (e) {
    debugPrint('[Main] Firebase initialization error: $e');
  }

  await HiveService.init();
  TranslationService.init();

  // Initialize real-time WebSocket connection to backend
  SocketService().init();


  // If citizen is logged in, registered, and device GPS permission is already active (granted in-app or in OS settings),
  // ensure hasSeenPermissionScreen is marked true so the permission screen is never shown on restart!
  if (HiveService.isLoggedIn && HiveService.userName.trim().isNotEmpty && !HiveService.hasSeenPermissionScreen) {
    try {
      final locStatus = await Permission.location.status;
      if (locStatus.isGranted) {
        await HiveService.setHasSeenPermissionScreen(true);
      }
    } catch (e) {
      debugPrint('[Main] Location permission startup check: $e');
    }
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => AuthBloc()),
        BlocProvider<CartBloc>.value(value: CartBloc.instance),
        BlocProvider<ToiletBloc>(create: (context) => ToiletBloc()),
        BlocProvider<BusStopBloc>(create: (context) => BusStopBloc()),
        BlocProvider<ProfileBloc>.value(value: ProfileBloc.instance),
        BlocProvider<ReportBloc>(create: (context) => ReportBloc()),
        BlocProvider<FeedbackBloc>(create: (context) => FeedbackBloc()),
        BlocProvider<TransactionBloc>.value(value: TransactionBloc.instance),
        BlocProvider<ComplaintBloc>(create: (context) => ComplaintBloc()),
        BlocProvider<OrderTrackingBloc>(create: (context) => OrderTrackingBloc()),
        BlocProvider<RiderChatBloc>(create: (context) => RiderChatBloc()),
        BlocProvider<AddressBloc>(create: (context) => AddressBloc()),
          BlocProvider<CouponBloc>(create: (context) => CouponBloc()),
          BlocProvider<DirectionBloc>(create: (context) => DirectionBloc()),
          BlocProvider<ProductBloc>(create: (context) => ProductBloc()),
          ],
      child: MaterialApp(
        title: 'GoGovernment',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          Responsive.init(context);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
            child: child!,
          );
        },
        initialRoute: RouteConstants.initial,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
