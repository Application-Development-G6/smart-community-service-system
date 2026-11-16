import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApi {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'current_user';
  static final http.Client _client = http.Client();

  static String? accessToken;
  static Map<String, dynamic>? currentUser;

  static Future<void> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    final encodedUser = await _storage.read(key: _userKey);
    if (token == null || token.isEmpty || encodedUser == null) {
      accessToken = null;
      currentUser = null;
      return;
    }

    final decodedUser = jsonDecode(encodedUser);
    if (decodedUser is! Map<String, dynamic>) {
      throw const FormatException('Saved account information is invalid.');
    }
    accessToken = token;
    currentUser = decodedUser;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          ApiConfig.endpoint('auth/login'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(body, 'Login failed.'));
    }

    final token = body['token'];
    final user = body['user'];
    if (token is! String || token.isEmpty || user is! Map<String, dynamic>) {
      throw const FormatException('The API returned incomplete login details.');
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user));
    accessToken = token;
    currentUser = user;
    return body;
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client
        .post(
          ApiConfig.endpoint('auth/register'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({
            'full_name': fullName,
            'email': email,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthApiException(_messageFrom(body, 'Registration failed.'));
    }
    return body;
  }

  static Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    accessToken = null;
    currentUser = null;
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The API returned an invalid response.');
    }
    return decoded;
  }

  static String _messageFrom(
    Map<String, dynamic> body,
    String fallback,
  ) {
    final message = body['message'];
    return message is String && message.isNotEmpty ? message : fallback;
  }
}
