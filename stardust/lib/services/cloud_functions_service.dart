import 'dart:convert';
import 'package:http/http.dart' as http;
import '../yandex_cloud_options.dart';

/// Yandex Cloud Functions service
class CloudFunctionsService {
  final String functionUrl;
  final String functionToken;
  
  CloudFunctionsService({
    String? functionUrl,
    String? functionToken,
  })  : functionUrl = functionUrl ?? YandexCloudConfig.functionUrl,
        functionToken = functionToken ?? YandexCloudConfig.functionToken;
  
  /// Call a cloud function
  Future<dynamic> callFunction({
    required String functionName,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$functionUrl/$functionName');
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $functionToken',
        },
        body: body != null ? jsonEncode(body) : null,
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Function call failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Cloud function error: $e');
    }
  }
  
  /// Send push notification
  Future<dynamic> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await callFunction(
      functionName: 'sendPush',
      body: {
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
      },
    );
  }
  
  /// Check match (when user likes someone)
  Future<bool> checkMatch({
    required String fromUserId,
    required String toUserId,
  }) async {
    final result = await callFunction(
      functionName: 'checkMatch',
      body: {
        'fromUserId': fromUserId,
        'toUserId': toUserId,
      },
    );
    return result['isMatch'] ?? false;
  }
  
  /// Get recommended users
  Future<List<Map<String, dynamic>>> getRecommendations({
    required String userId,
    int limit = 10,
    double? latitude,
    double? longitude,
  }) async {
    final result = await callFunction(
      functionName: 'getRecommendations',
      body: {
        'userId': userId,
        'limit': limit,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return List<Map<String, dynamic>>.from(result['users'] ?? []);
  }
  
  /// Upload media to Yandex Storage via function
  Future<String> uploadMedia({
    required String fileName,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    final result = await callFunction(
      functionName: 'uploadMedia',
      body: {
        'fileName': fileName,
        'contentType': contentType,
        'data': base64Encode(fileBytes),
      },
    );
    return result['url'] ?? '';
  }
}
