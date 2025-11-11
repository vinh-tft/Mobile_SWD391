import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/google_auth_service.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../theme/auth_theme.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  static const String _googleWebClientId =
      '1093884420538-ka17a3efctfkv117f1lqotu4uusgokn9.apps.googleusercontent.com';

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
          final isStaffOrAdmin = roleStr == 'STAFF' || roleStr == 'ADMIN';
          print('🔍 Google Login - Is staff/admin: $isStaffOrAdmin');
          
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
            role: isStaffOrAdmin ? UserRole.staff : UserRole.customer,
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

          // Show success message with points
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng nhập thành công! Chào mừng ${user.name} - ${user.points} điểm'),
                backgroundColor: AuthTheme.primary,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } catch (meError) {
          print('❌ Error fetching /api/auth/me: $meError');
          
          // Fallback: Create user from Google login response
          final user = User(
            id: result.userId ?? '',
            name: '${result.firstName ?? ''} ${result.lastName ?? ''}'.trim(),
            email: result.email ?? '',
            role: result.role?.toUpperCase() == 'ADMIN' || result.role?.toUpperCase() == 'STAFF'
                ? UserRole.staff
                : UserRole.customer,
            points: 0,
          );
          authService.updateUser(user);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đăng nhập thành công! ${user.name}'),
                backgroundColor: AuthTheme.primary,
              ),
            );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AuthTheme.destructive,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AuthTheme.destructive,
          ),
        );
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
