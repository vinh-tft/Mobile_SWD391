import 'api_client.dart';
import 'auth_service.dart';

class PointsService {
  PointsService(this._api, [this._auth]);
  final ApiClient _api;
  final AuthService? _auth;

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
}


