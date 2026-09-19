import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CommonBackground extends StatelessWidget {
  final Widget child;

  const CommonBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF0EB), // Subtle warm peach-orange top
            AppColors.screenColor, // Cream white base
          ],
          stops: [0.0, 0.3],
        ),
      ),
      child: child,
    );
  }
}
