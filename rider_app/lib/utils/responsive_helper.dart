import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
  }

  // Scale based on design width 375
  static double w(double width) {
    return (width / 375.0) * screenWidth;
  }

  // Scale based on design height 812
  static double h(double height) {
    return (height / 812.0) * screenHeight;
  }

  // Font scale helper
  static double sp(double fontSize) {
    return (fontSize / 375.0) * screenWidth;
  }
}
