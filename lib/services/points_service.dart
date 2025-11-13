import 'api_client.dart';
import 'auth_service.dart';

class PointsService {
  PointsService(this._api, [this._auth]);
  final ApiClient _api;
  final AuthService? _auth;

  // Get point summary for a user
  Future<Map<String, dynamic>?> getPointSummary(String userId) async {
    try {
      final response = await _api.get('/api/points/summary/$userId');
      
      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('❌ Error getting point summary: $e');
      return null;
    }
  }

  // Get recent transactions
  Future<List<Map<String, dynamic>>> getRecentTransactions(String userId, {int limit = 5}) async {
    try {
      final response = await _api.get('/api/points/transactions/$userId/recent', query: {
        'limit': limit.toString(),
      });
      
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting recent transactions: $e');
      return [];
    }
  }

  // Get payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    try {
      final response = await _api.get('/api/payment/history', query: {
        'userId': userId,
      });
      
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting payment history: $e');
      return [];
    }
  }

  // Get expiring points
  Future<List<Map<String, dynamic>>> getExpiringPoints(String userId, {int days = 7}) async {
    try {
      final response = await _api.get('/api/points/$userId/expiring', query: {
        'days': days.toString(),
      });
      
      if (response is Map && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else if (response is List) {
        return response.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error getting expiring points: $e');
      return [];
    }
  }

  // Adjust points: positive to add, negative to deduct
  Future<bool> adjustPoints({
    required String userId,
    required int amount,
    String reason = 'adjust',
  }) async {
    final body = {
      'userId': userId,
      'amount': amount,
      'reason': reason,
    };
    try {
      await _api.post('/api/points/adjust', body: body);
      // Update locally so UI reflects immediately
      if (_auth?.currentUser != null && _auth!.currentUser!.id == userId) {
        final current = _auth!.currentUser!.points;
        _auth!.updatePoints(current + amount);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // Buy points with MoMo payment
  Future<Map<String, dynamic>?> buyPointsWithMomo({
    required String userId,
    required int pointsAmount,
    required String description,
    String? returnUrl,
  }) async {
    try {
      final body = {
        'userId': userId,
        'pointsAmount': pointsAmount,
        'description': description,
      };
      if (returnUrl != null && returnUrl.isNotEmpty) {
        body['returnUrl'] = returnUrl;
      }
      
      final response = await _api.post('/api/payment/momo/buy-points', body: body);
      
      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('❌ Error buying points with MoMo: $e');
      return null;
    }
  }

  Future<bool> completeMomoPayment({
    required String orderId,
    required String requestId,
    required String resultCode,
    String? message,
  }) async {
    try {
      final body = {
        'orderId': orderId,
        'requestId': requestId,
        'resultCode': resultCode,
        if (message != null) 'message': message,
      };

      final response = await _api.post('/api/payment/momo/redirect', body: body);

      if (response is Map) {
        final isSuccess = response['success'] == true;
        if (isSuccess && _auth != null) {
          await _auth!.refreshPoints();
        }
        return isSuccess;
      }
      return false;
    } catch (e) {
      print('❌ Error completing MoMo payment: $e');
      return false;
    }
  }

  // Cancel a pending payment
  Future<bool> cancelPayment(String paymentId) async {
    try {
      await _api.post('/api/payment/cancel/$paymentId');
      return true;
    } catch (e) {
      print('❌ Error cancelling payment: $e');
      return false;
    }
  }
}


