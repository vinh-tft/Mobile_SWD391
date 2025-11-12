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

  // Parse brand list response - handles both direct List and wrapped ApiResponse
  List<BrandResponse> _parseBrandListResponse(dynamic response) {
    // Some endpoints return a raw list [], others return ApiResponse { data: [...] }
    if (response is List) {
      return response.map((item) => BrandResponse.fromJson(item)).toList();
    }
    if (response is Map) {
      // Try ApiResponse shape
      final apiResponse = ApiResponse<List<BrandResponse>>.fromJson(
        Map<String, dynamic>.from(response as Map),
        (data) => (data as List).map((item) => BrandResponse.fromJson(item)).toList(),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      // Fallback: if "content" exists (paged list)
      if (response['content'] is List) {
        return (response['content'] as List)
            .map((item) => BrandResponse.fromJson(item))
            .toList();
      }
    }
    throw Exception('Unexpected brands response format');
  }

  // Get active brands only
  Future<void> loadActiveBrands() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands/active');
      _brands = _parseBrandListResponse(response);
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

  // Create new brand with Map data
  Future<bool> createBrand(Map<String, dynamic> brandData) async {
    final request = BrandCreateRequest(
      name: brandData['name'] ?? '',
      description: brandData['description'] ?? '',
      logoUrl: brandData['logoUrl'],
      websiteUrl: brandData['website'] ?? brandData['websiteUrl'],
      isVerified: brandData['isVerified'] ?? false,
      isSustainable: brandData['isSustainable'] ?? false,
      isPartner: brandData['isPartner'] ?? false,
      isActive: brandData['isActive'] ?? true,
    );
    return await createBrandWithRequest(request);
  }

  // Create new brand
  Future<bool> createBrandWithRequest(BrandCreateRequest request) async {
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

  // Update brand
  Future<bool> updateBrand(String brandId, Map<String, dynamic> brandData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.put('/api/brands/$brandId', body: brandData);
      final apiResponse = ApiResponse<BrandResponse>.fromJson(
        response,
        (data) => BrandResponse.fromJson(data),
      );

      if (apiResponse.success) {
        // Reload brands to reflect changes
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
        _brands = apiResponse.data!;
        notifyListeners();
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

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      final response = await _api.get('/api/brands/statistics');
      return {
        'totalBrands': response['totalBrands'] ?? 0,
        'verifiedBrands': response['verifiedBrands'] ?? 0,
        'partnerBrands': response['partnerBrands'] ?? 0,
      };
    } catch (e) {
      print('Error getting brand statistics: $e');
      return {'totalBrands': 0, 'verifiedBrands': 0, 'partnerBrands': 0};
    }
  }

  // Delete brand (soft delete)
  Future<bool> deleteBrand(String brandId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.delete('/api/brands/$brandId');
      // Reload brands to reflect changes
      await loadBrands();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Restore brand
  Future<bool> restoreBrand(String brandId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.post('/api/brands/$brandId/restore');
      // Reload brands to reflect changes
      await loadBrands();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load brands with pagination
  Future<Map<String, dynamic>> loadBrandsPaginated({int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands', query: {
        'page': page.toString(),
        'size': size.toString(),
      });

      // Handle Spring Data Page response: { content: [], totalPages: 1, totalElements: 10, ... }
      List<BrandResponse> brands = [];
      int totalPages = 0;

      if (response is Map) {
        if (response['content'] is List) {
          brands = (response['content'] as List)
              .map((item) => BrandResponse.fromJson(item))
              .toList();
          totalPages = response['totalPages'] ?? 0;
        } else {
          // If response is Map but no 'content', treat as empty
          brands = [];
          totalPages = 0;
        }
      } else if (response is List) {
        brands = response.map((item) => BrandResponse.fromJson(item)).toList();
        totalPages = 1;
      }

      _brands = brands;
      return {
        'brands': brands,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      _error = e.toString();
      _brands = [];
      return {
        'brands': <BrandResponse>[],
        'totalPages': 0,
        'currentPage': page,
      };
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Search brands with pagination
  Future<Map<String, dynamic>> searchBrandsPaginated(String keyword, {int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/brands/search', query: {
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      });

      // Handle Spring Data Page response
      List<BrandResponse> brands = [];
      int totalPages = 0;

      if (response is Map) {
        if (response['content'] is List) {
          brands = (response['content'] as List)
              .map((item) => BrandResponse.fromJson(item))
              .toList();
          totalPages = response['totalPages'] ?? 0;
        }
      } else if (response is List) {
        brands = response.map((item) => BrandResponse.fromJson(item)).toList();
        totalPages = 1;
      }

      _brands = brands;
      return {
        'brands': brands,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      _error = e.toString();
      _brands = [];
      return {
        'brands': <BrandResponse>[],
        'totalPages': 0,
        'currentPage': page,
      };
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
