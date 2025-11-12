import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/auth_theme.dart';
import '../config/app_config.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  // Use config from app_config.dart (matches React FE .env)
  static const String _googleWebClientId = AppConfig.googleWebClientId;

  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final googleAuthService =
          Provider.of<GoogleAuthService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Initialize Google Sign-In with your web client ID
      // Note: serverClientId is only used on mobile, ignored on web
      googleAuthService.initialize(
        webClientId: _googleWebClientId,
        serverClientId: kIsWeb ? null : _googleWebClientId, // Only for mobile
      );

      // Perform Google Sign-In
      final result = await googleAuthService.signIn();

      if (!mounted) return;

      if (result.success && result.accessToken != null) {
        // Set the token in API client
        final apiClient = Provider.of<ApiClient>(context, listen: false);
        apiClient.setToken(result.accessToken!);

        // Save token to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', result.accessToken!);

        print('🔍 ========== GOOGLE LOGIN: FETCHING USER DETAILS ==========');
        
        // Fetch full user details from /api/auth/me
        try {
          final meResponse = await apiClient.get('/api/auth/me');
          print('🔍 Google Login - /api/auth/me response: $meResponse');
          
          final me = meResponse is Map && meResponse['data'] != null 
              ? meResponse['data'] 
              : meResponse;
          
          print('🔍 Google Login - Extracted me: $me');
          print('🔍 Google Login - Keys: ${me is Map ? me.keys.toList() : "not a map"}');
          
          // Parse role (ADMIN or STAFF)
          final roleStr = (me['role']?.toString() ?? 'CUSTOMER').toUpperCase();
          print('🔍 Google Login - Role from /me: $roleStr');
          
          // Map roles correctly: ADMIN -> admin, STAFF -> staff
          UserRole userRole;
          if (roleStr == 'ADMIN') {
            userRole = UserRole.admin;
          } else if (roleStr == 'STAFF') {
            userRole = UserRole.staff;
          } else {
            userRole = UserRole.customer;
          }
          print('🔍 Google Login - Mapped role: $userRole');
          
          // Parse points
          final pointsValue = me['sustainabilityPoints'] ?? me['points'] ?? 0;
          print('🔍 Google Login - Points from /me: $pointsValue (type: ${pointsValue.runtimeType})');
          final points = pointsValue is int 
              ? pointsValue 
              : int.tryParse(pointsValue.toString()) ?? 0;
          print('🔍 Google Login - Parsed points: $points');
          
          // Create user object with REAL data from /api/auth/me
          final user = User(
            id: (me['userId'] ?? result.userId ?? '').toString(),
            name: me['fullName'] ?? '${me['firstName'] ?? result.firstName ?? ''} ${me['lastName'] ?? result.lastName ?? ''}'.trim(),
            email: me['email'] ?? result.email ?? '',
            phone: me['phone']?.toString(),
            role: userRole,
            points: points,
            staffId: me['staffId']?.toString(),
            storeName: me['storeName']?.toString(),
            storeAddress: me['storeAddress']?.toString(),
          );

          print('🔍 Google Login - Final user object:');
          print('   Name: ${user.name}');
          print('   Role: ${user.role}');
          print('   Points: ${user.points}');
          print('🔍 ==================================================');

          // Update auth service
          authService.updateUser(user);
          
          // Ensure auth state is updated and listeners are notified
          // This will trigger the Consumer in main.dart to rebuild and show home page
          authService.notifyListeners();

          // Show success message with points
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng nhập thành công! Chào mừng ${user.name} - ${user.points} điểm'),
                backgroundColor: AuthTheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Wait for state to propagate
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Navigation is handled by auth guard in main.dart
              // No explicit navigation needed
            });
          }
        } catch (meError) {
          print('❌ Error fetching /api/auth/me: $meError');
          
          // Fallback: Create user from Google login response
          final user = User(
            id: result.userId ?? '',
            name: '${result.firstName ?? ''} ${result.lastName ?? ''}'.trim(),
            email: result.email ?? '',
            role: () {
              final roleStr = result.role?.toUpperCase() ?? 'CUSTOMER';
              if (roleStr == 'ADMIN') {
                return UserRole.admin;
              } else if (roleStr == 'STAFF') {
                return UserRole.staff;
              } else {
                return UserRole.customer;
              }
            }(),
            points: 0,
          );
          authService.updateUser(user);
          
          // Ensure auth state is updated
          authService.notifyListeners();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng nhập thành công! ${user.name}'),
                backgroundColor: AuthTheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Wait for state to propagate
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Navigation is handled by auth guard in main.dart
            });
          }
        }

        // If profile is incomplete, navigate to complete profile page
        if (result.isProfileComplete == false) {
          // TODO: Navigate to complete profile page
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vui lòng hoàn thiện thông tin cá nhân'),
                backgroundColor: AuthTheme.warning,
              ),
            );
          }
        }
      } else {
        // Show error message
        if (mounted) {
          if (kDebugMode) {
            print('📱 Showing error message: ${result.message}');
            print('📱 Contains DEVELOPER_ERROR: ${result.message.contains('DEVELOPER_ERROR')}');
            print('📱 Contains SHA-1: ${result.message.contains('SHA-1 fingerprint')}');
          }
          
          // Use AlertDialog for configuration errors (ApiException: 10)
          if (result.message.contains('DEVELOPER_ERROR') || 
              result.message.contains('SHA-1 fingerprint')) {
            if (kDebugMode) {
              print('📱 Showing AlertDialog for configuration error');
            }
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Lỗi cấu hình Google Sign-In'),
                content: SingleChildScrollView(
                  child: Text(
                    result.message,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Đã hiểu'),
                  ),
                ],
              ),
            );
          } else {
            // Use SnackBar for other errors
            if (kDebugMode) {
              print('📱 Showing SnackBar for error');
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: AuthTheme.destructive,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Đăng nhập Google thất bại';
      
      // Handle PlatformException (Google Sign-In errors)
      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('sign_in_failed')) {
          if (e.toString().contains('ApiException: 10')) {
            errorMessage = 'Lỗi cấu hình Google Sign-In (DEVELOPER_ERROR).\n'
                'Vui lòng thêm SHA-1 fingerprint vào Google Cloud Console:\n'
                'SHA-1: 1A:3F:98:FB:F2:2B:3F:9F:77:ED:49:1E:AE:BD:69:C2:91:37:59:F8\n'
                'Package: com.example.greenloop';
          } else {
            errorMessage = 'Đăng nhập Google thất bại. Vui lòng thử lại.';
          }
        } else {
          errorMessage = 'Lỗi: ${e.toString()}';
        }
      } else {
        errorMessage = 'Lỗi: ${e.toString()}';
        // Truncate very long error messages
        if (errorMessage.length > 200) {
          errorMessage = '${errorMessage.substring(0, 200)}...';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AuthTheme.destructive,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      
      if (kDebugMode) {
        print('❌ Google Sign-In Error: $e');
        print('❌ Error type: ${e.runtimeType}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AuthTheme.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AuthTheme.neutralStrong,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AuthTheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Icon (using emoji for now, you can replace with actual SVG)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AuthTheme.border),
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Đăng nhập với Google'),
                ],
              ),
      ),
    );
  }
}
