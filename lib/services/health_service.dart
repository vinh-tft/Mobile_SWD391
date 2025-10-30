import 'package:flutter/foundation.dart';
import 'api_client.dart';

class HealthService extends ChangeNotifier {
  HealthService(this._api);
  final ApiClient _api;

  bool _backendUp = false;
  DateTime? _lastCheckedAt;

  bool get backendUp => _backendUp;
  DateTime? get lastCheckedAt => _lastCheckedAt;

  Future<bool> ping() async {
    try {
      await _api.get('/api/public/health');
      _backendUp = true;
    } catch (_) {
      _backendUp = false;
    }
    _lastCheckedAt = DateTime.now();
    notifyListeners();
    return _backendUp;
  }
}


