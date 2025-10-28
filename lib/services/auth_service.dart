import 'package:flutter/foundation.dart';

enum UserRole { customer, staff }

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final int points; // Số điểm hiện tại
  final String? staffId; // ID nhân viên (nếu là staff)
  final String? storeName; // Tên cửa hàng (nếu là staff)
  final String? storeAddress; // Địa chỉ cửa hàng (nếu là staff)

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.points = 0,
    this.staffId,
    this.storeName,
    this.storeAddress,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${json['role']}',
        orElse: () => UserRole.customer,
      ),
      points: json['points'] ?? 0,
      staffId: json['staffId'],
      storeName: json['storeName'],
      storeAddress: json['storeAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.toString().split('.').last,
      'points': points,
      'staffId': staffId,
      'storeName': storeName,
      'storeAddress': storeAddress,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    int? points,
    String? staffId,
    String? storeName,
    String? storeAddress,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      points: points ?? this.points,
      staffId: staffId ?? this.staffId,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
    );
  }
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isStaff => _currentUser?.role == UserRole.staff;

  // Demo accounts (email -> (password, user))
  final Map<String, ({String password, User user})> _demoAccounts = {
    'customer@demo.com': (
      password: '123456',
      user: User(
        id: '1',
        name: 'Khách hàng Demo',
        email: 'customer@demo.com',
        phone: '0123456789',
        role: UserRole.customer,
        points: 1000,
      ),
    ),
    'staff@demo.com': (
      password: '123456',
      user: User(
        id: '2',
        name: 'Nhân viên Demo',
        email: 'staff@demo.com',
        phone: '0987654321',
        role: UserRole.staff,
        staffId: 'ST001',
        storeName: 'Cửa hàng Thu mua Quần áo Xanh',
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
  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    notifyListeners();

    // Giả lập delay
    await Future.delayed(const Duration(seconds: 2));

    // Giả lập tạo tài khoản mới
    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty && phone.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Cập nhật điểm cho người dùng
  void updatePoints(int newPoints) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(points: newPoints);
      notifyListeners();
    }
  }

  // Thêm điểm cho người dùng
  void addPoints(int points) {
    if (_currentUser != null) {
      updatePoints(_currentUser!.points + points);
    }
  }

  // Trừ điểm khi mua hàng
  bool deductPoints(int points) {
    if (_currentUser != null && _currentUser!.points >= points) {
      updatePoints(_currentUser!.points - points);
      return true;
    }
    return false;
  }

  // Nạp điểm (giả lập)
  Future<bool> rechargePoints(int amount) async {
    if (_currentUser != null && amount > 0) {
      _isLoading = true;
      notifyListeners();
      
      // Giả lập delay
      await Future.delayed(const Duration(seconds: 2));
      
      addPoints(amount);
      _isLoading = false;
      notifyListeners();
      return true;
    }
    return false;
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
