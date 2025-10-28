import 'package:flutter/foundation.dart';
import '../models/clothing_item.dart';
import '../models/transaction.dart';

class ClothingService extends ChangeNotifier {
  final List<ClothingItem> _clothingItems = [];
  final List<Transaction> _transactions = [];

  List<ClothingItem> get clothingItems => _clothingItems.where((item) => item.isAvailable).toList();
  List<Transaction> get transactions => List.unmodifiable(_transactions);

  // Khởi tạo dữ liệu demo
  void initializeDemoData() {
    _clothingItems.clear();
    _transactions.clear();

    // Thêm một số quần áo demo
    _clothingItems.addAll([
      ClothingItem(
        id: '1',
        name: 'Áo sơ mi trắng',
        description: 'Áo sơ mi trắng chất liệu cotton, form dáng đẹp',
        category: ClothingCategory.shirt,
        condition: ClothingCondition.excellent,
        size: 'M',
        brand: 'Uniqlo',
        color: 'Trắng',
        images: [],
        pointValue: 500,
        originalPrice: 299000,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        customerId: '1',
        staffId: 'ST001',
      ),
      ClothingItem(
        id: '2',
        name: 'Quần jean xanh',
        description: 'Quần jean xanh đậm, kiểu dáng slim fit',
        category: ClothingCategory.pants,
        condition: ClothingCondition.good,
        size: 'L',
        brand: 'Levi\'s',
        color: 'Xanh',
        images: [],
        pointValue: 800,
        originalPrice: 899000,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        customerId: '1',
        staffId: 'ST001',
      ),
      ClothingItem(
        id: '3',
        name: 'Váy đen dài',
        description: 'Váy đen dài, phù hợp cho các dịp trang trọng',
        category: ClothingCategory.dress,
        condition: ClothingCondition.excellent,
        size: 'S',
        brand: 'Zara',
        color: 'Đen',
        images: [],
        pointValue: 1200,
        originalPrice: 1299000,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        customerId: '1',
        staffId: 'ST001',
      ),
      ClothingItem(
        id: '4',
        name: 'Áo khoác denim',
        description: 'Áo khoác denim cổ điển, phong cách vintage',
        category: ClothingCategory.jacket,
        condition: ClothingCondition.fair,
        size: 'M',
        brand: 'H&M',
        color: 'Xanh',
        images: [],
        pointValue: 600,
        originalPrice: 599000,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        customerId: '1',
        staffId: 'ST001',
      ),
      ClothingItem(
        id: '5',
        name: 'Giày sneaker trắng',
        description: 'Giày sneaker trắng, phong cách thể thao',
        category: ClothingCategory.shoes,
        condition: ClothingCondition.good,
        size: '42',
        brand: 'Nike',
        color: 'Trắng',
        images: [],
        pointValue: 1000,
        originalPrice: 1999000,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        customerId: '1',
        staffId: 'ST001',
      ),
    ]);

    // Thêm một số giao dịch demo
    _transactions.addAll([
      Transaction(
        id: 'TXN001',
        customerId: '1',
        staffId: 'ST001',
        type: TransactionType.sell,
        status: TransactionStatus.completed,
        clothingItemIds: ['1', '2'],
        totalPoints: 1300,
        notes: 'Bán áo sơ mi và quần jean',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        completedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Transaction(
        id: 'TXN002',
        customerId: '1',
        staffId: 'ST001',
        type: TransactionType.buy,
        status: TransactionStatus.completed,
        clothingItemIds: ['3'],
        totalPoints: 1200,
        notes: 'Mua váy đen bằng điểm',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ]);

    notifyListeners();
  }

  // Lấy quần áo theo danh mục
  List<ClothingItem> getClothingByCategory(ClothingCategory category) {
    return _clothingItems.where((item) => 
        item.category == category && item.isAvailable).toList();
  }

  // Tìm kiếm quần áo
  List<ClothingItem> searchClothing(String query) {
    if (query.isEmpty) return clothingItems;
    
    return _clothingItems.where((item) => 
        item.isAvailable && (
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.brand.toLowerCase().contains(query.toLowerCase()) ||
          item.color.toLowerCase().contains(query.toLowerCase()) ||
          item.categoryDisplayName.toLowerCase().contains(query.toLowerCase())
        )).toList();
  }

  // Lấy quần áo theo ID
  ClothingItem? getClothingById(String id) {
    try {
      return _clothingItems.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  // Thêm quần áo mới (dành cho staff)
  void addClothingItem(ClothingItem item) {
    _clothingItems.add(item);
    notifyListeners();
  }

  // Cập nhật quần áo
  void updateClothingItem(ClothingItem updatedItem) {
    final index = _clothingItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _clothingItems[index] = updatedItem;
      notifyListeners();
    }
  }

  // Xóa quần áo (đánh dấu không có sẵn)
  void removeClothingItem(String id) {
    final index = _clothingItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _clothingItems[index] = _clothingItems[index].copyWith(isAvailable: false);
      notifyListeners();
    }
  }

  // Tạo giao dịch mới
  void createTransaction(Transaction transaction) {
    _transactions.add(transaction);
    notifyListeners();
  }

  // Cập nhật trạng thái giao dịch
  void updateTransactionStatus(String transactionId, TransactionStatus status) {
    final index = _transactions.indexWhere((txn) => txn.id == transactionId);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        status: status,
        completedAt: status == TransactionStatus.completed ? DateTime.now() : null,
      );
      notifyListeners();
    }
  }

  // Lấy giao dịch theo khách hàng
  List<Transaction> getTransactionsByCustomer(String customerId) {
    return _transactions.where((txn) => txn.customerId == customerId).toList();
  }

  // Lấy giao dịch theo nhân viên
  List<Transaction> getTransactionsByStaff(String staffId) {
    return _transactions.where((txn) => txn.staffId == staffId).toList();
  }

  // Tính điểm dựa trên tình trạng quần áo
  int calculatePoints(ClothingItem item) {
    int basePoints = 0;
    
    // Điểm cơ bản theo danh mục
    switch (item.category) {
      case ClothingCategory.shirt:
        basePoints = 300;
        break;
      case ClothingCategory.pants:
        basePoints = 400;
        break;
      case ClothingCategory.dress:
        basePoints = 500;
        break;
      case ClothingCategory.jacket:
        basePoints = 600;
        break;
      case ClothingCategory.shoes:
        basePoints = 700;
        break;
      case ClothingCategory.accessories:
        basePoints = 200;
        break;
      case ClothingCategory.other:
        basePoints = 250;
        break;
    }

    // Hệ số theo tình trạng
    double conditionMultiplier = 1.0;
    switch (item.condition) {
      case ClothingCondition.excellent:
        conditionMultiplier = 1.0;
        break;
      case ClothingCondition.good:
        conditionMultiplier = 0.8;
        break;
      case ClothingCondition.fair:
        conditionMultiplier = 0.6;
        break;
      case ClothingCondition.poor:
        conditionMultiplier = 0.4;
        break;
    }

    return (basePoints * conditionMultiplier).round();
  }

  // Tạo quần áo từ thông tin khách hàng bán
  ClothingItem createClothingFromSell({
    required String name,
    required String description,
    required ClothingCategory category,
    required ClothingCondition condition,
    required String size,
    required String brand,
    required String color,
    required String customerId,
    required String staffId,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final basePoints = calculatePoints(ClothingItem(
      id: id,
      name: name,
      description: description,
      category: category,
      condition: condition,
      size: size,
      brand: brand,
      color: color,
      images: [],
      pointValue: 0,
      originalPrice: 0,
      createdAt: DateTime.now(),
    ));

    return ClothingItem(
      id: id,
      name: name,
      description: description,
      category: category,
      condition: condition,
      size: size,
      brand: brand,
      color: color,
      images: [],
      pointValue: basePoints,
      originalPrice: basePoints * 1000, // Giả sử 1 điểm = 1000 VND
      createdAt: DateTime.now(),
      customerId: customerId,
      staffId: staffId,
    );
  }
}
