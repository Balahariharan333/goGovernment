import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiClient {
  static String? _resolvedBaseUrl;

  static String get defaultBaseUrl => 'http://192.168.1.10:5000/api';

  static String get baseUrl => _resolvedBaseUrl ?? defaultBaseUrl;

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url;
    debugPrint('🔄 [ApiClient] Base URL updated to: $url');
  }

  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
  };

  static List<String> get candidateHosts => [
    'http://192.168.1.10:5000/api',
    'http://127.0.0.1:5000/api',
    if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:5000/api',
  ];

  /// Normalizes image URLs so localhost/127.0.0.1 URLs from the database
  /// resolve to the currently reachable backend baseUrl (e.g. 192.168.1.10:5000)
  static String normalizeImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://127.0.0.1:5000') ||
        trimmed.startsWith('http://localhost:5000') ||
        trimmed.startsWith('http://10.0.2.2:5000')) {
      final serverOrigin = baseUrl.replaceAll('/api', '');
      return trimmed.replaceFirst(
        RegExp(r'^http:\/\/(127\.0\.0\.1|localhost|10\.0\.2\.2):5000'),
        serverOrigin,
      );
    }
    return trimmed;
  }

  // ================= DEBUG LOGGER ================= //
  static void logRequest(String method, String url, {dynamic body}) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🌐 [API REQUEST] $method $url');
    if (body != null) {
      debugPrint('📦 Body: $body');
    }
  }

  static void logResponse(String method, String url, int statusCode, String responseBody) {
    final emoji = (statusCode >= 200 && statusCode < 300) ? '✅' : '⚠️';
    debugPrint('$emoji [API RESPONSE] [$statusCode] $method $url');
    debugPrint('📄 Response Body: $responseBody');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void logError(String method, String url, dynamic error) {
    debugPrint('❌ [API ERROR] $method $url');
    debugPrint('💥 Exception: $error');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
