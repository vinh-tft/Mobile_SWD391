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
}


