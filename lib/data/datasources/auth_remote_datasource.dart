import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../models/api_response.dart';
import '../models/auth_models.dart';

class AuthRemoteDataSource {
  Future<ApiResponse<AuthToken>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');
    debugPrint('--- API CALL: POST $url ---');
    debugPrint(
      'Payload: {"name": "$name", "email": "$email"}',
    ); // hiding password

    try {
      final response = await http.post(
        url,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirm': passwordConfirm,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final jsonBody = jsonDecode(response.body);

      // We expect the standard API response structure
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<AuthToken>.fromJson(
          jsonBody,
          (data) => AuthToken.fromJson(data as Map<String, dynamic>),
        );
      } else {
        // Validation errors or other errors
        return ApiResponse<AuthToken>.fromJson(
          jsonBody,
          // Since it failed, there's no proper AuthToken data
          null,
        );
      }
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<AuthToken>(
        success: false,
        message: 'Network error or server unavailable',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<AuthToken>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
    debugPrint('--- API CALL: POST $url ---');
    debugPrint('Payload: {"email": "$email"}'); // hiding password

    try {
      final response = await http.post(
        url,
        headers: ApiConstants.defaultHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<AuthToken>.fromJson(
          jsonBody,
          (data) => AuthToken.fromJson(data as Map<String, dynamic>),
        );
      } else {
        return ApiResponse<AuthToken>.fromJson(jsonBody, null);
      }
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<AuthToken>(
        success: false,
        message: 'Network error or server unavailable',
        error: e.toString(),
      );
    }
  }
}
