import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'api_client.dart';

class GoogleAuthService {
  GoogleAuthService(this._api);

  final ApiClient _api;
  late final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;

  // Initialize Google Sign-In with appropriate client IDs
  void initialize({String? webClientId, String? serverClientId}) {
    if (_isInitialized) return;

    final bool isWeb = kIsWeb;
    
    // IMPORTANT: On web, serverClientId is NOT supported!
    // Web uses only clientId for OAuth flow and ID token generation
    // Mobile uses serverClientId to get ID tokens for backend verification
    final String? resolvedWebClientId = isWeb ? webClientId : null;
    final String? resolvedServerClientId = isWeb ? null : (serverClientId ?? webClientId);

    if (kDebugMode) {
      print('🔧 Initializing Google Sign-In');
      print('  Platform: ${isWeb ? "Web" : "Mobile"}');
      if (isWeb) {
        print('  Web Client ID: ${resolvedWebClientId ?? "from meta tag"}');
        print('  ⚠️  serverClientId is NOT used on web (not supported)');
      } else {
        print('  Server Client ID: $resolvedServerClientId');
      }
    }

    _googleSignIn = GoogleSignIn(
      scopes: [
        'openid', // Required to get ID token
        'email',
        'profile',
      ],
      // On web: Use clientId from meta tag OR explicit parameter
      clientId: resolvedWebClientId,
      // CRITICAL: serverClientId is ONLY for mobile platforms!
      // On web, this MUST be null or it will throw an assertion error
      serverClientId: resolvedServerClientId,
    );

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
    });

    _isInitialized = true;
  }

  // Sign in with Google
  Future<GoogleSignInResult> signIn() async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // User canceled the sign-in
        return GoogleSignInResult(
          success: false,
          message: 'Đăng nhập bị hủy',
        );
      }

      // Get authentication details
      if (kDebugMode) {
        print('📱 Getting authentication tokens from Google...');
      }
      
      final GoogleSignInAuthentication auth = await account.authentication;
      String? idToken = auth.idToken;
      String? accessToken = auth.accessToken;

      if (kDebugMode) {
        print('  From auth object - idToken: ${idToken != null}, accessToken: ${accessToken != null}');
      }

      if (idToken == null || accessToken == null) {
        if (kDebugMode) {
          print('⚠️ Tokens missing, trying platform interface...');
        }
        try {
          final tokenData = await GoogleSignInPlatform.instance
              .getTokens(email: account.email);
          idToken ??= tokenData.idToken;
          accessToken ??= tokenData.accessToken;
          if (kDebugMode) {
            print('  From platform - idToken: ${idToken != null}, accessToken: ${accessToken != null}');
          }
        } catch (tokenError) {
          if (kDebugMode) {
            print('❌ Platform interface failed: $tokenError');
          }
        }
      }

      if (kDebugMode) {
        print('');
        print('🔐 Google Auth Debug Summary:');
        print('  Account email: ${account.email}');
        print('  Has ID token: ${idToken != null}');
        print('  Has access token: ${accessToken != null}');
        if (idToken != null) {
          print('  ID token (first 50 chars): ${idToken.substring(0, idToken.length > 50 ? 50 : idToken.length)}...');
        } else {
          print('  ❌ NO ID TOKEN! This means:');
          print('     1. serverClientId might not be set correctly');
          print('     2. OAuth consent screen not configured properly');
          print('     3. Try signing out and back in');
        }
        print('');
      }

      // On web, we might only have accessToken (no idToken)
      // Send whichever token we have to the backend
      if (idToken == null && accessToken == null) {
        return GoogleSignInResult(
          success: false,
          message:
              'Không thể lấy Google tokens. Vui lòng thử lại.',
        );
      }

      // Send token to backend (prefer idToken, fallback to accessToken on web)
      if (kDebugMode) {
        print('🌐 Sending Google token to backend: /api/auth/google/login');
        if (idToken != null) {
          print('🔑 Using ID Token (length: ${idToken.length})');
        } else if (accessToken != null) {
          print('🔑 Using Access Token on web (length: ${accessToken.length})');
        }
      }
      
      final response = await _api.post('/api/auth/google/login', body: {
        if (idToken != null) 'idToken': idToken,
        if (accessToken != null) 'accessToken': accessToken,
      });
      
      if (kDebugMode) {
        print('✅ Backend response received');
        print('📦 Response type: ${response.runtimeType}');
        print('📦 Response: $response');
      }

      // Parse response
      if (response is Map &&
          response['success'] == true &&
          response['data'] != null) {
        final data = response['data'];
        return GoogleSignInResult(
          success: true,
          message: data['message'] ?? 'Đăng nhập thành công',
          accessToken: data['accessToken'],
          userId: data['userId'],
          email: data['email'],
          username: data['username'],
          firstName: data['firstName'],
          lastName: data['lastName'],
          role: data['role'],
          isProfileComplete: data['isProfileComplete'] ?? true,
        );
      } else {
        return GoogleSignInResult(
          success: false,
          message: response['message'] ?? 'Đăng nhập thất bại',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Google Sign-In Error: $e');
        print('❌ Error type: ${e.runtimeType}');
      }
      
      String errorMessage = 'Đăng nhập Google thất bại';

      if (e is ApiException) {
        errorMessage = e.body;
        if (kDebugMode) {
          print('❌ API Exception status: ${e.statusCode}');
          print('❌ API Exception body: ${e.body}');
        }
      } else {
        errorMessage = e.toString();
      }

      return GoogleSignInResult(
        success: false,
        message: errorMessage,
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    if (!_isInitialized) return;

    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out from Google: $e');
      }
    }
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    if (!_isInitialized) {
      initialize();
    }
    return await _googleSignIn.isSignedIn();
  }

  // Silent sign-in (auto sign-in if previously signed in)
  Future<GoogleSignInAccount?> signInSilently() async {
    if (!_isInitialized) {
      initialize();
    }

    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      if (kDebugMode) {
        print('Silent sign-in failed: $e');
      }
      return null;
    }
  }
}

// Result model for Google Sign-In
class GoogleSignInResult {
  final bool success;
  final String message;
  final String? accessToken;
  final String? userId;
  final String? email;
  final String? username;
  final String? firstName;
  final String? lastName;
  final String? role;
  final bool? isProfileComplete;

  GoogleSignInResult({
    required this.success,
    required this.message,
    this.accessToken,
    this.userId,
    this.email,
    this.username,
    this.firstName,
    this.lastName,
    this.role,
    this.isProfileComplete,
  });
}
