import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_models.dart';

class BrandsService extends ChangeNotifier {
  BrandsService(this._api);
  final ApiClient _api;

  bool _loading = false;
  List<BrandResponse> _brands = [];
  String? _error;

  bool get loading => _loading;
  List<BrandResponse> get brands => _brands;
  String? get error => _error;

  // Get all brands
  Future<void> loadBrands() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands');
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _brands = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _brands = [];
      }
    } catch (e) {
      _error = e.toString();
      _brands = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get active brands only
  Future<void> loadActiveBrands() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands/active');
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _brands = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _brands = [];
      }
    } catch (e) {
      _error = e.toString();
      _brands = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get verified brands
  Future<void> loadVerifiedBrands() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands/verified');
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _brands = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _brands = [];
      }
    } catch (e) {
      _error = e.toString();
      _brands = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get sustainable brands
  Future<void> loadSustainableBrands() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands/sustainable');
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _brands = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _brands = [];
      }
    } catch (e) {
      _error = e.toString();
      _brands = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get brand by ID
  Future<BrandResponse?> getBrandById(String brandId) async {
    try {
      final response = await _api.get('/api/brands/$brandId');
      final apiResponse = ApiResponse<BrandResponse>.fromJson(
        response,
        (data) => BrandResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get brand by slug
  Future<BrandResponse?> getBrandBySlug(String slug) async {
    try {
      final response = await _api.get('/api/brands/slug/$slug');
      final apiResponse = ApiResponse<BrandResponse>.fromJson(
        response,
        (data) => BrandResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new brand
  Future<bool> createBrand(BrandCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/brands', body: request.toJson());
      final apiResponse = ApiResponse<BrandResponse>.fromJson(
        response,
        (data) => BrandResponse.fromJson(data),
      );

      if (apiResponse.success) {
        // Reload brands to include the new one
        await loadBrands();
        return true;
      } else {
        _error = apiResponse.message;
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Search brands
  Future<List<BrandResponse>> searchBrands(String query) async {
    try {
      final response = await _api.get('/api/brands/search', query: {'q': query});
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get partner brands
  Future<List<BrandResponse>> getPartnerBrands() async {
    try {
      final response = await _api.get('/api/brands/partners');
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
