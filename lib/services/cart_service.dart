import 'package:flutter/foundation.dart';
import '../models/api_models.dart';

class CartItem {
  final String itemId;
  final String name;
  final int pointValue;
  final String? imageUrl;
  final String condition;
  final String size;
  final String? brand;
  int quantity;

  CartItem({
    required this.itemId,
    required this.name,
    required this.pointValue,
    this.imageUrl,
    required this.condition,
    required this.size,
    this.brand,
    this.quantity = 1,
  });

  int get totalPoints => pointValue * quantity;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'pointValue': pointValue,
      'imageUrl': imageUrl,
      'condition': condition,
      'size': size,
      'brand': brand,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      itemId: json['itemId'] ?? '',
      name: json['name'] ?? '',
      pointValue: json['pointValue'] ?? 0,
      imageUrl: json['imageUrl'],
      condition: json['condition'] ?? '',
      size: json['size'] ?? '',
      brand: json['brand'],
      quantity: json['quantity'] ?? 1,
    );
  }
}

class CartService extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  
  int get totalPoints => _items.fold(0, (sum, item) => sum + item.totalPoints);
  
  bool get isEmpty => _items.isEmpty;
  
  bool get isNotEmpty => _items.isNotEmpty;

  // Add item to cart
  void addItem(CartItem item) {
    // Check if item already exists
    final existingIndex = _items.indexWhere((i) => i.itemId == item.itemId);
    
    if (existingIndex >= 0) {
      // Item exists, increase quantity
      _items[existingIndex].quantity += item.quantity;
    } else {
      // New item, add to cart
      _items.add(item);
    }
    
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.itemId == itemId);
    notifyListeners();
  }

  // Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    
    final index = _items.indexWhere((item) => item.itemId == itemId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }

  // Increase quantity
  void increaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.itemId == itemId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String itemId) {
    final index = _items.indexWhere((item) => item.itemId == itemId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
        notifyListeners();
      } else {
        removeItem(itemId);
      }
    }
  }

  // Clear cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // Check if item is in cart
  bool isInCart(String itemId) {
    return _items.any((item) => item.itemId == itemId);
  }

  // Get item quantity
  int getItemQuantity(String itemId) {
    final item = _items.firstWhere(
      (item) => item.itemId == itemId,
      orElse: () => CartItem(
        itemId: '',
        name: '',
        pointValue: 0,
        condition: '',
        size: '',
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}



