import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_models.dart';

class CategoriesService extends ChangeNotifier {
  CategoriesService(this._api);
  final ApiClient _api;

  bool _loading = false;
  List<CategoryResponse> _categories = [];
  String? _error;

  bool get loading => _loading;
  List<CategoryResponse> get categories => _categories;
  String? get error => _error;

  List<CategoryResponse> _parseCategoryListResponse(dynamic response) {
    // Some endpoints return a raw list [], others return ApiResponse { data: [...] }
    if (response is List) {
      return response.map((item) => CategoryResponse.fromJson(item)).toList();
    }
    if (response is Map) {
      // Try ApiResponse shape
      final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(
        Map<String, dynamic>.from(response as Map),
        (data) => (data as List).map((item) => CategoryResponse.fromJson(item)).toList(),
      );
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      // Fallback: if "content" exists (paged list)
      if (response['content'] is List) {
        return (response['content'] as List)
            .map((item) => CategoryResponse.fromJson(item))
            .toList();
      }
    }
    throw Exception('Unexpected categories response format');
  }

  // Get all categories
  Future<void> loadCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/categories');
      _categories = _parseCategoryListResponse(response);
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get root categories only
  Future<void> loadRootCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/categories/root');
      _categories = _parseCategoryListResponse(response);
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get active categories only
  Future<void> loadActiveCategories() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/categories/active');
      _categories = _parseCategoryListResponse(response);
    } catch (e) {
      _error = e.toString();
      _categories = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get category by ID
  Future<CategoryResponse?> getCategoryById(String categoryId) async {
    try {
      final response = await _api.get('/api/categories/$categoryId');
      final apiResponse = ApiResponse<CategoryResponse>.fromJson(
        response,
        (data) => CategoryResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get subcategories
  Future<List<CategoryResponse>> getSubcategories(String categoryId) async {
    try {
      final response = await _api.get('/api/categories/$categoryId/subcategories');
      final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => CategoryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Create new category
  Future<bool> createCategory(CategoryCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/categories', body: request.toJson());
      final apiResponse = ApiResponse<CategoryResponse>.fromJson(
        response,
        (data) => CategoryResponse.fromJson(data),
      );

      if (apiResponse.success) {
        // Reload categories to include the new one
        await loadCategories();
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

  // Create new category with individual parameters
  Future<bool> createCategoryWithParams({
    required String name,
    String? description,
    String? parentCategoryId,
    int displayOrder = 0,
    bool isActive = true,
  }) async {
    final request = CategoryCreateRequest(
      name: name,
      description: description ?? '',
      parentCategoryId: parentCategoryId,
      displayOrder: displayOrder,
      isActive: isActive,
    );
    return await createCategory(request);
  }

  // Search categories
  Future<List<CategoryResponse>> searchCategories(String query) async {
    try {
      final response = await _api.get('/api/categories/search', query: {'q': query});
      final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => CategoryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Get category tree
  Future<List<CategoryResponse>> getCategoryTree() async {
    try {
      final response = await _api.get('/api/categories/tree');
      final apiResponse = ApiResponse<List<CategoryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => CategoryResponse.fromJson(item)).toList(),
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
