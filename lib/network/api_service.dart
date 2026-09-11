import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../hive/hive_service.dart';

class ApiService {
  static String? _resolvedBaseUrl;

  static String get defaultBaseUrl {
    return 'http://127.0.0.1:5000/api';
  }

  static String get baseUrl => _resolvedBaseUrl ?? defaultBaseUrl;

  static void setBaseUrl(String url) {
    _resolvedBaseUrl = url;
  }

  // 1. Upload Image (Multipart) to Node.js Backend
  static Future<String?> uploadComplaintImage(String localPath, String complaintId) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) {
        debugPrint('[ApiService] Local image does not exist: $localPath');
        return localPath;
      }

      final uri = Uri.parse('$baseUrl/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String?;
        debugPrint('[ApiService] Image uploaded successfully: $imageUrl');
        return imageUrl;
      } else {
        debugPrint('[ApiService] Image upload failed (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] uploadComplaintImage error: $e');
    }
    return localPath;
  }

  // 2. Submit Complaint to MongoDB via Node.js
  static Future<void> submitComplaint(Map<String, dynamic> complaint) async {
    try {
      final dataToSend = Map<String, dynamic>.from(complaint);
      dataToSend['userId'] = HiveService.citizenId;
      dataToSend['complaintId'] = complaint['complaintId'] ?? complaint['id'] ?? ('CMP${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');
      dataToSend.remove('id');
      dataToSend.remove('citizenId');

      final uri = Uri.parse('$baseUrl/complaints');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dataToSend),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ApiService] Successfully submitted complaint to Node.js backend!');
      } else {
        debugPrint('[ApiService] Failed to submit complaint (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[ApiService] submitComplaint error: $e');
    }
  }

  // 3. Fetch All Complaints
  static Future<List<Map<String, dynamic>>> fetchComplaints() async {
    try {
      final uri = Uri.parse('$baseUrl/complaints');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] fetchComplaints error: $e');
    }
    return [];
  }

  // 3b. Fetch User-Specific Complaints ("My Activity")
  static Future<List<Map<String, dynamic>>> fetchMyComplaints([String? userId]) async {
    try {
      final uid = userId ?? HiveService.citizenId;
      final uri = Uri.parse('$baseUrl/complaints/user/$uid');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    } catch (e) {
      debugPrint('[ApiService] fetchMyComplaints error: $e');
    }
    return [];
  }

  // 4. Stream Complaints (Auto-refreshes periodically to mimic real-time stream)
  static Stream<List<Map<String, dynamic>>> streamAllComplaints({Duration interval = const Duration(seconds: 4)}) async* {
    while (true) {
      final complaints = await fetchComplaints();
      if (complaints.isNotEmpty) {
        yield complaints;
      }
      await Future.delayed(interval);
    }
  }

  // 5. Toggle Like
  static Future<void> toggleLike(String complaintId, bool isCurrentlyLiked) async {
    try {
      final uri = Uri.parse('$baseUrl/complaints/$complaintId/like');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'citizenId': HiveService.citizenId,
          'isCurrentlyLiked': isCurrentlyLiked,
        }),
      );
    } catch (e) {
      debugPrint('[ApiService] toggleLike error: $e');
    }
  }

  // 6. Add Comment
  static Future<void> addComment(String complaintId, String comment, String userName) async {
    try {
      final uri = Uri.parse('$baseUrl/complaints/$complaintId/comment');
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'citizenId': HiveService.citizenId,
          'userName': userName,
          'comment': comment,
        }),
      );
    } catch (e) {
      debugPrint('[ApiService] addComment error: $e');
    }
  }

  // 7. Send OTP
  static Future<Map<String, dynamic>?> sendOtp(String phone) async {
    final candidateHosts = [
      'http://127.0.0.1:5000/api',
      'http://192.168.1.10:5000/api',
      if (!kIsWeb && Platform.isAndroid) 'http://10.0.2.2:5000/api',
    ];

    for (final host in candidateHosts) {
      try {
        debugPrint('[ApiService] Trying send-otp at: $host/auth/send-otp');
        final response = await http
            .post(
              Uri.parse('$host/auth/send-otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'phone': phone}),
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          _resolvedBaseUrl = host;
          debugPrint('[ApiService] Connected successfully via: $host');
          return jsonDecode(response.body);
        }
      } catch (e) {
        debugPrint('[ApiService] Could not reach $host: $e');
      }
    }
    return null;
  }

  // 8. Verify OTP
  static Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('[ApiService] verifyOtp error: $e');
    }
    return null;
  }

  // 9. Update Profile
  static Future<bool> updateProfile({
    required String userId,
    required String userName,
    required String email,
    String? profileImage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'userName': userName,
          'email': email,
          if (profileImage != null) 'profileImage': profileImage,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[ApiService] updateProfile error: $e');
      return false;
    }
  }

  // 10. Upload Profile Image
  static Future<String?> uploadProfileImage(String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return localPath;

      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/profile'));
      request.files.add(await http.MultipartFile.fromPath('image', localPath));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'] as String?;
      }
    } catch (e) {
      debugPrint('[ApiService] uploadProfileImage error: $e');
    }
    return localPath;
  }
}
