import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/api_models.dart';

class ItemsService extends ChangeNotifier {
  ItemsService(this._api);
  final ApiClient _api;

  bool _loading = false;
  List<ItemSummaryResponse> _items = [];
  String? _error;
  
  bool get loading => _loading;
  List<ItemSummaryResponse> get items => _items;
  String? get error => _error;

  // Load marketplace ready items
  Future<void> loadMarketplaceReady() async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/api/items/marketplace-ready');
      final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => ItemSummaryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _items = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _items = [];
      }
    } catch (e) {
      _items = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load all items with pagination
  Future<void> loadItems({int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/api/items', query: {
        'page': page,
        'size': size,
      });
      
      final apiResponse = ApiResponse<PageResponse<ItemSummaryResponse>>.fromJson(
        response,
        (data) => PageResponse.fromJson(data, (item) => ItemSummaryResponse.fromJson(item)),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _items = apiResponse.data!.content;
      } else {
        _error = apiResponse.message;
        _items = [];
      }
    } catch (e) {
      _items = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load items by category
  Future<void> loadItemsByCategory(String categoryId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/api/items/category/$categoryId');
      final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => ItemSummaryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _items = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _items = [];
      }
    } catch (e) {
      _items = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Load items by owner
  Future<void> loadItemsByOwner(String ownerId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/api/items/owner/$ownerId');
      final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => ItemSummaryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _items = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _items = [];
      }
    } catch (e) {
      _items = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Search items
  Future<void> searchItems(String query) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _api.get('/api/items/search', query: {'q': query});
      final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
        response,
        (data) => (data as List).map((item) => ItemSummaryResponse.fromJson(item)).toList(),
      );

      if (apiResponse.success && apiResponse.data != null) {
        _items = apiResponse.data!;
      } else {
        _error = apiResponse.message;
        _items = [];
      }
    } catch (e) {
      _items = [];
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get item by ID
  Future<ItemResponse?> getItemById(String itemId) async {
    try {
      final response = await _api.get('/api/items/$itemId');
      final apiResponse = ApiResponse<ItemResponse>.fromJson(
        response,
        (data) => ItemResponse.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Create new item
  Future<bool> createItem(ItemCreateRequest request) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/items', body: request.toJson());
      final apiResponse = ApiResponse<ItemResponse>.fromJson(
        response,
        (data) => ItemResponse.fromJson(data),
      );

      if (apiResponse.success) {
        // Reload items to include the new one
        await loadMarketplaceReady();
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

  // Create item with images
  Future<bool> createItemWithImages(ItemCreateRequest request, List<String> imageUrls) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post('/api/items/with-images', body: {
        ...request.toJson(),
        'imageUrls': imageUrls,
      });
      final apiResponse = ApiResponse<ItemResponse>.fromJson(
        response,
        (data) => ItemResponse.fromJson(data),
      );

      if (apiResponse.success) {
        // Reload items to include the new one
        await loadMarketplaceReady();
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

  // Upload image to item
  Future<bool> uploadImageToItem(String itemId, String imageUrl) async {
    try {
      final response = await _api.post('/api/items/$itemId/images', body: {
        'imageUrl': imageUrl,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Add image by URL
  Future<bool> addImageByUrl(String itemId, String imageUrl) async {
    try {
      final response = await _api.post('/api/items/$itemId/images', body: {
        'imageUrl': imageUrl,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Remove image from item
  Future<bool> removeImageFromItem(String itemId, String imageUrl) async {
    try {
      final response = await _api.delete('/api/items/$itemId/images', body: {
        'imageUrl': imageUrl,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Update item status
  Future<bool> updateItemStatus(String itemId, ItemStatus status) async {
    try {
      final response = await _api.patch('/api/items/$itemId/status', body: {
        'status': status.toString().split('.').last,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Update item condition
  Future<bool> updateItemCondition(String itemId, ItemCondition condition) async {
    try {
      final response = await _api.patch('/api/items/$itemId/condition', body: {
        'condition': condition.toString().split('.').last,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Update item valuation
  Future<bool> updateItemValuation(String itemId, int pointValue) async {
    try {
      final response = await _api.patch('/api/items/$itemId/valuation', body: {
        'pointValue': pointValue,
      });
      final apiResponse = ApiResponse.fromJson(response, null);

      return apiResponse.success;
    } catch (e) {
      return false;
    }
  }

  // Delete item
  Future<bool> deleteItem(String itemId) async {
    try {
      final response = await _api.delete('/api/items/$itemId');
      final apiResponse = ApiResponse.fromJson(response, null);

      if (apiResponse.success) {
        // Remove from local list
        _items.removeWhere((item) => item.itemId == itemId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}


