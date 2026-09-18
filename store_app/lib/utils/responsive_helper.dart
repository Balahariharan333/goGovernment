import 'package:flutter/material.dart';

class Responsive {
  static double screenWidth = _designWidth;
  static double screenHeight = _designHeight;

  static const double _designWidth = 390.0;
  static const double _designHeight = 844.0;

  static void init(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }

  static double w(double width) {
    return (width / _designWidth) * screenWidth;
  }

  static double h(double height) {
    return (height / _designHeight) * screenHeight;
  }

  static double sp(double fontSize) {
    return (fontSize / _designWidth) * screenWidth;
  }
}
