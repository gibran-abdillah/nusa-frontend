import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class HomeRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<FullDailySummary>> getDailySummary(String date) async {
    // Correct endpoint from api_doc: /stats/summary/ (not /stats/daily/)
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/stats/summary/?period=daily&date=$date',
    );
    debugPrint('--- API CALL: GET $url ---');

    try {
      final response = await http.get(url, headers: await _getAuthHeaders());

      debugPrint('Summary Status: ${response.statusCode}');

      // Guard against HTML error pages (e.g. ngrok 404)
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('Non-JSON response: ${response.body.substring(0, 200)}');
        return ApiResponse<FullDailySummary>(
          success: false,
          message: 'Server error (${response.statusCode})',
        );
      }

      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<FullDailySummary>.fromJson(
          jsonBody,
          (data) => FullDailySummary.fromJson(data as Map<String, dynamic>),
        );
      }
      if (response.statusCode == 401) {
        return ApiResponse<FullDailySummary>(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      return ApiResponse<FullDailySummary>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<FullDailySummary>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<List<FoodLog>>> getLogs(String date) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.logFood}?date=$date',
    );
    debugPrint('--- API CALL: GET $url ---');
    try {
      final response = await http.get(url, headers: await _getAuthHeaders());

      debugPrint('Logs Status: ${response.statusCode}');
      debugPrint('Logs Body: ${response.body}');

      // Guard against HTML error pages
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        debugPrint('Non-JSON response: ${response.body.substring(0, 200)}');
        return ApiResponse<List<FoodLog>>(
          success: false,
          message: 'Server error (${response.statusCode})',
          data: [],
        );
      }

      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<List<FoodLog>>.fromJson(jsonBody, (data) {
          List items = [];
          if (data is List) {
            items = data;
          } else if (data is Map && data.containsKey('results')) {
            items = data['results'] as List;
          } else if (data is Map) {
            items = [data];
          }
          return items
              .map((e) => FoodLog.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
      if (response.statusCode == 401) {
        return ApiResponse<List<FoodLog>>(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
          data: [],
        );
      }
      return ApiResponse<List<FoodLog>>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<List<FoodLog>>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
