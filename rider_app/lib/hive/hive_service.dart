import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

class HiveService {
  static late Box _authBox;
  static late Box _dutyBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(HiveBoxes.auth);
    _dutyBox = await Hive.openBox(HiveBoxes.duty);
  }

  // ----------------------------------------------------
  // Auth Profile
  // ----------------------------------------------------
  static bool get isLoggedIn =>
      _authBox.get(HiveKeys.isLoggedIn, defaultValue: false) as bool;

  static bool get isProfileCompleted =>
      userName.trim().isNotEmpty && vehicleNumber.trim().isNotEmpty;

  static Future<void> setLoggedIn(bool value) async {
    await _authBox.put(HiveKeys.isLoggedIn, value);
  }

  static String get userPhone =>
      _authBox.get(HiveKeys.userPhone, defaultValue: '') as String;

  static Future<void> setUserPhone(String phone) async {
    await _authBox.put(HiveKeys.userPhone, phone);
  }

  static String get userId =>
      _authBox.get(HiveKeys.userId, defaultValue: '') as String;

  static Future<void> setUserId(String id) async {
    await _authBox.put(HiveKeys.userId, id);
  }

  static String get userName =>
      _authBox.get(HiveKeys.userName, defaultValue: '') as String;

  static Future<void> setUserName(String name) async {
    await _authBox.put(HiveKeys.userName, name);
  }

  static String get vehicleType =>
      _authBox.get(HiveKeys.vehicleType, defaultValue: 'Motorcycle') as String;

  static Future<void> setVehicleType(String type) async {
    await _authBox.put(HiveKeys.vehicleType, type);
  }

  static String get vehicleNumber =>
      _authBox.get(HiveKeys.vehicleNumber, defaultValue: '') as String;

  static Future<void> setVehicleNumber(String num) async {
    await _authBox.put(HiveKeys.vehicleNumber, num);
  }

  // ----------------------------------------------------
  // Duty & Work Metrics
  // ----------------------------------------------------
  static bool get isOnline =>
      _dutyBox.get(HiveKeys.isOnline, defaultValue: false) as bool;

  static Future<void> setIsOnline(bool online) async {
    await _dutyBox.put(HiveKeys.isOnline, online);
  }

  static double get totalEarnings =>
      (_dutyBox.get(HiveKeys.totalEarnings, defaultValue: 0.0) as num).toDouble();

  static Future<void> addEarnings(double amount) async {
    final current = totalEarnings;
    await _dutyBox.put(HiveKeys.totalEarnings, current + amount);
  }

  static Future<void> setTotalEarnings(double amount) async {
    await _dutyBox.put(HiveKeys.totalEarnings, amount);
  }

  static int get completedCount =>
      _dutyBox.get(HiveKeys.completedCount, defaultValue: 0) as int;

  static Future<void> incrementCompletedCount() async {
    final current = completedCount;
    await _dutyBox.put(HiveKeys.completedCount, current + 1);
  }

  static Future<void> setCompletedCount(int count) async {
    await _dutyBox.put(HiveKeys.completedCount, count);
  }

  // ----------------------------------------------------
  // Battery Optimization Prompt Flag
  // ----------------------------------------------------
  static bool get hasRequestedBatteryOptimization =>
      _authBox.get('hasRequestedBatteryOptimization', defaultValue: false) as bool;

  static Future<void> setRequestedBatteryOptimization(bool val) async {
    await _authBox.put('hasRequestedBatteryOptimization', val);
  }

  // ----------------------------------------------------
  // Clear Session
  // ----------------------------------------------------
  static Future<void> clearAuth() async {
    await _authBox.clear();
    await _dutyBox.clear();
  }
}
