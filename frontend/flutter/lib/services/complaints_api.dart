import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'api_config.dart';
import 'auth_api.dart';

class ComplaintsApiException implements Exception {
  const ComplaintsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ComplaintsApi {
  static final http.Client _client = http.Client();

  static Future<List<Map<String, dynamic>>> getComplaints() {
    return _getComplaints('complaints');
  }

  static Future<List<Map<String, dynamic>>> getAdminComplaints() {
    return _getComplaints('complaints/admin');
  }

  static Future<List<Map<String, dynamic>>> _getComplaints(
    String endpoint,
  ) async {
    final response = await _client
        .get(ApiConfig.endpoint(endpoint), headers: _authorizedHeaders())
        .timeout(const Duration(seconds: 15));
    final body = _decodeResponse(response);
    _ensureSuccess(response, body, 'Failed to retrieve complaints.');

    if (body is! List) {
      throw const FormatException(
        'The API returned an invalid complaint list.',
      );
    }
    return body.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('The API returned an invalid complaint.');
      }
      return item;
    }).toList();
  }

  static Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String category,
    required String location,
    required String description,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      ApiConfig.endpoint('complaints'),
    )..headers['Authorization'] = _authorizationValue();
    request.fields.addAll({
      'title': title,
      'category': category,
      'location': location,
      'description': description,
    });

    if (imageBytes != null && imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'photo',
          imageBytes,
          filename: imageName,
          contentType: _imageContentType(imageName),
        ),
      );
    }

    final streamedResponse = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeResponse(response);
    _ensureSuccess(response, body, 'Failed to submit complaint.');
    if (body is! Map<String, dynamic>) {
      throw const FormatException(
        'The API returned an invalid submission response.',
      );
    }
    return body;
  }

  static Future<void> updateStatus({
    required int complaintId,
    required String status,
    String? remark,
  }) async {
    final response = await _client
        .patch(
          ApiConfig.endpoint('complaints/$complaintId/status'),
          headers: {
            ..._authorizedHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'status': status, 'remark': remark}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decodeResponse(response);
    _ensureSuccess(response, body, 'Failed to update complaint status.');
  }

  static Map<String, String> _authorizedHeaders() => {
    'Authorization': _authorizationValue(),
  };

  static String _authorizationValue() {
    final token = AuthApi.accessToken;
    if (token == null || token.isEmpty) {
      throw const ComplaintsApiException('Please log in to continue.');
    }
    return 'Bearer $token';
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (!contentType.contains('application/json')) {
      throw ComplaintsApiException(
        'The API returned a non-JSON response (HTTP ${response.statusCode}). '
        'Check the backend URL and restart the latest backend server.',
      );
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw FormatException('The API returned invalid JSON: $error');
    }
  }

  static void _ensureSuccess(
    http.Response response,
    dynamic body,
    String fallback,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    final message = body is Map<String, dynamic> ? body['message'] : null;
    throw ComplaintsApiException(
      message is String && message.isNotEmpty ? message : fallback,
    );
  }

  static MediaType _imageContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        throw const ComplaintsApiException(
          'Choose a JPEG, PNG, GIF, or WebP image.',
        );
    }
  }
}
