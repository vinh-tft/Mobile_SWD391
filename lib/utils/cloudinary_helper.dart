// Cloudinary Helper Utilities
// Provides functions to transform and optimize Cloudinary image URLs
// Uses Cloudinary config from AppConfig (matches React FE env.download)

import '../config/app_config.dart';

class CloudinaryHelper {
  // Get Cloudinary cloud name from AppConfig
  // Matches: NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME=dmpjc496u
  static String get cloudName => AppConfig.cloudinaryCloudName;
  
  // Base Cloudinary URL - dynamically built from AppConfig
  static String get baseUrl => 'https://res.cloudinary.com/$cloudName/image/upload';
  
  /// Transform a Cloudinary URL or publicId to optimized image URL
  /// 
  /// If the URL is already a full Cloudinary URL, it will be transformed
  /// If it's a publicId, it will be converted to a full URL
  /// 
  /// Options:
  /// - width: desired width (default: 800)
  /// - height: desired height (optional)
  /// - quality: image quality ('auto', 'best', 'good', 'eco', 'low') (default: 'auto')
  /// - format: image format ('auto', 'webp', 'jpg', 'png') (default: 'auto')
  /// - crop: crop mode ('fill', 'fit', 'scale', 'thumb') (default: 'fill')
  static String getOptimizedImageUrl(
    String urlOrPublicId, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
    String crop = 'fill',
  }) {
    // If already a full URL (starts with http/https), check if it's Cloudinary
    if (urlOrPublicId.startsWith('http://') || urlOrPublicId.startsWith('https://')) {
      // Check if it's a Cloudinary URL
      if (urlOrPublicId.contains('cloudinary.com')) {
        // Already a Cloudinary URL, can add transformations
        return _addTransformations(urlOrPublicId, width: width, height: height, quality: quality, format: format, crop: crop);
      } else {
        // External URL (not Cloudinary), return as-is
        return urlOrPublicId;
      }
    }
    
    // It's a publicId, build full URL with transformations
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop.isNotEmpty) transformations.add('c_$crop');
    if (quality.isNotEmpty && quality != 'auto') transformations.add('q_$quality');
    if (format.isNotEmpty && format != 'auto') transformations.add('f_$format');
    
    final transformStr = transformations.isNotEmpty ? '${transformations.join(',')}/' : '';
    
    // Remove leading slash from publicId if present
    final publicId = urlOrPublicId.startsWith('/') ? urlOrPublicId.substring(1) : urlOrPublicId;
    
    return '$baseUrl/$transformStr$publicId';
  }
  
  /// Add transformations to an existing Cloudinary URL
  static String _addTransformations(
    String url, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
    String crop = 'fill',
  }) {
    // Find the position after /upload/ to insert transformations
    final uploadIndex = url.indexOf('/upload/');
    if (uploadIndex == -1) return url;
    
    final beforeUpload = url.substring(0, uploadIndex + 8); // Include '/upload/'
    final afterUpload = url.substring(uploadIndex + 8);
    
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    if (crop.isNotEmpty) transformations.add('c_$crop');
    if (quality.isNotEmpty && quality != 'auto') transformations.add('q_$quality');
    if (format.isNotEmpty && format != 'auto') transformations.add('f_$format');
    
    if (transformations.isEmpty) return url;
    
    final transformStr = '${transformations.join(',')}/';
    return '$beforeUpload$transformStr$afterUpload';
  }
  
  /// Get thumbnail URL (small optimized image)
  static String getThumbnailUrl(String urlOrPublicId, {int size = 200}) {
    return getOptimizedImageUrl(
      urlOrPublicId,
      width: size,
      height: size,
      crop: 'fill',
      quality: 'auto',
      format: 'auto',
    );
  }
  
  /// Get medium size image URL
  static String getMediumImageUrl(String urlOrPublicId, {int width = 600}) {
    return getOptimizedImageUrl(
      urlOrPublicId,
      width: width,
      quality: 'auto',
      format: 'auto',
      crop: 'fit',
    );
  }
  
  /// Get large/high quality image URL
  static String getLargeImageUrl(String urlOrPublicId, {int width = 1200}) {
    return getOptimizedImageUrl(
      urlOrPublicId,
      width: width,
      quality: 'auto',
      format: 'auto',
      crop: 'fit',
    );
  }
  
  /// Check if a URL is a Cloudinary URL
  static bool isCloudinaryUrl(String url) {
    return url.contains('cloudinary.com');
  }
}
