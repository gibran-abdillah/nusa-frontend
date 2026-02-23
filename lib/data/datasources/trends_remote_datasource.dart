import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class TrendsRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<TrendsData>> getTrends(String period) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/stats/trends/?period=$period',
    );
    debugPrint('--- API CALL: GET $url ---');

    try {
      final response = await http.get(url, headers: await _getAuthHeaders());
      debugPrint('Trends Status: ${response.statusCode}');

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('Non-JSON response: ${response.body.substring(0, 200)}');
        return ApiResponse<TrendsData>(
          success: false,
          message: 'Server error (${response.statusCode})',
        );
      }

      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<TrendsData>.fromJson(
          jsonBody,
          (data) => TrendsData.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<TrendsData>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<TrendsData>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
