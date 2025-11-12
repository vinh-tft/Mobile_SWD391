import 'package:flutter/foundation.dart';
import 'api_config.dart' show ApiConfig, PRODUCTION_BACKEND_URL;

/**
 * App Configuration
 * Legacy config file for backward compatibility
 * Now uses ApiConfig from api_config.dart (matches React FE api.config.ts)
 * 
 * React FE Environment Variables:
 * - NEXT_PUBLIC_API_URL=http://localhost:8082
 * - NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dmpjc496u
 * - NEXT_PUBLIC_CLOUDINARY_API_KEY=867162548936863
 * - NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=ml_default
 * - NEXT_PUBLIC_GOOGLE_CLIENT_ID=1093884420538-ka17a3efctfkv117f1lqotu4uusgokn9.apps.googleusercontent.com
 */

class AppConfig {
  // API Configuration
  // Matches: NEXT_PUBLIC_API_URL=http://localhost:8082
  static const String apiUrlLocal = 'http://localhost:8082';
  static const String apiUrlAndroidLocal = 'http://10.0.2.2:8082'; // Android emulator localhost
  // Production backend URL - Matches React FE api.config.ts PRODUCTION_BACKEND_URL
  static const String apiUrlProd = PRODUCTION_BACKEND_URL;

  // Google Sign-In Configuration
  // Matches: NEXT_PUBLIC_GOOGLE_CLIENT_ID=1093884420538-ka17a3efctfkv117f1lqotu4uusgokn9.apps.googleusercontent.com
  static const String googleWebClientId =
      '1093884420538-ka17a3efctfkv117f1lqotu4uusgokn9.apps.googleusercontent.com';

  // Cloudinary Configuration
  // Matches React FE env.download:
  // - NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dmpjc496u
  // - NEXT_PUBLIC_CLOUDINARY_API_KEY=867162548936863
  // - NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET=ml_default
  // Note: Currently images are uploaded through backend API, but these are used for image optimization
  static const String cloudinaryCloudName = 'dmpjc496u';
  static const String cloudinaryApiKey = '867162548936863';
  static const String cloudinaryUploadPreset = 'ml_default';

  // Get API URL based on platform and build mode
  // Now uses ApiConfig.baseUrl which reads from --dart-define=API_URL (matches React FE NEXT_PUBLIC_API_URL)
  // Falls back to platform-specific localhost for debug mode if API_URL not set
  static String getApiUrl({
    required bool isWeb,
    required bool isDebug,
    required bool isAndroid,
  }) {
    // Use ApiConfig.baseUrl which reads from --dart-define=API_URL (matches React FE behavior)
    // This ensures consistency with React FE's NEXT_PUBLIC_API_URL
    final apiUrl = ApiConfig.baseUrl;
    
    // If ApiConfig returned production URL but we're in debug mode and API_URL wasn't set,
    // fall back to platform-specific localhost (backward compatibility)
    if (isDebug && apiUrl == PRODUCTION_BACKEND_URL) {
      const envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
      if (envApiUrl.isEmpty) {
        // No API_URL set via --dart-define, use platform-specific localhost
        if (isWeb) {
          return apiUrlLocal;
        } else if (isAndroid) {
          return apiUrlAndroidLocal;
        } else {
          return apiUrlLocal;
        }
      }
    }
    
    return apiUrl;
  }
}

