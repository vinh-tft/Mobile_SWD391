import 'api_client.dart';

class DonatedItem {
  final String donatedItemId;
  final String donationCode;
  final Map<String, dynamic>? customer;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final Map<String, dynamic> staff;
  final Map<String, dynamic> category;
  final Map<String, dynamic>? brand;
  final String name;
  final String description;
  final String? size;
  final String? color;
  final double? originalPrice;
  final int? conditionScore;
  final String? conditionDescription;
  final Map<String, dynamic>? materialComposition;
  final double? estimatedValue;
  final String? processingType;
  final String? processingNotes;
  final String donationStatus;
  final int? pointsAwarded;
  final String? convertedToItemId;
  final List<String>? images;
  final String createdAt;
  final String updatedAt;
  final String? valuatedAt;
  final String? acceptedAt;
  final String? processedAt;

  DonatedItem({
    required this.donatedItemId,
    required this.donationCode,
    this.customer,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.staff,
    required this.category,
    this.brand,
    required this.name,
    required this.description,
    this.size,
    this.color,
    this.originalPrice,
    this.conditionScore,
    this.conditionDescription,
    this.materialComposition,
    this.estimatedValue,
    this.processingType,
    this.processingNotes,
    required this.donationStatus,
    this.pointsAwarded,
    this.convertedToItemId,
    this.images,
    required this.createdAt,
    required this.updatedAt,
    this.valuatedAt,
    this.acceptedAt,
    this.processedAt,
  });

  factory DonatedItem.fromJson(Map<String, dynamic> json) {
    // Handle nested data wrapper
    final data = json['data'] ?? json;
    
    return DonatedItem(
      donatedItemId: data['donatedItemId']?.toString() ?? '',
      donationCode: data['donationCode']?.toString() ?? '',
      customer: data['customer'] is Map ? Map<String, dynamic>.from(data['customer']) : null,
      customerName: data['customerName']?.toString(),
      customerPhone: data['customerPhone']?.toString(),
      customerEmail: data['customerEmail']?.toString(),
      staff: data['staff'] is Map ? Map<String, dynamic>.from(data['staff']) : {},
      category: data['category'] is Map ? Map<String, dynamic>.from(data['category']) : {},
      brand: data['brand'] is Map ? Map<String, dynamic>.from(data['brand']) : null,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      size: data['size']?.toString(),
      color: data['color']?.toString(),
      originalPrice: data['originalPrice']?.toDouble(),
      conditionScore: data['conditionScore'] is int ? data['conditionScore'] : (data['conditionScore'] != null ? int.tryParse(data['conditionScore'].toString()) : null),
      conditionDescription: data['conditionDescription']?.toString(),
      materialComposition: data['materialComposition'] is Map ? Map<String, dynamic>.from(data['materialComposition']) : null,
      estimatedValue: data['estimatedValue']?.toDouble(),
      processingType: data['processingType']?.toString(),
      processingNotes: data['processingNotes']?.toString(),
      donationStatus: data['donationStatus']?.toString() ?? '',
      pointsAwarded: data['pointsAwarded'] is int ? data['pointsAwarded'] : (data['pointsAwarded'] != null ? int.tryParse(data['pointsAwarded'].toString()) : null),
      convertedToItemId: data['convertedToItemId']?.toString(),
      images: data['images'] is List ? List<String>.from(data['images']) : null,
      createdAt: data['createdAt']?.toString() ?? '',
      updatedAt: data['updatedAt']?.toString() ?? '',
      valuatedAt: data['valuatedAt']?.toString(),
      acceptedAt: data['acceptedAt']?.toString(),
      processedAt: data['processedAt']?.toString(),
    );
  }
}

class DonationsService {
  DonationsService(this._api);
  final ApiClient _api;

  // Get all donations with pagination
  Future<Map<String, dynamic>> getAllDonations({int page = 0, int size = 20, String? status}) async {
    try {
      final params = <String, dynamic>{'page': page, 'size': size};
      if (status != null && status.isNotEmpty) params['status'] = status;
      
      final data = await _api.get('/api/donations', query: params);
      return data is Map<String, dynamic> ? data : {'content': [], 'totalPages': 0, 'totalElements': 0};
    } catch (e) {
      print('Error getting donations: $e');
      return {'content': [], 'totalPages': 0, 'totalElements': 0};
    }
  }

  // Get donation by ID
  Future<DonatedItem?> getDonationById(String id) async {
    try {
      final data = await _api.get('/api/donations/$id');
      final responseData = data is Map && data.containsKey('data') ? data['data'] : data;
      if (responseData is Map) {
        return DonatedItem.fromJson(Map<String, dynamic>.from(responseData));
      }
      return DonatedItem.fromJson({});
    } catch (e) {
      print('Error getting donation: $e');
      return null;
    }
  }

  // Get donations by status
  Future<Map<String, dynamic>> getDonationsByStatus(String status, {int page = 0, int size = 20}) async {
    try {
      final data = await _api.get('/api/donations/status/$status', query: {'page': page, 'size': size});
      return data is Map<String, dynamic> ? data : {'content': [], 'totalPages': 0, 'totalElements': 0};
    } catch (e) {
      print('Error getting donations by status: $e');
      return {'content': [], 'totalPages': 0, 'totalElements': 0};
    }
  }

  // Get donations by staff
  Future<Map<String, dynamic>> getDonationsByStaff(String staffId, {int page = 0, int size = 20}) async {
    try {
      final data = await _api.get('/api/donations/staff/$staffId', query: {'page': page, 'size': size});
      return data is Map<String, dynamic> ? data : {'content': [], 'totalPages': 0, 'totalElements': 0};
    } catch (e) {
      print('Error getting donations by staff: $e');
      return {'content': [], 'totalPages': 0, 'totalElements': 0};
    }
  }

  // Create donation
  Future<DonatedItem?> createDonation(Map<String, dynamic> donationData, String staffId) async {
    try {
      final data = await _api.post('/api/donations?staffId=$staffId', body: donationData);
      final responseData = data is Map && data.containsKey('data') ? data['data'] : data;
      if (responseData is Map) {
        return DonatedItem.fromJson(Map<String, dynamic>.from(responseData));
      }
      return DonatedItem.fromJson({});
    } catch (e) {
      print('Error creating donation: $e');
      return null;
    }
  }

  // Valuate donation
  Future<DonatedItem?> valuateDonation(String id, Map<String, dynamic> valuation, String staffId) async {
    try {
      final data = await _api.post('/api/donations/$id/valuate?staffId=$staffId', body: valuation);
      final responseData = data is Map && data.containsKey('data') ? data['data'] : data;
      if (responseData is Map) {
        return DonatedItem.fromJson(Map<String, dynamic>.from(responseData));
      }
      return DonatedItem.fromJson({});
    } catch (e) {
      print('Error valuating donation: $e');
      return null;
    }
  }

  // Accept donation
  Future<DonatedItem?> acceptDonation(String id, String staffId) async {
    try {
      final data = await _api.post('/api/donations/$id/accept?staffId=$staffId');
      final responseData = data is Map && data.containsKey('data') ? data['data'] : data;
      if (responseData is Map) {
        return DonatedItem.fromJson(Map<String, dynamic>.from(responseData));
      }
      return DonatedItem.fromJson({});
    } catch (e) {
      print('Error accepting donation: $e');
      return null;
    }
  }

  // Convert to item
  Future<Map<String, dynamic>?> convertToItem(String id, String staffId) async {
    try {
      final data = await _api.post('/api/donations/$id/convert-to-item?staffId=$staffId');
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error converting donation to item: $e');
      return null;
    }
  }

  // Search donations
  Future<Map<String, dynamic>> searchDonations(String keyword, {int page = 0, int size = 20}) async {
    try {
      final data = await _api.get('/api/donations/search', query: {'keyword': keyword, 'page': page, 'size': size});
      return data is Map<String, dynamic> ? data : {'content': [], 'totalPages': 0, 'totalElements': 0};
    } catch (e) {
      print('Error searching donations: $e');
      return {'content': [], 'totalPages': 0, 'totalElements': 0};
    }
  }

  // Get statistics
  Future<Map<String, dynamic>?> getDonationStatistics() async {
    try {
      final data = await _api.get('/api/donations/statistics');
      return data is Map<String, dynamic> ? data : null;
    } catch (e) {
      print('Error getting donation statistics: $e');
      return null;
    }
  }
}

