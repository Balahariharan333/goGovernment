import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../network/api_client.dart';

/// Universal widget that renders complaint images from:
/// 1. Remote Network URL / Node.js Backend uploads (http://...)
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

  // In-memory cache to prevent decoding base64 repeatedly and causing image flickering
  static final Map<String, Uint8List> _base64Cache = {};

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
      gaplessPlayback: true,
    );
  }

  Widget _buildImageContent() {
    final raw = imagePath?.trim();
    if (raw == null || raw.isEmpty) {
      return _buildFallback();
    }

    final path = ApiClient.normalizeImageUrl(raw);

    // 1. Remote Network URL (Node backend /uploads/ or cloud storage)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: fit,
        width: width,
        height: height,
        gaplessPlayback: true,
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
        Uint8List? bytes = _base64Cache[path];
        if (bytes == null) {
          final commaIndex = path.indexOf(',');
          final base64String = commaIndex != -1 ? path.substring(commaIndex + 1) : path;
          bytes = base64Decode(base64String.trim());
          if (_base64Cache.length > 80) {
            _base64Cache.remove(_base64Cache.keys.first);
          }
          _base64Cache[path] = bytes;
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
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
        gaplessPlayback: true,
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
          gaplessPlayback: true,
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
