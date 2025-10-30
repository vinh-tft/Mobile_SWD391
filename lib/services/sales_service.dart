import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_models.dart';

class SalesService extends ChangeNotifier {
  SalesService(this._api);
  final ApiClient _api;

  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  // Create sale via /api/sales
  Future<bool> createSale(SaleCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/sales', body: request.toJson());
      final apiResponse = ApiResponse<SaleResponse>.fromJson(
        Map<String, dynamic>.from(response as Map),
        (data) => SaleResponse.fromJson(data),
      );
      return apiResponse.success;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createSaleItem(SaleCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('🧾 POST /api/sale-items body: ${request.toJson()}');
      }
      final response = await _api.post('/api/sale-items', body: request.toJson());
      // Handle both wrapped and raw responses
      if (response is Map && !(response as Map).containsKey('success')) {
        // Raw sale object returned
        final _ = SaleResponse.fromJson(Map<String, dynamic>.from(response as Map));
        return true;
      }
      if (response is Map) {
        final apiResponse = ApiResponse<SaleResponse>.fromJson(
          Map<String, dynamic>.from(response as Map),
          (data) => SaleResponse.fromJson(data),
        );
        if (!apiResponse.success) {
          _error = apiResponse.message;
        }
        return apiResponse.success;
      }
      // If response is not a Map, assume failure
      _error = 'Phản hồi không hợp lệ từ máy chủ';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get all sales
  Future<List<SaleResponse>> getSales() async {
    try {
      final response = await _api.get('/api/sales');
      // Some endpoints may return a list directly
      if (response is List) {
        return response.map((e) => SaleResponse.fromJson(Map<String, dynamic>.from(e))).toList();
      }
      // Or wrapped
      final apiResponse = ApiResponse<List<SaleResponse>>.fromJson(
        Map<String, dynamic>.from(response as Map),
        (data) => (data as List).map((e) => SaleResponse.fromJson(e)).toList(),
      );
      return apiResponse.data ?? <SaleResponse>[];
    } catch (e) {
      _error = e.toString();
      return <SaleResponse>[];
    }
  }

  // Get sale by id
  Future<SaleResponse?> getSaleById(int id) async {
    try {
      final response = await _api.get('/api/sales/$id');
      final apiResponse = ApiResponse<SaleResponse>.fromJson(
        Map<String, dynamic>.from(response as Map),
        (data) => SaleResponse.fromJson(data),
      );
      return apiResponse.data;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Delete sale by id
  Future<bool> deleteSale(int id) async {
    try {
      final response = await _api.delete('/api/sales/$id');
      final apiResponse = ApiResponse.fromJson(Map<String, dynamic>.from(response as Map), null);
      return apiResponse.success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }
}


