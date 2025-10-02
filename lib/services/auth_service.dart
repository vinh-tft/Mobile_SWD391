import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final bool isSeller;
  final String? storeName;
  final String? storeCategory;
  final String? storeAddress;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.isSeller = false,
    this.storeName,
    this.storeCategory,
    this.storeAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      isSeller: json['isSeller'] ?? false,
      storeName: json['storeName'],
      storeCategory: json['storeCategory'],
      storeAddress: json['storeAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'isSeller': isSeller,
      'storeName': storeName,
      'storeCategory': storeCategory,
      'storeAddress': storeAddress,
    };
  }
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSeller => _currentUser?.isSeller ?? false;

  // Demo accounts (email -> (password, user))
  final Map<String, ({String password, User user})> _demoAccounts = {
    'user@demo.com': (
      password: '123456',
      user: User(
        id: '1',
        name: 'Người dùng Demo',
        email: 'user@demo.com',
        phone: '0123456789',
        isSeller: false,
      ),
    ),
    'seller@demo.com': (
      password: '123456',
      user: User(
        id: '2',
        name: 'Người bán Demo',
        email: 'seller@demo.com',
        phone: '0987654321',
        isSeller: true,
        storeName: 'Cửa hàng Demo',
        storeCategory: 'Thời trang',
        storeAddress: '123 Đường ABC, Quận 1, TP.HCM',
      ),
    ),
  };

  // Giả lập đăng nhập (kiểm tra theo tài khoản demo)
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập delay
    await Future.delayed(const Duration(seconds: 2));

    // Kiểm tra thông tin đăng nhập dựa trên tài khoản demo
    final demo = _demoAccounts[email];
    if (demo != null && password == demo.password) {
      _currentUser = demo.user;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Giả lập đăng ký
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập delay
    await Future.delayed(const Duration(seconds: 2));

    // Giả lập tạo tài khoản mới
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Giả lập đăng ký bán hàng
  Future<bool> registerSeller({
    required String ownerName,
    required String email,
    required String password,
    required String phone,
    required String storeName,
    required String storeCategory,
    required String storeAddress,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập delay
    await Future.delayed(const Duration(seconds: 3));

    // Giả lập tạo tài khoản người bán
    if (ownerName.isNotEmpty && email.isNotEmpty && password.isNotEmpty && 
        phone.isNotEmpty && storeName.isNotEmpty && storeCategory.isNotEmpty && 
        storeAddress.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Đăng nhập với tài khoản người bán (sử dụng cùng nguồn demo)
  Future<bool> loginAsSeller(String email, String password) async {
    return login(email, password);
  }

  // Đăng xuất
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Cập nhật thông tin người dùng
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
