import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary branding colors matching GoGovernment ecosystem
  static const Color primary = Color(0xFFF3410B); // Primary Orange-Red
  static const Color outliner = Color(0xFFFFA88E); // Warm peach outline / gradient
  static const Color screenColor = Color(0xFFFFF8F5); // Warm cream screen background
  
  // Neutral colors
  static const Color black = Color(0xFF1E1E1E); // Black font/headings
  static const Color white = Color(0xFFFFFFFF); // White card background
  static const Color lightGray = Color(0xFFF5F5F5); // Light gray
  static const Color grayFont = Color(0xFF7A7A7A); // Gray font
  static const Color border = Color(0xFFE8E8E8); // Border line
  
  // Feedback & Status
  static const Color success = Color(0xFF4CAF50); // Active duty / delivered
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA000); // Pending pickup
  static const Color info = Color(0xFF2196F3); // Out for delivery
}
