import 'api_client.dart';

class UsersService {
  UsersService(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>?> getByEmail(String email) async {
    try {
      final data = await _api.get('/api/users/email/$email');
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  // Get user management summary with stats
  Future<Map<String, dynamic>> getUserManagementSummary({int page = 0, int size = 20}) async {
    try {
      final response = await _api.get('/api/users/management/summary', query: {
        'page': page.toString(),
        'size': size.toString(),
      });
      
      // Backend returns ApiResponse<UserManagementResponse>
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return <String, dynamic>{};
    } catch (e) {
      print('❌ Error getting user management summary: $e');
      return <String, dynamic>{};
    }
  }

  // Get all users with pagination
  Future<Map<String, dynamic>> getAllUsersPaginated({int page = 0, int size = 20}) async {
    try {
      final response = await _api.get('/api/users', query: {
        'page': page.toString(),
        'size': size.toString(),
      });
      
      // Backend returns ApiResponse<Page<UserDetailResponse>>
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return <String, dynamic>{};
    } catch (e) {
      print('❌ Error getting all users: $e');
      return <String, dynamic>{};
    }
  }

  // Search users by keyword (email, phone, name) with pagination
  Future<Map<String, dynamic>> searchUsersPaginated(String keyword, {int page = 0, int size = 20}) async {
    try {
      final response = await _api.get('/api/users/search', query: {
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      });
      
      // Backend returns ApiResponse<Page<UserDetailResponse>>
      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return <String, dynamic>{};
    } catch (e) {
      print('❌ Error searching users: $e');
      return <String, dynamic>{};
    }
  }

  // Search users by keyword (email, phone, name) - legacy method
  Future<List<Map<String, dynamic>>> searchUsers(String keyword, {int page = 0, int size = 10}) async {
    try {
      final response = await searchUsersPaginated(keyword, page: page, size: size);
      
      if (response is Map && response['data'] is Map) {
        final data = response['data'] as Map;
        if (data['content'] is List) {
          return (data['content'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _api.get('/api/users/$userId');
      
      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user by ID: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>?> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      final response = await _api.put('/api/users/$userId', body: updateData);
      
      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      } else if (response is Map) {
        return Map<String, dynamic>.from(response);
      }
      return null;
    } catch (e) {
      print('❌ Error updating user: $e');
      rethrow;
    }
  }

  // Adjust points for a user (admin/staff only)
  Future<Map<String, dynamic>?> adjustPoints(String userId, int points, String reason) async {
    try {
      final response = await _api.post('/api/points/adjust', query: {
        'userId': userId,
        'points': points.toString(),
        'reason': reason,
      });
      
      if (response is Map && response['data'] is Map) {
        return response['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Error adjusting points: $e');
      rethrow;
    }
  }
}


