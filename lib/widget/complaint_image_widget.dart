import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

/// Universal widget that renders complaint images from:
/// 1. Firebase Cloud Storage (https://...)
/// 2. Base64 data URI (data:image/...;base64,...)
/// 3. Local filesystem cache (/data/user/0/... or File path)
/// 4. App asset bundle (assets/...)
/// 5. Graceful fallback to default civic complaint illustration
class ComplaintImageWidget extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ComplaintImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  Widget _buildFallback() {
    return Image.asset(
      'assets/images/report1.png',
      fit: fit,
      width: width,
      height: height,
    );
  }

  Widget _buildImageContent() {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) {
      return _buildFallback();
    }

    // 1. Firebase Storage or Remote Network URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            width: width,
            height: height,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // 2. Base64 Data URI
    if (path.startsWith('data:image') || path.contains(';base64,')) {
      try {
        final commaIndex = path.indexOf(',');
        final base64String = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
        final bytes = base64Decode(base64String.trim());
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } catch (_) {
        return _buildFallback();
      }
    }

    // 3. Asset path
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }

    // 4. Local device file path
    try {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
    } catch (_) {}

    // Fallback default
    return _buildFallback();
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImageContent();
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
