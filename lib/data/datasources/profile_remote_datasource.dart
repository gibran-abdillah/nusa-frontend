import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class ProfileRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<UserProfile>> getProfile(String userId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.usersPath}/$userId/profile/',
    );
    debugPrint('--- API CALL: GET $url ---');
    try {
      final response = await http.get(url, headers: await _getAuthHeaders());
      debugPrint('Profile Status: ${response.statusCode}');
      if (response.statusCode == 401) {
        return ApiResponse<UserProfile>(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return ApiResponse<UserProfile>(
          success: false,
          message: 'Server error (${response.statusCode})',
        );
      }
      final jsonBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = jsonBody['data'];
        if (data != null && data is Map<String, dynamic>) {
          return ApiResponse<UserProfile>(
            success: true,
            message: jsonBody['message']?.toString() ?? '',
            data: UserProfile.fromJson(data),
          );
        }
      }
      return ApiResponse<UserProfile>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('Profile exception: $e');
      return ApiResponse<UserProfile>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<UserProfile>> updateProfile(
    String userId,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.usersPath}/$userId/profile/',
    );
    debugPrint('--- API CALL: PATCH $url ---');
    try {
      final response = await http.patch(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode(body),
      );
      debugPrint('Profile PATCH Status: ${response.statusCode}');
      debugPrint('Profile PATCH Body: ${response.body}');
      if (response.statusCode == 401) {
        return ApiResponse<UserProfile>(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return ApiResponse<UserProfile>(
          success: false,
          message: 'Server error (${response.statusCode})',
        );
      }
      final jsonBody = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = jsonBody['data'];
        if (data != null && data is Map<String, dynamic>) {
          return ApiResponse<UserProfile>(
            success: true,
            message: jsonBody['message']?.toString() ?? '',
            data: UserProfile.fromJson(data),
          );
        }
      }
      return ApiResponse<UserProfile>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('Profile PATCH exception: $e');
      return ApiResponse<UserProfile>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
