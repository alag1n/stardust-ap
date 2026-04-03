import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Yandex Cloud Storage service (S3 compatible)
class YandexStorageService {
  final String accessKey;
  final String secretKey;
  final String bucket;
  final String endpoint;
  final String region;
  
  YandexStorageService({
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.endpoint,
    required this.region,
  });
  
  /// Upload file to Yandex Object Storage
  Future<String> uploadFile({
    required String filePath,
    required String objectName,
    String contentType = 'application/octet-stream',
  }) async {
    final uri = Uri.parse('$endpoint/$bucket/$objectName');
    
    // Read file and compute SHA256 hash
    final file = File(filePath);
    final fileBytes = await file.readAsBytes();
    final payloadHash = sha256.convert(fileBytes).toString();
    
    final date = DateTime.now().toUtc();
    final dateStamp = '${date.year}${_pad(date.month)}${_pad(date.day)}';
    final amzDate = '${dateStamp}T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
    
    final headers = {
      'Host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
      'Content-Type': contentType,
    };
    
    final signature = _generateSignature(
      method: 'PUT',
      uri: uri,
      dateStamp: dateStamp,
      amzDate: amzDate,
      payloadHash: payloadHash,
      headers: headers,
    );
    
    headers['Authorization'] = 'AWS4-HMAC-SHA256 '
        'Credential=$accessKey/$dateStamp/$region/s3/aws4_request, '
        'SignedHeaders=content-type;host;x-amz-content-sha256;x-amz-date, '
        'Signature=$signature';
    
    final response = await http.put(
      uri,
      headers: headers,
      body: fileBytes,
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return '$endpoint/$bucket/$objectName';
    } else {
      throw Exception('Upload failed: ${response.statusCode} - ${response.body}');
    }
  }
  
  /// Get file URL
  String getFileUrl(String objectName) {
    return '$endpoint/$bucket/$objectName';
  }
  
  /// Delete file from storage
  Future<void> deleteFile(String objectName) async {
    final uri = Uri.parse('$endpoint/$bucket/$objectName');
    
    final date = DateTime.now().toUtc();
    final dateStamp = '${date.year}${_pad(date.month)}${_pad(date.day)}';
    final amzDate = '${dateStamp}T${_pad(date.hour)}${_pad(date.minute)}${_pad(date.second)}Z';
    
    final payloadHash = 'UNSIGNED-PAYLOAD';
    
    final headers = {
      'Host': uri.host,
      'x-amz-date': amzDate,
      'x-amz-content-sha256': payloadHash,
    };
    
    final signature = _generateSignature(
      method: 'DELETE',
      uri: uri,
      dateStamp: dateStamp,
      amzDate: amzDate,
      payloadHash: payloadHash,
      headers: headers,
    );
    
    headers['Authorization'] = 'AWS4-HMAC-SHA256 '
        'Credential=$accessKey/$dateStamp/$region/s3/aws4_request, '
        'SignedHeaders=host;x-amz-content-sha256;x-amz-date, '
        'Signature=$signature';
    
    final response = await http.delete(uri, headers: headers);
    
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Delete failed: ${response.statusCode}');
    }
  }
  
  String _pad(int n) => n.toString().padLeft(2, '0');
  
  String _generateSignature({
    required String method,
    required Uri uri,
    required String dateStamp,
    required String amzDate,
    required String payloadHash,
    required Map<String, String> headers,
  }) {
    final canonicalHeaders = headers.entries
        .map((e) => '${e.key.toLowerCase()}:${e.value}')
        .join('\n');
    
    final signedHeaders = headers.keys.map((k) => k.toLowerCase()).join(';');
    
    final canonicalRequest = [
      method,
      uri.path.isEmpty ? '/' : uri.path,
      uri.query,
      canonicalHeaders,
      '',
      signedHeaders,
      payloadHash,
    ].join('\n');
    
    final canonicalRequestHash = sha256.convert(utf8.encode(canonicalRequest)).toString();
    
    final scope = '$dateStamp/$region/s3/aws4_request';
    
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      scope,
      canonicalRequestHash,
    ].join('\n');
    
    final kDate = _hmacSha256(utf8.encode('AWS4$secretKey'), utf8.encode(dateStamp));
    final kRegion = _hmacSha256(kDate, utf8.encode(region));
    final kService = _hmacSha256(kRegion, utf8.encode('s3'));
    final kSigning = _hmacSha256(kService, utf8.encode('aws4_request'));
    
    final signature = _hmacSha256(kSigning, utf8.encode(stringToSign));
    
    return signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }
}
