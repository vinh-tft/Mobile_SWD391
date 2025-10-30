import 'dart:async';
import 'dart:math';
import 'api_client.dart';

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: 'fake://api');

  static final DateTime _now = DateTime.now();

  static Map<String, dynamic> _wrapSuccess(dynamic data, {String message = ''}) => {
        'success': true,
        'message': message,
        'data': data,
        'timestamp': _now.toIso8601String(),
      };

  static Map<String, dynamic> _wrapFailure(String message, {int code = 400}) => {
        'success': false,
        'message': message,
        'data': null,
        'timestamp': _now.toIso8601String(),
        'statusCode': code,
      };

  // ---- Fake datasets ----
  static final List<Map<String, dynamic>> _categories = [
    {
      'categoryId': 'cat-top',
      'name': 'Áo',
      'slug': 'ao',
      'description': 'Áo các loại',
      'subCategories': <String>[],
      'displayOrder': 1,
      'isActive': true,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
      'isRootCategory': true,
      'hasSubCategories': false,
      'fullPath': 'Áo',
      'level': 0,
      'totalItems': 2,
    },
    {
      'categoryId': 'cat-bottom',
      'name': 'Quần',
      'slug': 'quan',
      'description': 'Quần các loại',
      'subCategories': <String>[],
      'displayOrder': 2,
      'isActive': true,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
      'isRootCategory': true,
      'hasSubCategories': false,
      'fullPath': 'Quần',
      'level': 0,
      'totalItems': 1,
    },
  ];

  static final List<Map<String, dynamic>> _brands = [
    {
      'brandId': 'br-uniqlo',
      'name': 'Uniqlo',
      'slug': 'uniqlo',
      'description': 'Thời trang Nhật Bản',
      'logoUrl': null,
      'websiteUrl': null,
      'isVerified': true,
      'isSustainable': true,
      'isPartner': true,
      'isActive': true,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
      'totalItems': 2,
    },
    {
      'brandId': 'br-zara',
      'name': 'Zara',
      'slug': 'zara',
      'description': 'Thời trang nhanh',
      'logoUrl': null,
      'websiteUrl': null,
      'isVerified': false,
      'isSustainable': false,
      'isPartner': false,
      'isActive': true,
      'createdAt': _now.toIso8601String(),
      'updatedAt': _now.toIso8601String(),
      'totalItems': 1,
    },
  ];

  static final List<Map<String, dynamic>> _items = List.generate(6, (i) {
    final cat = i % 2 == 0 ? 'Áo' : 'Quần';
    final brand = i % 3 == 0 ? 'Uniqlo' : 'Zara';
    final id = 'item-${i + 1}';
    return {
      'itemId': id,
      'name': 'Sản phẩm $id',
      'description': 'Mô tả ngắn gọn cho sản phẩm $id',
      'categoryName': cat,
      'brandName': brand,
      'size': ['S', 'M', 'L', 'XL'][i % 4],
      'color': ['Đen', 'Trắng', 'Xám', 'Xanh'][i % 4],
      'condition': 'GOOD',
      'status': 'VERIFIED',
      'pointValue': 100 + i * 10,
      'originalPrice': 200000 + i * 50000,
      'primaryImageUrl': null,
      'imageCount': 1,
      'tags': <String>['basic', 'casual'],
      'ownerName': 'Người dùng demo',
      'createdAt': _now.subtract(Duration(days: i)).toIso8601String(),
      'isMarketplaceReady': true,
      'viewCount': 5 * i,
      'likeCount': 2 * i,
    };
  });

  // ---- Router ----
  Future<dynamic> _route(String method, String path,
      {Object? body, Map<String, dynamic>? query}) async {
    // Simulate small network delay
    await Future.delayed(const Duration(milliseconds: 180));

    // Health
    if (method == 'GET' && path == '/api/public/health') {
      return _wrapSuccess({'status': 'ok'});
    }

    // Items
    if (method == 'GET' && path == '/api/items/marketplace-ready') {
      return _wrapSuccess(_items);
    }
    if (method == 'GET' && path == '/api/items') {
      final page = (query?['page'] ?? 0) as int;
      final size = (query?['size'] ?? 20) as int;
      final start = page * size;
      final end = min(start + size, _items.length);
      final slice = start < _items.length ? _items.sublist(start, end) : <Map<String, dynamic>>[];
      return _wrapSuccess({
        'content': slice,
        'totalElements': _items.length,
        'totalPages': (_items.length / size).ceil(),
        'size': size,
        'number': page,
        'first': page == 0,
        'last': end >= _items.length,
        'numberOfElements': slice.length,
      });
    }
    if (method == 'GET' && path.startsWith('/api/items/category/')) {
      return _wrapSuccess(_items);
    }
    if (method == 'GET' && path == '/api/items/search') {
      final q = (query?['q'] ?? '').toString().toLowerCase();
      final filtered = _items.where((e) => e['name'].toString().toLowerCase().contains(q)).toList();
      return _wrapSuccess(filtered);
    }
    if (method == 'GET' && path.startsWith('/api/items/')) {
      final id = path.split('/').last;
      final found = _items.firstWhere((e) => e['itemId'] == id, orElse: () => {});
      if (found.isEmpty) return _wrapFailure('Không tìm thấy sản phẩm', code: 404);
      // Expand to ItemResponse-like shape
      return _wrapSuccess({
        'itemId': found['itemId'],
        'name': found['name'],
        'description': 'Mô tả chi tiết cho ${found['name']}',
        'categoryId': 'cat-top',
        'brandId': 'br-uniqlo',
        'brandName': found['brandName'],
        'size': found['size'],
        'color': found['color'],
        'condition': 'GOOD',
        'status': 'VERIFIED',
        'pointValue': found['pointValue'],
        'originalPrice': found['originalPrice'],
        'imageUrls': <String>[],
        'videoUrls': <String>[],
        'tags': found['tags'],
        'ownerId': 'u-1',
        'ownerName': found['ownerName'],
        'verifiedBy': null,
        'verifiedAt': null,
        'createdAt': found['createdAt'],
        'updatedAt': found['createdAt'],
        'isMarketplaceReady': true,
        'viewCount': found['viewCount'],
        'likeCount': found['likeCount'],
      });
    }
    if (method == 'POST' && path == '/api/items') {
      return _wrapSuccess({
        'itemId': 'item-${_items.length + 1}',
      }, message: 'Tạo sản phẩm thành công');
    }
    if (method == 'POST' && path == '/api/items/with-images') {
      return _wrapSuccess({
        'itemId': 'item-${_items.length + 1}',
      }, message: 'Tạo sản phẩm thành công');
    }
    if (method == 'POST' && path.contains('/images')) {
      return _wrapSuccess(null, message: 'Tải ảnh thành công');
    }
    if (method == 'DELETE' && path.contains('/images')) {
      return _wrapSuccess(null, message: 'Xóa ảnh thành công');
    }
    if (method == 'PATCH' && path.endsWith('/status')) {
      return _wrapSuccess(null, message: 'Cập nhật trạng thái thành công');
    }
    if (method == 'PATCH' && path.endsWith('/condition')) {
      return _wrapSuccess(null, message: 'Cập nhật tình trạng thành công');
    }
    if (method == 'PATCH' && path.endsWith('/valuation')) {
      return _wrapSuccess(null, message: 'Cập nhật định giá thành công');
    }
    if (method == 'DELETE' && path.startsWith('/api/items/')) {
      return _wrapSuccess(null, message: 'Xóa sản phẩm thành công');
    }

    // Categories
    if (method == 'GET' && path == '/api/categories') {
      return _wrapSuccess(_categories);
    }
    if (method == 'GET' && path == '/api/categories/root') {
      return _wrapSuccess(_categories);
    }
    if (method == 'GET' && path == '/api/categories/active') {
      return _wrapSuccess(_categories);
    }
    if (method == 'GET' && path.startsWith('/api/categories/') && path.endsWith('/subcategories')) {
      return _wrapSuccess(<Map<String, dynamic>>[]);
    }
    if (method == 'GET' && path.startsWith('/api/categories/')) {
      final id = path.split('/').last;
      final found = _categories.firstWhere((e) => e['categoryId'] == id, orElse: () => {});
      if (found.isEmpty) return _wrapFailure('Không tìm thấy danh mục', code: 404);
      return _wrapSuccess(found);
    }
    if (method == 'POST' && path == '/api/categories') {
      return _wrapSuccess(_categories.first, message: 'Tạo danh mục thành công');
    }
    if (method == 'GET' && path == '/api/categories/search') {
      return _wrapSuccess(_categories);
    }
    if (method == 'GET' && path == '/api/categories/tree') {
      return _wrapSuccess(_categories);
    }

    // Brands
    if (method == 'GET' && path == '/api/brands') return _wrapSuccess(_brands);
    if (method == 'GET' && path == '/api/brands/active') return _wrapSuccess(_brands);
    if (method == 'GET' && path == '/api/brands/verified') return _wrapSuccess(_brands);
    if (method == 'GET' && path == '/api/brands/sustainable') return _wrapSuccess(_brands);
    if (method == 'GET' && path == '/api/brands/partners') return _wrapSuccess(_brands.take(1).toList());
    if (method == 'GET' && path.startsWith('/api/brands/slug/')) return _wrapSuccess(_brands.first);
    if (method == 'GET' && path.startsWith('/api/brands/')) return _wrapSuccess(_brands.first);
    if (method == 'POST' && path == '/api/brands') return _wrapSuccess(_brands.first, message: 'Tạo thương hiệu thành công');

    // Sales
    if (method == 'POST' && (path == '/api/sales' || path == '/api/sale-items')) {
      return _wrapSuccess({
        'saleId': 'sale-1',
        'name': 'Đơn hàng demo',
        'description': 'Mô tả',
        'quantity': 1,
        'price': 1000,
        'createdAt': _now.toIso8601String(),
        'updatedAt': _now.toIso8601String(),
      }, message: 'Tạo đơn hàng thành công');
    }
    if (method == 'GET' && path == '/api/sales') {
      return _wrapSuccess([
        {
          'saleId': 'sale-1',
          'name': 'Đơn hàng demo',
          'description': 'Mô tả',
          'quantity': 1,
          'price': 1000,
          'createdAt': _now.toIso8601String(),
          'updatedAt': _now.toIso8601String(),
        }
      ]);
    }
    if (method == 'GET' && path.startsWith('/api/sales/')) {
      return _wrapSuccess({
        'saleId': 'sale-1',
        'name': 'Đơn hàng demo',
        'description': 'Mô tả',
        'quantity': 1,
        'price': 1000,
        'createdAt': _now.toIso8601String(),
        'updatedAt': _now.toIso8601String(),
      });
    }
    if (method == 'DELETE' && path.startsWith('/api/sales/')) {
      return _wrapSuccess(null, message: 'Xóa đơn hàng thành công');
    }

    // Users
    if (method == 'GET' && path.startsWith('/api/users/email/')) {
      final email = path.split('/').last;
      return {
        'id': 'u-1',
        'email': email,
        'name': 'Demo User',
      };
    }

    // Points
    if (method == 'POST' && path == '/api/points/adjust') {
      return _wrapSuccess(null, message: 'Điều chỉnh điểm thành công');
    }

    // Default
    return _wrapSuccess(null);
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query, Duration? timeout}) {
    return _route('GET', path, query: query);
  }

  @override
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) {
    return _route('POST', path, body: body, query: query);
  }

  @override
  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) {
    return _route('PUT', path, body: body, query: query);
  }

  @override
  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) {
    return _route('PATCH', path, body: body, query: query);
  }

  @override
  Future<dynamic> delete(String path, {Object? body, Map<String, dynamic>? query, Duration? timeout}) {
    return _route('DELETE', path, body: body, query: query);
  }
}


