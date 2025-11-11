import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AuthService([this._api]);
  User? _currentUser;
  bool _isLoading = false;
  final ApiClient? _api;
  static const String _tokenKey = 'auth_token';

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isCustomer => _currentUser?.role == UserRole.customer;
  bool get isStaff => _currentUser?.role == UserRole.staff;
  bool get isAdmin => _currentUser?.role == UserRole.staff; // Staff has admin privileges
  Future<void> restoreSession() async {
    if (_api == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return;
    try {
      _api!.setToken(token);
      final meResponse = await _api!.get('/api/auth/me');
      print('🔍 Raw restoreSession /api/auth/me response: $meResponse');
      
      // Extract data from response wrapper
      final me = meResponse is Map && meResponse['data'] != null 
          ? meResponse['data'] 
          : meResponse;
      print('🔍 Extracted restoreSession me data: $me');
      
      final user = User(
        id: (me['id'] ?? me['userId'] ?? '').toString(),
        name: (me['name'] ?? me['fullName'] ?? '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim()).toString(),
        email: (me['email'] ?? '').toString(),
        phone: (me['phone'] ?? '').toString(),
        role: () {
          print('🔍 RestoreSession - Using extracted me object: $me');
          print('🔍 RestoreSession - me keys: ${me.keys.toList()}');
          final roleFromRole = me['role']?.toString().toLowerCase();
          final roleFromUserType = me['userType']?.toString().toLowerCase();
          print('🔍 RestoreSession - role field: ${me['role']} (type: ${me['role'].runtimeType})');
            print('🔍 RestoreSession - userType field: ${me['userType']} (type: ${me['userType'].runtimeType})');
            final roleStr = (roleFromRole ?? roleFromUserType ?? 'CUSTOMER').toUpperCase();
            print('🔍 RestoreSession - Final role (uppercase): $roleStr');
            // ADMIN and STAFF both map to UserRole.staff
            final isStaff = roleStr == 'STAFF' || roleStr == 'ADMIN';
            print('🔍 RestoreSession - Is staff/admin: $isStaff');
            return isStaff ? UserRole.staff : UserRole.customer;
          }(),
        points: () {
          final pointsValue = me['points'] ?? me['sustainabilityPoints'] ?? 0;
          print('🔍 RestoreSession - Points from API: $pointsValue (type: ${pointsValue.runtimeType})');
          final parsedPoints = pointsValue is int
              ? pointsValue
              : int.tryParse(pointsValue.toString()) ?? 0;
          print('🔍 RestoreSession - Parsed points: $parsedPoints');
          return parsedPoints;
        }(),
        staffId: me['staffId']?.toString(),
        storeName: me['storeName']?.toString(),
        storeAddress: me['storeAddress']?.toString(),
      );
      _currentUser = user;
      
      // Fetch real points from database after restoring session
      await refreshPoints();
      
      notifyListeners();
    } catch (_) {
      // invalid token → clear
      await prefs.remove(_tokenKey);
      _api!.setToken(null);
    }
  }

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

  // Đăng nhập: ưu tiên gọi API, fallback demo
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_api != null) {
        // Send only required fields to minimize 400s
        final data = await _api!.post('/api/auth/login', body: {
          'emailOrUsername': email,
          'password': password,
          'rememberMe': false,
        });

        // Token can be at data.accessToken or root.accessToken depending on API wrapper
        dynamic wrapper = data;
        if (wrapper is Map && wrapper['data'] is Map) {
          wrapper = wrapper['data'];
        }
        final token = (wrapper['accessToken'] ?? wrapper['token'] ?? '').toString();
        if (token.isEmpty) {
          throw ApiException(500, 'Missing access token from login response');
        }

        // Set token BEFORE calling /me
        _api!.setToken(token);
        // persist token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        final meResponse = await _api!.get('/api/auth/me');
        print('🔍 Raw /api/auth/me response: $meResponse');
        
        // Extract data from response wrapper
        final me = meResponse is Map && meResponse['data'] != null 
            ? meResponse['data'] 
            : meResponse;
        print('🔍 Extracted me data: $me');
        print('🔍 me is Map: ${me is Map}');
        print('🔍 me keys: ${me is Map ? me.keys.toList() : 'Not a Map'}');

        final user = User(
          id: (me['id'] ?? me['userId'] ?? '').toString(),
          name: (me['name'] ?? me['fullName'] ?? '${me['firstName'] ?? ''} ${me['lastName'] ?? ''}'.trim()).toString(),
          email: (me['email'] ?? email).toString(),
          phone: (me['phone'] ?? '').toString(),
          role: () {
            print('🔍 Login - Using extracted me object: $me');
            print('🔍 Login - me keys: ${me.keys.toList()}');
            final roleFromRole = me['role']?.toString().toUpperCase();
            final roleFromUserType = me['userType']?.toString().toUpperCase();
            print('🔍 Login - role field: ${me['role']} (type: ${me['role'].runtimeType})');
            print('🔍 Login - userType field: ${me['userType']} (type: ${me['userType'].runtimeType})');
            final roleStr = roleFromRole ?? roleFromUserType ?? 'CUSTOMER';
            print('🔍 Login - Final role (uppercase): $roleStr');
            // ADMIN and STAFF both map to UserRole.staff (for admin privileges)
            final isStaff = roleStr == 'STAFF' || roleStr == 'ADMIN';
            print('🔍 Login - Is staff/admin: $isStaff (will use staff role)');
            return isStaff ? UserRole.staff : UserRole.customer;
          }(),
          points: () {
            print('🔍 ========== PARSING POINTS ==========');
            print('🔍 Full me object keys: ${me.keys}');
            print('🔍 me["points"] = ${me['points']}');
            print('🔍 me["sustainabilityPoints"] = ${me['sustainabilityPoints']}');
            
            final pointsValue = me['sustainabilityPoints'] ?? me['points'] ?? 0;
            print('🔍 Selected points value: $pointsValue (type: ${pointsValue.runtimeType})');
            
            final parsedPoints = pointsValue is int
                ? pointsValue
                : int.tryParse(pointsValue.toString()) ?? 0;
            print('🔍 Final parsed points: $parsedPoints');
            print('🔍 =====================================');
            return parsedPoints;
          }(),
          staffId: me['staffId']?.toString(),
          storeName: me['storeName']?.toString(),
          storeAddress: me['storeAddress']?.toString(),
        );

        _currentUser = user;
        
        // Fetch real points from database after login
        await refreshPoints();
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Đăng ký: gọi API nếu có, fallback demo OK
  Future<bool> register(String name, String email, String password, String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_api != null) {
        // Map theo swagger
        final parts = name.trim().split(RegExp(r"\s+"));
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        final username = email.contains('@') ? email.split('@').first : email;

        await _api!.post('/api/auth/register', body: {
          'email': email,
          'password': password,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'userType': 'CONSUMER',
          'acceptTerms': true,
          'acceptPrivacy': true,
          'marketingConsent': false,
        }, timeout: const Duration(seconds: 45));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      // surface error message
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty && phone.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Đăng ký đầy đủ theo schema backend
  Future<bool> registerFull({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    String? dateOfBirth,
    String? gender,
    String userType = 'CONSUMER',
    String? bio,
    String? streetAddress,
    String? ward,
    String? district,
    String? city,
    String? province,
    String? postalCode,
    bool acceptTerms = true,
    bool acceptPrivacy = true,
    bool marketingConsent = false,
    String? referralCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_api != null) {
        final body = {
          'email': email,
          'password': password,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'userType': userType,
          'bio': bio,
          'streetAddress': streetAddress,
          'ward': ward,
          'district': district,
          'city': city,
          'province': province,
          'postalCode': postalCode,
          'acceptTerms': acceptTerms,
          'acceptPrivacy': acceptPrivacy,
          'marketingConsent': marketingConsent,
          'referralCode': referralCode,
        }..removeWhere((key, value) => value == null);

        await _api!.post('/api/auth/register', body: body, timeout: const Duration(seconds: 45));
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
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

  // Gửi lại email xác thực
  Future<bool> resendVerification(String email) async {
    if (_api == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      await _api!.post('/api/auth/resend-verification', query: { 'email': email });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Refresh points from API - using dedicated points endpoint like frontend
  Future<void> refreshPoints() async {
    if (_currentUser == null || _api == null) {
      print('⚠️ Cannot refresh points: currentUser=${_currentUser != null}, api=${_api != null}');
      return;
    }
    
    try {
      print('🔍 Refreshing points from dedicated API endpoint...');
      print('🔍 User ID: ${_currentUser!.id}');
      print('🔍 Calling: /api/points/${_currentUser!.id}/available');
      
      // Use the same endpoint as frontend: /api/points/{userId}/available
      final pointsResponse = await _api!.get('/api/points/${_currentUser!.id}/available');
      print('🔍 Refresh Points - Raw response: $pointsResponse');
      print('🔍 Refresh Points - Response type: ${pointsResponse.runtimeType}');
      
      // Extract points EXACTLY like frontend: response.data.data ?? response.data ?? 0
      // Frontend code: const points = response.data.data ?? response.data ?? 0;
      dynamic pointsValue;
      
      if (pointsResponse is Map) {
        print('🔍 Response is Map with keys: ${pointsResponse.keys.toList()}');
        
        // First try response.data.data (nested data field like frontend)
        if (pointsResponse.containsKey('data')) {
          final dataField = pointsResponse['data'];
          if (dataField is Map && dataField.containsKey('data')) {
            // Nested data structure: { data: { data: <points> } }
            pointsValue = dataField['data'];
            print('🔍 Found nested data.data field: $pointsValue');
          } else if (dataField is int || dataField is double) {
            // Direct data field: { data: <points> }
            pointsValue = dataField;
            print('🔍 Found direct data field: $pointsValue');
          } else {
            // Try response.data itself
            pointsValue = dataField;
            print('🔍 Using data field as-is: $pointsValue');
          }
        } else {
          // Fallback: use entire response (shouldn't happen with proper API)
          pointsValue = pointsResponse;
          print('🔍 No data field, using entire response: $pointsValue');
        }
      } else if (pointsResponse is int || pointsResponse is double) {
        // Direct numeric response
        pointsValue = pointsResponse;
        print('🔍 Direct numeric response: $pointsValue');
      } else {
        pointsValue = 0;
        print('⚠️ Unexpected response format, defaulting to 0');
      }
      
      print('🔍 Refresh Points - Points value: $pointsValue (type: ${pointsValue.runtimeType})');
      
      final parsedPoints = pointsValue is int
          ? pointsValue
          : (pointsValue is double
              ? pointsValue.toInt()
              : int.tryParse(pointsValue.toString()) ?? 0);
      
      print('✅ Refresh Points - Successfully loaded: $parsedPoints points');
      print('🔍 Current user points before update: ${_currentUser!.points}');
      
      updatePoints(parsedPoints);
      
      print('🔍 Current user points after update: ${_currentUser!.points}');
    } catch (e, stackTrace) {
      print('❌ Refresh Points - Error: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Fallback: try to get from /api/auth/me
      try {
        print('🔄 Trying fallback method from /api/auth/me...');
        final meResponse = await _api!.get('/api/auth/me');
        print('🔄 Fallback response: $meResponse');
        
        final me = meResponse is Map && meResponse['data'] != null 
            ? meResponse['data'] 
            : meResponse;
        
        final pointsValue = me['sustainabilityPoints'] ?? me['points'] ?? 0;
        print('🔄 Fallback points value: $pointsValue');
        
        final parsedPoints = pointsValue is int
            ? pointsValue
            : int.tryParse(pointsValue.toString()) ?? 0;
        
        updatePoints(parsedPoints);
        print('✅ Fallback method successful: $parsedPoints points');
      } catch (fallbackError, fallbackStack) {
        print('❌ Fallback also failed: $fallbackError');
        print('❌ Fallback stack: $fallbackStack');
      }
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
    _api?.setToken(null);
    SharedPreferences.getInstance().then((p) => p.remove(_tokenKey));
    notifyListeners();
  }

  // Cập nhật thông tin người dùng
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
