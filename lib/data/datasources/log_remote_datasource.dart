import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class LogRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<FoodLog>> logFood({
    required String foodId,
    required String mealType,
    required num servingWeightG,
    required String notes,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logFood}');
    debugPrint('--- API CALL: POST $url ---');

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'food_id': foodId,
          'meal_type': mealType,
          'serving_weight_g': servingWeightG,
          'notes': notes,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<FoodLog>.fromJson(
          jsonBody,
          (data) => FoodLog.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<FoodLog>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<FoodLog>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
