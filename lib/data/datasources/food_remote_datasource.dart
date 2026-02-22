import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class FoodRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<List<FoodPayload>>> listFoods({String query = ''}) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/foods/?search=$query');
    debugPrint('--- API CALL: GET $url ---');

    try {
      final response = await http.get(url, headers: await _getAuthHeaders());

      debugPrint('Status Code: ${response.statusCode}');
      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<List<FoodPayload>>.fromJson(jsonBody, (data) {
          List items = [];
          if (data is List) {
            items = data;
          } else if (data is Map && data.containsKey('results')) {
            items = data['results'] as List;
          } else if (data is Map) {
            items = [data];
          }
          return items
              .map((e) => FoodPayload.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
      return ApiResponse<List<FoodPayload>>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<List<FoodPayload>>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<FoodPayload>> createCustomFood({
    required String name,
    required String brand,
    required num caloriesPer100g,
    required num proteinPer100g,
    required num carbsPer100g,
    required num fatPer100g,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/foods/');
    debugPrint('--- API CALL: POST $url ---');

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'name': name,
          'brand': brand,
          'calories_per_100g': caloriesPer100g,
          'protein_per_100g': proteinPer100g,
          'carbs_per_100g': carbsPer100g,
          'fat_per_100g': fatPer100g,
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return ApiResponse<FoodPayload>.fromJson(
          jsonBody,
          (data) => FoodPayload.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<FoodPayload>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<FoodPayload>(
        success: false,
        message: 'Network error',
        error: e.toString(),
      );
    }
  }
}
