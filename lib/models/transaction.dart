import 'package:flutter/foundation.dart';

enum TransactionType {
  sell,    // Khách hàng bán quần áo lấy điểm
  buy,     // Khách hàng dùng điểm mua quần áo
  exchange, // Đổi quần áo
}

enum TransactionStatus {
  pending,    // Chờ xử lý
  processing, // Đang xử lý
  completed,  // Hoàn thành
  cancelled,  // Đã hủy
}

class Transaction {
  final String id;
  final String customerId;
  final String? staffId;
  final TransactionType type;
  final TransactionStatus status;
  final List<String> clothingItemIds;
  final int totalPoints;
  final String? notes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata; // Thông tin bổ sung

  Transaction({
    required this.id,
    required this.customerId,
    this.staffId,
    required this.type,
    required this.status,
    required this.clothingItemIds,
    required this.totalPoints,
    this.notes,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      customerId: json['customerId'],
      staffId: json['staffId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${json['type']}',
        orElse: () => TransactionType.sell,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString() == 'TransactionStatus.${json['status']}',
        orElse: () => TransactionStatus.pending,
      ),
      clothingItemIds: List<String>.from(json['clothingItemIds'] ?? []),
      totalPoints: json['totalPoints'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'staffId': staffId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'clothingItemIds': clothingItemIds,
      'totalPoints': totalPoints,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case TransactionType.sell:
        return 'Bán quần áo';
      case TransactionType.buy:
        return 'Mua quần áo';
      case TransactionType.exchange:
        return 'Đổi quần áo';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TransactionStatus.pending:
        return 'Chờ xử lý';
      case TransactionStatus.processing:
        return 'Đang xử lý';
      case TransactionStatus.completed:
        return 'Hoàn thành';
      case TransactionStatus.cancelled:
        return 'Đã hủy';
    }
  }

  Transaction copyWith({
    String? id,
    String? customerId,
    String? staffId,
    TransactionType? type,
    TransactionStatus? status,
    List<String>? clothingItemIds,
    int? totalPoints,
    String? notes,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Transaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      staffId: staffId ?? this.staffId,
      type: type ?? this.type,
      status: status ?? this.status,
      clothingItemIds: clothingItemIds ?? this.clothingItemIds,
      totalPoints: totalPoints ?? this.totalPoints,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
