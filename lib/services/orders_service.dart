import 'api_client.dart';

class OrdersService {
  OrdersService(this._api);
  final ApiClient _api;

  // Get orders by buyer with pagination
  Future<Map<String, dynamic>> getOrdersByBuyer(
    String buyerId, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _api.get(
        '/api/orders/buyer/$buyerId',
        query: {
          'page': page.toString(),
          'size': size.toString(),
        },
      );

      // Backend returns ApiResponse<Page<OrderResponse>>
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return <String, dynamic>{};
    } catch (e) {
      print('❌ Error getting orders by buyer: $e');
      return <String, dynamic>{};
    }
  }

  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final response = await _api.get('/api/orders/$orderId');

      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('❌ Error getting order by ID: $e');
      return null;
    }
  }
}

