import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AuthApiService {
  // 1. Send OTP
  static Future<Map<String, dynamic>?> sendOtp(String phone) async {
    final candidateHosts = ApiClient.candidateHosts;

    for (final host in candidateHosts) {
      final url = '$host/auth/send-otp';
      final payload = jsonEncode({'phone': phone});

      try {
        ApiClient.logRequest('POST', url, body: payload);

        final response = await http
            .post(
              Uri.parse(url),
              headers: ApiClient.defaultHeaders,
              body: payload,
            )
            .timeout(const Duration(seconds: 5));

        ApiClient.logResponse('POST', url, response.statusCode, response.body);

        if (response.statusCode == 200) {
          ApiClient.setBaseUrl(host);
          return jsonDecode(response.body);
        }
      } catch (e) {
        ApiClient.logError('POST', url, e);
      }
    }
    return null;
  }

  // 2. Verify OTP
  static Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    final url = '${ApiClient.baseUrl}/auth/verify-otp';
    final payload = jsonEncode({'phone': phone, 'otp': otp});

    try {
      ApiClient.logRequest('POST', url, body: payload);

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiClient.defaultHeaders,
            body: payload,
          )
          .timeout(const Duration(seconds: 8));

      ApiClient.logResponse('POST', url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      ApiClient.logError('POST', url, e);
    }
    return null;
  }

  // 3. Update Profile
  static Future<bool> updateProfile({
    required String userId,
    required String userName,
    required String email,
    String? profileImage,
  }) async {
    final url = '${ApiClient.baseUrl}/auth/profile';
    final payload = jsonEncode({
      'userId': userId,
      'userName': userName,
      'email': email,
      if (profileImage != null) 'profileImage': profileImage,
    });

    try {
      ApiClient.logRequest('POST', url, body: payload);

      final response = await http
          .post(
            Uri.parse(url),
            headers: ApiClient.defaultHeaders,
            body: payload,
          )
          .timeout(const Duration(seconds: 8));

      ApiClient.logResponse('POST', url, response.statusCode, response.body);
      return response.statusCode == 200;
    } catch (e) {
      ApiClient.logError('POST', url, e);
      return false;
    }
  }

  // 4. Upload Profile Image
  static Future<String?> uploadProfileImage(String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      ApiClient.logError('UPLOAD', localPath, 'File does not exist locally');
      return localPath;
    }

    final url = '${ApiClient.baseUrl}/upload/profile';
    try {
      ApiClient.logRequest('MULTIPART POST', url, body: 'File: $localPath');

      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      ApiClient.logResponse('MULTIPART POST', url, response.statusCode, response.body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }
    } catch (e) {
      ApiClient.logError('MULTIPART POST', url, e);
    }
    return localPath;
  }
}
