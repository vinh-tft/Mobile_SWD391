// API Models matching Green Loop API schema

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String timestamp;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.errors,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : json['data'],
      timestamp: json['timestamp'] ?? '',
      errors: json['errors'] != null ? Map<String, dynamic>.from(json['errors']) : null,
    );
  }
}

// Category Models
class CategoryResponse {
  final String categoryId;
  final String name;
  final String slug;
  final String description;
  final String? parentCategoryId;
  final String? parentCategoryName;
  final List<String> subCategories;
  final int displayOrder;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final bool isRootCategory;
  final bool hasSubCategories;
  final String fullPath;
  final int level;
  final int totalItems;

  CategoryResponse({
    required this.categoryId,
    required this.name,
    required this.slug,
    required this.description,
    this.parentCategoryId,
    this.parentCategoryName,
    required this.subCategories,
    required this.displayOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.isRootCategory,
    required this.hasSubCategories,
    required this.fullPath,
    required this.level,
    required this.totalItems,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      parentCategoryId: json['parentCategoryId'],
      parentCategoryName: json['parentCategoryName'],
      subCategories: List<String>.from(json['subCategories'] ?? []),
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isRootCategory: json['isRootCategory'] ?? false,
      hasSubCategories: json['hasSubCategories'] ?? false,
      fullPath: json['fullPath'] ?? '',
      level: json['level'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class CategoryCreateRequest {
  final String name;
  final String description;
  final String? parentCategoryId;
  final int displayOrder;
  final bool isActive;

  CategoryCreateRequest({
    required this.name,
    required this.description,
    this.parentCategoryId,
    this.displayOrder = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (parentCategoryId != null) 'parentCategoryId': parentCategoryId,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}

// Brand Models
class BrandResponse {
  final String brandId;
  final String name;
  final String slug;
  final String description;
  final String? logoUrl;
  final String? websiteUrl;
  final bool isVerified;
  final bool isSustainable;
  final bool isPartner;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final int totalItems;

  BrandResponse({
    required this.brandId,
    required this.name,
    required this.slug,
    required this.description,
    this.logoUrl,
    this.websiteUrl,
    required this.isVerified,
    required this.isSustainable,
    required this.isPartner,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.totalItems,
  });

  factory BrandResponse.fromJson(Map<String, dynamic> json) {
    return BrandResponse(
      brandId: json['brandId'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      logoUrl: json['logoUrl'],
      websiteUrl: json['websiteUrl'],
      isVerified: json['isVerified'] ?? false,
      isSustainable: json['isSustainable'] ?? false,
      isPartner: json['isPartner'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      totalItems: json['totalItems'] ?? 0,
    );
  }
}

class BrandCreateRequest {
  final String name;
  final String description;
  final String? logoUrl;
  final String? websiteUrl;
  final bool isVerified;
  final bool isSustainable;
  final bool isPartner;
  final bool isActive;

  BrandCreateRequest({
    required this.name,
    required this.description,
    this.logoUrl,
    this.websiteUrl,
    this.isVerified = false,
    this.isSustainable = false,
    this.isPartner = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (websiteUrl != null) 'websiteUrl': websiteUrl,
      'isVerified': isVerified,
      'isSustainable': isSustainable,
      'isPartner': isPartner,
      'isActive': isActive,
    };
  }
}

// Item Models
enum ItemStatus {
  DRAFT,
  PENDING_VERIFICATION,
  VERIFIED,
  REJECTED,
  SOLD,
  UNAVAILABLE,
  DELETED
}

enum ItemCondition {
  EXCELLENT,
  GOOD,
  FAIR,
  POOR
}

class ItemResponse {
  final String itemId;
  final String name;
  final String description;
  final String categoryId;
  final String? brandId;
  final String? brandName;
  final String size;
  final String color;
  final ItemCondition condition;
  final ItemStatus status;
  final int pointValue;
  final int? originalPrice;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> tags;
  final String ownerId;
  final String ownerName;
  final String? verifiedBy;
  final String? verifiedAt;
  final String createdAt;
  final String updatedAt;
  final bool isMarketplaceReady;
  final int viewCount;
  final int likeCount;

  ItemResponse({
    required this.itemId,
    required this.name,
    required this.description,
    required this.categoryId,
    this.brandId,
    this.brandName,
    required this.size,
    required this.color,
    required this.condition,
    required this.status,
    required this.pointValue,
    this.originalPrice,
    required this.imageUrls,
    required this.videoUrls,
    required this.tags,
    required this.ownerId,
    required this.ownerName,
    this.verifiedBy,
    this.verifiedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isMarketplaceReady,
    required this.viewCount,
    required this.likeCount,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['categoryId'] ?? '',
      brandId: json['brandId'],
      brandName: json['brandName'],
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      condition: ItemCondition.values.firstWhere(
        (e) => e.toString().split('.').last == json['condition'],
        orElse: () => ItemCondition.GOOD,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.DRAFT,
      ),
      pointValue: json['pointValue'] ?? 0,
      originalPrice: json['originalPrice'],
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      videoUrls: List<String>.from(json['videoUrls'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      ownerId: json['ownerId'] ?? '',
      ownerName: json['ownerName'] ?? '',
      verifiedBy: json['verifiedBy'],
      verifiedAt: json['verifiedAt'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      isMarketplaceReady: json['isMarketplaceReady'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
    );
  }
}

class ItemCreateRequest {
  final String name;
  final String description;
  final String categoryId;
  final String? brandId;
  final String size;
  final String color;
  final ItemCondition condition;
  final int pointValue;
  final int? originalPrice;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final List<String> tags;

  ItemCreateRequest({
    required this.name,
    required this.description,
    required this.categoryId,
    this.brandId,
    required this.size,
    required this.color,
    required this.condition,
    required this.pointValue,
    this.originalPrice,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      if (brandId != null) 'brandId': brandId,
      'size': size,
      'color': color,
      'condition': condition.toString().split('.').last,
      'pointValue': pointValue,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'tags': tags,
    };
  }
}

class ItemSummaryResponse {
  final String itemId;
  final String name;
  final String description;
  final String categoryName;
  final String? brandName;
  final String size;
  final String color;
  final ItemCondition condition;
  final ItemStatus status;
  final int pointValue;
  final int? originalPrice;
  final String? primaryImageUrl;
  final int imageCount;
  final List<String> tags;
  final String ownerName;
  final String createdAt;
  final bool isMarketplaceReady;
  final int viewCount;
  final int likeCount;

  ItemSummaryResponse({
    required this.itemId,
    required this.name,
    required this.description,
    required this.categoryName,
    this.brandName,
    required this.size,
    required this.color,
    required this.condition,
    required this.status,
    required this.pointValue,
    this.originalPrice,
    this.primaryImageUrl,
    required this.imageCount,
    required this.tags,
    required this.ownerName,
    required this.createdAt,
    required this.isMarketplaceReady,
    required this.viewCount,
    required this.likeCount,
  });

  factory ItemSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ItemSummaryResponse(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      categoryName: json['categoryName'] ?? '',
      brandName: json['brandName'],
      size: json['size'] ?? '',
      color: json['color'] ?? '',
      condition: ItemCondition.values.firstWhere(
        (e) => e.toString().split('.').last == json['condition'],
        orElse: () => ItemCondition.GOOD,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ItemStatus.DRAFT,
      ),
      pointValue: json['pointValue'] ?? 0,
      originalPrice: json['originalPrice'],
      primaryImageUrl: json['primaryImageUrl'],
      imageCount: json['imageCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      ownerName: json['ownerName'] ?? '',
      createdAt: json['createdAt'] ?? '',
      isMarketplaceReady: json['isMarketplaceReady'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
    );
  }
}

// Sale Models
class SaleCreateRequest {
  final String name;
  final String description;
  final int quantity;
  final int price;

  SaleCreateRequest({
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'quantity': quantity,
      'price': price,
    };
  }
}

class SaleResponse {
  final String saleId;
  final String name;
  final String description;
  final int quantity;
  final int price;
  final String createdAt;
  final String updatedAt;

  SaleResponse({
    required this.saleId,
    required this.name,
    required this.description,
    required this.quantity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleResponse.fromJson(Map<String, dynamic> json) {
    return SaleResponse(
      saleId: (json['saleId'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }
}

// Pagination Models
class Pageable {
  final int page;
  final int size;
  final String? sort;
  final String? direction;

  Pageable({
    this.page = 0,
    this.size = 20,
    this.sort,
    this.direction,
  });

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'size': size,
      if (sort != null) 'sort': sort,
      if (direction != null) 'direction': direction,
    };
  }
}

class PageResponse<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;
  final bool first;
  final bool last;
  final int numberOfElements;

  PageResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
    required this.first,
    required this.last,
    required this.numberOfElements,
  });

  factory PageResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return PageResponse<T>(
      content: (json['content'] as List).map((item) => fromJsonT(item)).toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 0,
      number: json['number'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
      numberOfElements: json['numberOfElements'] ?? 0,
    );
  }
}
