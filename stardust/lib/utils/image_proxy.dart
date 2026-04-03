/// URL proxy for Yandex Cloud Storage images
/// Adds CORS headers to bypass browser restrictions

class ImageProxy {
  // Yandex Cloud Function URL for proxy
  static const String proxyUrl = 'https://functions.yandexcloud.net/d4e3g69asu4ph8871vct';
  
  /// Convert Yandex Storage URL to proxy URL
  static String? getProxyUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    // Only proxy Yandex Cloud Storage URLs
    if (!imageUrl.contains('storage.yandexcloud.net')) {
      return imageUrl;
    }
    
    // Encode the original URL and create proxy URL
    final encodedUrl = Uri.encodeComponent(imageUrl);
    return '$proxyUrl?url=$encodedUrl';
  }
  
  /// Check if URL needs proxy
  static bool needsProxy(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('storage.yandexcloud.net');
  }
}
