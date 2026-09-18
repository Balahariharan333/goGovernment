class HiveBoxes {
  static const String auth = 'store_auth_box';
  static const String store = 'store_data_box';
  static const String settings = 'store_settings_box';
}

class HiveKeys {
  // Auth & Profile
  static const String isLoggedIn = 'is_logged_in';
  static const String userPhone = 'user_phone';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userName = 'user_name';

  // Store Specific
  static const String storeId = 'store_id';
  static const String storeStatus = 'store_status';
  static const String storeData = 'store_cached_data';
}
