import 'package:flutter/foundation.dart';

enum ClothingCategory {
  shirt,
  pants,
  dress,
  jacket,
  shoes,
  accessories,
  other,
}

enum ClothingCondition {
  excellent, // Xuất sắc
  good,      // Tốt
  fair,      // Khá
  poor,      // Kém
}

class ClothingItem {
  final String id;
  final String name;
  final String description;
  final ClothingCategory category;
  final ClothingCondition condition;
  final String size;
  final String brand;
  final String color;
  final List<String> images;
  final int pointValue; // Giá trị điểm
  final int originalPrice; // Giá gốc (để tham khảo)
  final DateTime createdAt;
  final String? customerId; // ID khách hàng bán (nếu có)
  final String? staffId; // ID nhân viên xử lý (nếu có)
  final bool isAvailable; // Còn có sẵn để mua không

  ClothingItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.size,
    required this.brand,
    required this.color,
    required this.images,
    required this.pointValue,
    required this.originalPrice,
    required this.createdAt,
    this.customerId,
    this.staffId,
    this.isAvailable = true,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: ClothingCategory.values.firstWhere(
        (e) => e.toString() == 'ClothingCategory.${json['category']}',
        orElse: () => ClothingCategory.other,
      ),
      condition: ClothingCondition.values.firstWhere(
        (e) => e.toString() == 'ClothingCondition.${json['condition']}',
        orElse: () => ClothingCondition.fair,
      ),
      size: json['size'],
      brand: json['brand'],
      color: json['color'],
      images: List<String>.from(json['images'] ?? []),
      pointValue: json['pointValue'],
      originalPrice: json['originalPrice'],
      createdAt: DateTime.parse(json['createdAt']),
      customerId: json['customerId'],
      staffId: json['staffId'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.toString().split('.').last,
      'condition': condition.toString().split('.').last,
      'size': size,
      'brand': brand,
      'color': color,
      'images': images,
      'pointValue': pointValue,
      'originalPrice': originalPrice,
      'createdAt': createdAt.toIso8601String(),
      'customerId': customerId,
      'staffId': staffId,
      'isAvailable': isAvailable,
    };
  }

  String get categoryDisplayName {
    switch (category) {
      case ClothingCategory.shirt:
        return 'Áo';
      case ClothingCategory.pants:
        return 'Quần';
      case ClothingCategory.dress:
        return 'Váy';
      case ClothingCategory.jacket:
        return 'Áo khoác';
      case ClothingCategory.shoes:
        return 'Giày';
      case ClothingCategory.accessories:
        return 'Phụ kiện';
      case ClothingCategory.other:
        return 'Khác';
    }
  }

  String get conditionDisplayName {
    switch (condition) {
      case ClothingCondition.excellent:
        return 'Xuất sắc';
      case ClothingCondition.good:
        return 'Tốt';
      case ClothingCondition.fair:
        return 'Khá';
      case ClothingCondition.poor:
        return 'Kém';
    }
  }

  ClothingItem copyWith({
    String? id,
    String? name,
    String? description,
    ClothingCategory? category,
    ClothingCondition? condition,
    String? size,
    String? brand,
    String? color,
    List<String>? images,
    int? pointValue,
    int? originalPrice,
    DateTime? createdAt,
    String? customerId,
    String? staffId,
    bool? isAvailable,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      size: size ?? this.size,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      images: images ?? this.images,
      pointValue: pointValue ?? this.pointValue,
      originalPrice: originalPrice ?? this.originalPrice,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      staffId: staffId ?? this.staffId,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
