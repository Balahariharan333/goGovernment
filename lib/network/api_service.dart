export 'api_client.dart';
export 'auth_api_service.dart';
export 'complaint_api_service.dart';

import 'api_client.dart';
import 'auth_api_service.dart';
import 'complaint_api_service.dart';

/// Facade for backward compatibility.
/// You can also use [AuthApiService] and [ComplaintApiService] directly.
class ApiService {
  static String get baseUrl => ApiClient.baseUrl;
  static String get defaultBaseUrl => ApiClient.defaultBaseUrl;
  static void setBaseUrl(String url) => ApiClient.setBaseUrl(url);

  // Auth & Profile
  static Future<Map<String, dynamic>?> sendOtp(String phone) =>
      AuthApiService.sendOtp(phone);

  static Future<Map<String, dynamic>?> verifyOtp(String phone, String otp) =>
      AuthApiService.verifyOtp(phone, otp);

  static Future<bool> updateProfile({
    required String userId,
    required String userName,
    required String email,
    String? profileImage,
  }) =>
      AuthApiService.updateProfile(
        userId: userId,
        userName: userName,
        email: email,
        profileImage: profileImage,
      );

  static Future<String?> uploadProfileImage(String localPath) =>
      AuthApiService.uploadProfileImage(localPath);

  // Complaints
  static Future<String?> uploadComplaintImage(String localPath, String complaintId) =>
      ComplaintApiService.uploadComplaintImage(localPath, complaintId);

  static Future<void> submitComplaint(Map<String, dynamic> complaint) =>
      ComplaintApiService.submitComplaint(complaint);

  static Future<List<Map<String, dynamic>>> fetchComplaints() =>
      ComplaintApiService.fetchComplaints();

  static Future<List<Map<String, dynamic>>> fetchMyComplaints([String? userId]) =>
      ComplaintApiService.fetchMyComplaints(userId);

  static Stream<List<Map<String, dynamic>>> streamAllComplaints({
    Duration interval = const Duration(seconds: 4),
  }) =>
      ComplaintApiService.streamAllComplaints(interval: interval);

  static Future<void> toggleLike(String complaintId, bool isCurrentlyLiked) =>
      ComplaintApiService.toggleLike(complaintId, isCurrentlyLiked);

  static Future<void> addComment(String complaintId, String comment, String userName) =>
      ComplaintApiService.addComment(complaintId, comment, userName);
}
