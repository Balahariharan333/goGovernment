import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CustomText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const CustomText._({
    super.key,
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  factory CustomText.header(
    String text, {
    Key? key,
    Color color = AppColors.black,
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.bold,
    double? height,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CustomText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  factory CustomText.title(
    String text, {
    Key? key,
    Color color = AppColors.black,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
    double? height,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CustomText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  factory CustomText.subtitle(
    String text, {
    Key? key,
    Color color = AppColors.grayFont,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CustomText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  factory CustomText.body(
    String text, {
    Key? key,
    Color color = AppColors.black,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CustomText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  factory CustomText.caption(
    String text, {
    Key? key,
    Color color = AppColors.grayFont,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.normal,
    double? height,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CustomText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: style,
    );
  }
}
