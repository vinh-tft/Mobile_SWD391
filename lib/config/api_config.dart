import 'package:flutter/foundation.dart';

/**
 * API Configuration
 * Centralized configuration for all API endpoints and WebSocket URLs
 * Matches React FE's api.config.ts
 * 
 * IMPORTANT: Set API_URL via --dart-define=API_URL=... when building
 * Example: flutter run --dart-define=API_URL=http://localhost:8082
 * 
 * For production builds:
 * flutter build apk --dart-define=API_URL=https://your-api.com
 */

/**
 * Production backend URL - used as fallback if environment variables fail
 * This ensures the app works even if API_URL is not set
 * Matches React FE api.config.ts PRODUCTION_BACKEND_URL
 */
const String PRODUCTION_BACKEND_URL = 'https://greenloop-heb0bffxh4h4e0hy.canadacentral-01.azurewebsites.net';

/**
 * Get the API base URL from environment variables (--dart-define)
 * Falls back to production URL (safer than localhost)
 * 
 * Matches React FE api.config.ts getApiUrl() function
 */
String getApiUrl() {
  // Try to get API_URL from --dart-define (similar to NEXT_PUBLIC_API_URL in React FE)
  const apiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  
  // In release/production mode, validate the URL
  if (kReleaseMode) {
    if (apiUrl.isEmpty) {
      print('❌ WARNING: API_URL is not set in production!');
      print('Falling back to hardcoded production URL: $PRODUCTION_BACKEND_URL');
      return PRODUCTION_BACKEND_URL;
    }
    
    // Check if URL still contains localhost in production
    if (apiUrl.contains('localhost') || 
        apiUrl.contains('127.0.0.1') || 
        apiUrl.contains(':8080') || 
        apiUrl.contains(':8082')) {
      print('❌ CRITICAL: API_URL contains localhost in production!');
      print('Current value: $apiUrl');
      print('Using production URL instead: $PRODUCTION_BACKEND_URL');
      return PRODUCTION_BACKEND_URL;
    }
    
    return apiUrl;
  }
  
  // Fallback to production URL if not set (safer than localhost)
  if (apiUrl.isEmpty) {
    print('⚠️ API_URL not set, using production backend');
    print('To use localhost for development, run: flutter run --dart-define=API_URL=http://localhost:8082');
    return PRODUCTION_BACKEND_URL;
  }
  
  return apiUrl;
}

/**
 * Get the WebSocket URL from environment variables
 * Automatically derives from API_URL if not explicitly set
 * Matches React FE api.config.ts getWebSocketUrl()
 */
String getWebSocketUrl() {
  // Check if explicitly set
  const wsUrl = String.fromEnvironment('WS_URL', defaultValue: '');
  if (wsUrl.isNotEmpty) {
    return wsUrl;
  }
  
  // Derive from API URL
  final apiUrl = getApiUrl();
  
  // Convert http/https to ws/wss
  final wsProtocol = apiUrl.startsWith('https') ? 'wss' : 'ws';
  final urlWithoutProtocol = apiUrl.replaceAll(RegExp(r'^https?://'), '');
  
  return '$wsProtocol://$urlWithoutProtocol/api/ws';
}

/**
 * API Configuration Object - Using getters for lazy evaluation
 * Use these throughout the application instead of hardcoding URLs
 * Matches React FE api.config.ts API_CONFIG
 */
class ApiConfig {
  /**
   * Base API URL (e.g., http://localhost:8082 or https://api.yourapp.com)
   * Matches React FE: API_CONFIG.BASE_URL
   */
  static String get baseUrl => getApiUrl();
  
  /**
   * WebSocket URL for real-time communications
   * Matches React FE: API_CONFIG.WS_URL
   */
  static String get wsUrl => getWebSocketUrl();
  
  /**
   * Request timeout in milliseconds
   * Matches React FE: API_CONFIG.TIMEOUT
   */
  static const int timeout = 30000;
  
  /**
   * Environment flag
   * Matches React FE: API_CONFIG.IS_PRODUCTION
   */
  static bool get isProduction => kReleaseMode;
  
  /**
   * API Endpoints
   * Matches React FE: API_CONFIG.ENDPOINTS
   * Note: Using non-const Map because Dart doesn't allow functions in const expressions
   * For dynamic endpoints (like points), use helper methods below
   */
  static final Map<String, dynamic> endpoints = {
    // Auth
    'auth': {
      'login': '/api/auth/login',
      'register': '/api/auth/register',
      'verify': '/api/auth/verify',
      'resendVerification': '/api/auth/resend-verification',
      'logout': '/api/auth/logout',
      'refresh': '/api/auth/refresh',
      'forgotPassword': '/api/auth/forgot-password',
      'resetPassword': '/api/auth/reset-password',
      'me': '/api/auth/me',
      'profile': '/api/auth/profile',
      'googleLogin': '/api/auth/google/login',
      'googleCompleteProfile': '/api/auth/google/complete-profile',
    },
    // Posts & social feed
    'posts': {
      'base': '/api/posts',
      'feed': '/api/posts/feed',
      'followingFeed': '/api/posts/feed/following',
      'communityFeed': '/api/posts/feed/community',
    },
    // Health Check
    'health': '/actuator/health',
  };
  
  /**
   * Helper methods for dynamic endpoints
   * Matches React FE: API_CONFIG.ENDPOINTS.POINTS.AVAILABLE(userId)
   */
  static String pointsAvailable(String userId) => '/api/points/$userId/available';
  static String pointsHistory(String userId) => '/api/points/$userId/history';

  static String postsForUser(String userId) => '/api/posts/users/$userId';
  static String postDetail(String postId) => '/api/posts/$postId';
  static String likePost(String postId) => '/api/posts/$postId/like';
  static String restorePost(String postId) => '/api/posts/$postId/restore';
  static String commentsForPost(String postId) => '/api/posts/$postId/comments';
}

/**
 * Helper to build full URL
 * Matches React FE: buildApiUrl(endpoint)
 */
String buildApiUrl(String endpoint) {
  return '${ApiConfig.baseUrl}$endpoint';
}

/**
 * Log configuration on app start
 * Matches React FE: console.log('🔧 API Configuration:')
 */
void logApiConfig() {
  print('🔧 API Configuration:');
  print('  Base URL: ${ApiConfig.baseUrl}');
  print('  WebSocket URL: ${ApiConfig.wsUrl}');
  print('  Environment: ${ApiConfig.isProduction ? "production" : "development"}');
  print('  Raw API_URL: ${const String.fromEnvironment('API_URL', defaultValue: 'not set')}');
}

