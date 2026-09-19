import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class StoreOrderApiService {
  // Fetch all orders for this store
  static Future<List<Map<String, dynamic>>> fetchStoreOrders(String storeId) async {
    if (storeId.isEmpty) return [];
    final url = '${ApiClient.baseUrl}/orders/store/$storeId';
    ApiClient.logRequest('GET', url);

    try {
      final response = await http
          .get(Uri.parse(url), headers: ApiClient.defaultHeaders)
          .timeout(const Duration(seconds: 10));

      ApiClient.logResponse('GET', url, response.statusCode, response.body);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['data'] as List? ?? [];
        return list.map((i) => Map<String, dynamic>.from(i)).toList();
      }
      return [];
    } catch (e) {
      ApiClient.logError('GET', url, e);
      return [];
    }
  }

  // Update order status (e.g. preparing, ready_for_pickup)
  static Future<bool> updateOrderStatus({
    required String orderId,
    required String status,
    String? note,
  }) async {
    final url = '${ApiClient.baseUrl}/orders/$orderId/status';
    final body = {
      'status': status,
      if (note != null) 'note': note,
    };
    ApiClient.logRequest('PATCH', url, body: body);

    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: ApiClient.defaultHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      ApiClient.logResponse('PATCH', url, response.statusCode, response.body);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      ApiClient.logError('PATCH', url, e);
      return false;
    }
  }
}
