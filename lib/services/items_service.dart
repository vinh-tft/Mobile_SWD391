import 'dart:io';
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
      
      // Handle both cases: direct List or wrapped in ApiResponse Map
      if (response is List) {
        // API returned a direct list
        _items = (response as List)
            .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map) {
        // API returned wrapped response
        final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
          response as Map<String, dynamic>,
          (data) {
            if (data is List) {
              return (data as List)
                  .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <ItemSummaryResponse>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          _items = apiResponse.data!;
        } else {
          _error = apiResponse.message;
          _items = [];
        }
      } else {
        _error = 'Unexpected response format: ${response.runtimeType}';
        _items = [];
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error loading marketplace ready items: $e');
      print('❌ Stack trace: $stackTrace');
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
      
      // Handle both cases: direct PageResponse or wrapped in ApiResponse
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        // Check if it's a PageResponse directly
        if (responseMap.containsKey('content') && responseMap.containsKey('totalPages')) {
          final pageResponse = PageResponse.fromJson(
            responseMap,
            (item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>),
          );
          _items = pageResponse.content;
        } else {
          // Wrapped in ApiResponse
          final apiResponse = ApiResponse<PageResponse<ItemSummaryResponse>>.fromJson(
            responseMap,
            (data) => PageResponse.fromJson(data as Map<String, dynamic>, (item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>)),
          );

          if (apiResponse.success && apiResponse.data != null) {
            _items = apiResponse.data!.content;
          } else {
            _error = apiResponse.message;
            _items = [];
          }
        }
      } else {
        _error = 'Unexpected response format: ${response.runtimeType}';
        _items = [];
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error loading items: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Filter items with multiple criteria (matches React version)
  Future<void> filterItems({
    List<String>? statuses,
    String? categoryId,
    String? brandId,
    int? minCondition,
    int page = 0,
    int size = 12,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      
      if (statuses != null && statuses.isNotEmpty) {
        // Send statuses as array - ApiClient will serialize it correctly
        // Match React FE: statuses: [ItemStatus.READY_FOR_SALE] -> statuses=READY_FOR_SALE
        queryParams['statuses'] = statuses;
        print('📋 Statuses filter: $statuses');
      }
      
      if (categoryId != null) {
        queryParams['categoryId'] = categoryId;
        print('📋 Category filter: $categoryId');
      }
      
      if (brandId != null) {
        queryParams['brandId'] = brandId;
        print('📋 Brand filter: $brandId');
      }
      
      if (minCondition != null) {
        queryParams['minCondition'] = minCondition;
      }
      
      print('🔍 Filter query params: $queryParams');
      final response = await _api.get('/api/items/filter', query: queryParams);
      print('📦 Filter API response type: ${response.runtimeType}');
      
      // Match React FE: axios returns response.data, which is the PageResponse directly
      // React FE: const response = await ItemsAPI.filterItems(filters);
      //           let resultItems = response.content; // Direct access to content
      dynamic dataToParse = response;
      
      // Check if response is wrapped in 'data' field (like axios does)
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        print('📋 Response keys: ${responseMap.keys.toList()}');
        
        // If response has 'data' field, unwrap it (like axios response.data)
        if (responseMap.containsKey('data') && !responseMap.containsKey('content')) {
          print('📦 Response wrapped in data field, unwrapping...');
          dataToParse = responseMap['data'];
          print('📋 Unwrapped data type: ${dataToParse.runtimeType}');
          if (dataToParse is Map) {
            print('📋 Unwrapped data keys: ${(dataToParse as Map).keys.toList()}');
          }
        }
      }
      
      // Handle both cases: direct PageResponse or wrapped in ApiResponse
      // Match React FE: response.content and response.totalPages
      if (dataToParse is Map) {
        final responseMap = Map<String, dynamic>.from(dataToParse);
        print('📋 Final data keys: ${responseMap.keys.toList()}');
        
        // Check if it's a PageResponse directly (has 'content' and 'totalPages')
        if (responseMap.containsKey('content') && responseMap.containsKey('totalPages')) {
          print('✅ Direct PageResponse detected');
          final pageResponse = PageResponse.fromJson(
            responseMap,
            (item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>),
          );
          _items = pageResponse.content;
          print('✅ Parsed ${_items.length} items from PageResponse.content');
        } else if (responseMap.containsKey('success')) {
          // Wrapped in ApiResponse
          print('📦 Wrapped in ApiResponse, checking...');
          final apiResponse = ApiResponse<PageResponse<ItemSummaryResponse>>.fromJson(
            responseMap,
            (data) {
              if (data is Map) {
                return PageResponse.fromJson(
                  Map<String, dynamic>.from(data),
                  (item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>),
                );
              }
              throw Exception('Expected Map for PageResponse data');
            },
          );

          if (apiResponse.success && apiResponse.data != null) {
            _items = apiResponse.data!.content;
            print('✅ Parsed ${_items.length} items from ApiResponse.data.content');
          } else {
            _error = apiResponse.message;
            _items = [];
            print('❌ ApiResponse error: ${apiResponse.message}');
          }
        } else {
          _error = 'Response does not contain content or success field';
          _items = [];
          print('❌ Response missing content/success fields. Keys: ${responseMap.keys.toList()}');
        }
      } else if (dataToParse is List) {
        // API returned a direct list (fallback)
        print('📋 Direct List response detected');
        _items = (dataToParse as List)
            .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList();
        print('✅ Parsed ${_items.length} items from List');
      } else {
        _error = 'Unexpected response format: ${dataToParse.runtimeType}';
        _items = [];
        print('❌ Unexpected response format: ${dataToParse.runtimeType}');
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error filtering items: $e');
      print('❌ Stack trace: $stackTrace');
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
      
      // Handle both cases: direct List or wrapped in ApiResponse Map
      if (response is List) {
        // API returned a direct list
        _items = (response as List)
            .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map) {
        // API returned wrapped response
        final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
          response as Map<String, dynamic>,
          (data) {
            if (data is List) {
              return (data as List)
                  .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <ItemSummaryResponse>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          _items = apiResponse.data!;
        } else {
          _error = apiResponse.message;
          _items = [];
        }
      } else {
        _error = 'Unexpected response format: ${response.runtimeType}';
        _items = [];
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error loading items by category: $e');
      print('❌ Stack trace: $stackTrace');
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
      
      // Handle both cases: direct List or wrapped in ApiResponse Map
      if (response is List) {
        // API returned a direct list
        _items = (response as List)
            .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map) {
        // API returned wrapped response
        final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
          response as Map<String, dynamic>,
          (data) {
            if (data is List) {
              return (data as List)
                  .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <ItemSummaryResponse>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          _items = apiResponse.data!;
        } else {
          _error = apiResponse.message;
          _items = [];
        }
      } else {
        _error = 'Unexpected response format: ${response.runtimeType}';
        _items = [];
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error loading items by owner: $e');
      print('❌ Stack trace: $stackTrace');
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
      
      // Handle both cases: direct List or wrapped in ApiResponse Map
      if (response is List) {
        // API returned a direct list
        _items = (response as List)
            .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response is Map) {
        // API returned wrapped response
        final apiResponse = ApiResponse<List<ItemSummaryResponse>>.fromJson(
          response as Map<String, dynamic>,
          (data) {
            if (data is List) {
              return (data as List)
                  .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
                  .toList();
            }
            return <ItemSummaryResponse>[];
          },
        );

        if (apiResponse.success && apiResponse.data != null) {
          _items = apiResponse.data!;
        } else {
          _error = apiResponse.message;
          _items = [];
        }
      } else {
        _error = 'Unexpected response format: ${response.runtimeType}';
        _items = [];
      }
    } catch (e, stackTrace) {
      _items = [];
      _error = e.toString();
      print('❌ Error searching items: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get item by ID
  Future<ItemResponse?> getItemById(String itemId) async {
    try {
      final response = await _api.get('/api/items/$itemId');
      
      // Handle both direct ItemResponse or wrapped in ApiResponse
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        
        // Check if it's wrapped in ApiResponse
        if (responseMap.containsKey('success') || responseMap.containsKey('data')) {
          final apiResponse = ApiResponse<ItemResponse>.fromJson(
            responseMap,
            (data) {
              if (data is Map) {
                return ItemResponse.fromJson(Map<String, dynamic>.from(data));
              }
              throw Exception('Expected Map for ItemResponse data');
            },
          );

          if (apiResponse.success && apiResponse.data != null) {
            return apiResponse.data!;
          }
        } else {
          // Direct ItemResponse
          return ItemResponse.fromJson(responseMap);
        }
      }
      
      return null;
    } catch (e, stackTrace) {
      print('❌ Error loading item by ID: $e');
      print('❌ Stack trace: $stackTrace');
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

  // Create item with full admin fields (for admin create page)
  Future<ItemResponse?> createItemAsAdmin(Map<String, dynamic> itemData, String ownerId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      // Prepare request body matching backend ItemCreateRequest
      // Backend expects: categoryId (UUID), brandId (UUID), name, description, size, color,
      // conditionScore (BigDecimal), conditionDescription, originalPrice (BigDecimal),
      // currentEstimatedValue (BigDecimal), weightGrams (Integer), acquisitionMethod (String),
      // images (List<String>), videos (List<String>), tags (List<String>)
      // Note: ownerId is passed as query param userId, not in body
      final requestBody = <String, dynamic>{
        'categoryId': itemData['categoryId'],
        if (itemData['brandId'] != null) 'brandId': itemData['brandId'],
        'name': itemData['name'],
        'description': itemData['description'],
        'size': itemData['size'] ?? 'N/A',
        'color': itemData['color'] ?? 'N/A',
        if (itemData['conditionScore'] != null) 'conditionScore': itemData['conditionScore'],
        if (itemData['conditionDescription'] != null) 'conditionDescription': itemData['conditionDescription'],
        if (itemData['originalPrice'] != null) 'originalPrice': itemData['originalPrice'],
        if (itemData['currentEstimatedValue'] != null) 'currentEstimatedValue': itemData['currentEstimatedValue'],
        if (itemData['weightGrams'] != null) 'weightGrams': itemData['weightGrams'],
        if (itemData['acquisitionMethod'] != null) 'acquisitionMethod': itemData['acquisitionMethod'],
        'images': itemData['imageUrls'] ?? [],
        'videos': itemData['videoUrls'] ?? [],
        'tags': itemData['tags'] ?? [],
      };

      // Backend expects userId as query parameter, not in body
      final response = await _api.post('/api/items?userId=$ownerId', body: requestBody);
      
      // Handle response - could be direct ItemResponse or wrapped
      ItemResponse? createdItem;
      String? itemCode;
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        
        // Extract itemCode if available
        itemCode = responseMap['itemCode']?.toString();
        
        if (responseMap.containsKey('itemId')) {
          // Direct ItemResponse
          createdItem = ItemResponse.fromJson(responseMap);
        } else {
          // Wrapped in ApiResponse
          final apiResponse = ApiResponse<ItemResponse>.fromJson(
            responseMap,
            (data) => ItemResponse.fromJson(Map<String, dynamic>.from(data)),
          );
          if (apiResponse.success && apiResponse.data != null) {
            createdItem = apiResponse.data;
            // Try to get itemCode from response if not in data
            if (itemCode == null) {
              itemCode = responseMap['itemCode']?.toString();
            }
          } else {
            _error = apiResponse.message;
            return null;
          }
        }
      }

      if (createdItem != null) {
        // Store itemCode if available (for success dialog)
        if (itemCode != null && itemCode.isNotEmpty) {
          // ItemResponse doesn't have itemCode field, but we can store it temporarily
          // For now, we'll pass it through the return value via a workaround
        }

        // Auto-verify the item (admin created items are pre-verified)
        try {
          await _api.post('/api/items/${createdItem.itemId}/verify', body: {'verifiedBy': ownerId});
        } catch (e) {
          print('Warning: Could not auto-verify item: $e');
        }

        // Reload items
        await loadMarketplaceReady();
        return createdItem;
      }

      return null;
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ Error creating item: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Upload multiple images for an item
  Future<ItemResponse?> uploadItemImages(String itemId, List<File> imageFiles) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      print('📤 Uploading ${imageFiles.length} images for item $itemId');
      
      final response = await _api.postMultipart(
        '/api/items/$itemId/images/upload-multiple',
        files: imageFiles,
        fileFieldName: 'files',
        timeout: Duration(seconds: 120), // 2 minutes for image uploads
      );
      
      // Handle response
      ItemResponse? updatedItem;
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        
        if (responseMap.containsKey('itemId')) {
          // Direct ItemResponse
          updatedItem = ItemResponse.fromJson(responseMap);
        } else {
          // Wrapped in ApiResponse
          final apiResponse = ApiResponse<ItemResponse>.fromJson(
            responseMap,
            (data) => ItemResponse.fromJson(Map<String, dynamic>.from(data)),
          );
          if (apiResponse.success && apiResponse.data != null) {
            updatedItem = apiResponse.data;
          } else {
            _error = apiResponse.message;
            return null;
          }
        }
      }

      print('✅ Images uploaded successfully');
      return updatedItem;
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ Error uploading images: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
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

  // Update item (full update)
  Future<ItemResponse?> updateItem(String itemId, Map<String, dynamic> updateData) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.put('/api/items/$itemId', body: updateData);
      
      // Handle response - could be direct ItemResponse or wrapped
      ItemResponse? updatedItem;
      if (response is Map) {
        final responseMap = Map<String, dynamic>.from(response);
        
        // Check if it's wrapped in ApiResponse
        if (responseMap.containsKey('success') || responseMap.containsKey('data')) {
          final apiResponse = ApiResponse<ItemResponse>.fromJson(
            responseMap,
            (data) {
              if (data is Map) {
                return ItemResponse.fromJson(Map<String, dynamic>.from(data));
              }
              throw Exception('Expected Map for ItemResponse data');
            },
          );

          if (apiResponse.success && apiResponse.data != null) {
            updatedItem = apiResponse.data;
          } else {
            _error = apiResponse.message;
            return null;
          }
        } else {
          // Direct ItemResponse
          updatedItem = ItemResponse.fromJson(responseMap);
        }
      }

      return updatedItem;
    } catch (e, stackTrace) {
      _error = e.toString();
      print('❌ Error updating item: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
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

  // Search items with pagination
  Future<Map<String, dynamic>> searchItemsPaginated(String keyword, {int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/items/search', query: {
        'keyword': keyword,
        'page': page.toString(),
        'size': size.toString(),
      });

      List<ItemSummaryResponse> items = [];
      int totalPages = 0;

      if (response is Map) {
        if (response['content'] is List) {
          items = (response['content'] as List)
              .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
              .toList();
          totalPages = response['totalPages'] ?? 0;
        }
      } else if (response is List) {
        items = response.map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>)).toList();
        totalPages = 1;
      }

      _items = items;
      return {
        'items': items,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      _error = e.toString();
      _items = [];
      return {
        'items': <ItemSummaryResponse>[],
        'totalPages': 0,
        'currentPage': page,
      };
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Get items by status with pagination
  Future<Map<String, dynamic>> getItemsByStatusPaginated(String status, {int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/items/status/$status', query: {
        'page': page.toString(),
        'size': size.toString(),
      });

      List<ItemSummaryResponse> items = [];
      int totalPages = 0;

      if (response is Map) {
        if (response['content'] is List) {
          items = (response['content'] as List)
              .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
              .toList();
          totalPages = response['totalPages'] ?? 0;
        }
      } else if (response is List) {
        items = response.map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>)).toList();
        totalPages = 1;
      }

      _items = items;
      return {
        'items': items,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      _error = e.toString();
      _items = [];
      return {
        'items': <ItemSummaryResponse>[],
        'totalPages': 0,
        'currentPage': page,
      };
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Count items by status
  Future<int> countItemsByStatus(String status) async {
    try {
      final response = await _api.get('/api/items/statistics/status/$status/count');
      // Backend returns Long directly, not wrapped in an object
      if (response is int) {
        return response;
      } else if (response is Map && response['count'] != null) {
        return response['count'] as int;
      } else if (response is num) {
        return response.toInt();
      }
      print('⚠️ Unexpected response format for countItemsByStatus: ${response.runtimeType}');
      return 0;
    } catch (e) {
      print('❌ Error counting items by status $status: $e');
      return 0;
    }
  }

  // Get statistics
  Future<Map<String, int>> getStatistics() async {
    try {
      print('📊 Loading statistics...');
      final listedCount = await countItemsByStatus('LISTED');
      print('📊 LISTED: $listedCount');
      final readyCount = await countItemsByStatus('READY_FOR_SALE');
      print('📊 READY_FOR_SALE: $readyCount');
      final submittedCount = await countItemsByStatus('SUBMITTED');
      print('📊 SUBMITTED: $submittedCount');
      final rejectedCount = await countItemsByStatus('REJECTED');
      print('📊 REJECTED: $rejectedCount');

      final stats = {
        'total': listedCount + readyCount + submittedCount + rejectedCount,
        'approved': listedCount + readyCount,
        'pending': submittedCount,
        'rejected': rejectedCount,
      };
      print('📊 Final stats: $stats');
      return stats;
    } catch (e) {
      print('❌ Error getting item statistics: $e');
      return {'total': 0, 'approved': 0, 'pending': 0, 'rejected': 0};
    }
  }

  // Load items with pagination (returns pagination info)
  Future<Map<String, dynamic>> loadItemsPaginated({int page = 0, int size = 20}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('/api/items', query: {
        'page': page.toString(),
        'size': size.toString(),
      });

      List<ItemSummaryResponse> items = [];
      int totalPages = 0;

      if (response is Map) {
        if (response['content'] is List) {
          items = (response['content'] as List)
              .map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>))
              .toList();
          totalPages = response['totalPages'] ?? 0;
        }
      } else if (response is List) {
        items = response.map((item) => ItemSummaryResponse.fromJson(item as Map<String, dynamic>)).toList();
        totalPages = 1;
      }

      _items = items;
      return {
        'items': items,
        'totalPages': totalPages,
        'currentPage': page,
      };
    } catch (e) {
      _error = e.toString();
      _items = [];
      return {
        'items': <ItemSummaryResponse>[],
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


