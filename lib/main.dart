import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_government/bloc/coupon/coupon_bloc.dart';
import 'package:go_government/bloc/direction/direction_bloc.dart';
import 'package:go_government/bloc/product/product_bloc.dart';
import 'utils/app_theme.dart';
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

import 'hive/hive_service.dart';
import 'constants/route_constants.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
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
        BlocProvider<TransactionBloc>(create: (context) => TransactionBloc()),
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
