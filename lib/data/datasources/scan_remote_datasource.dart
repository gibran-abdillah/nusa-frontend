import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../core/scan_image_compress.dart';
import '../../core/token_storage.dart';
import '../models/api_response.dart';
import '../models/api_models.dart';

class ScanRemoteDataSource {
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await TokenStorage.getAccessToken();
    return {
      ...ApiConstants.defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<ApiResponse<ScanPrepareResponse>> uploadAndPrepareScan({
    required File imageFile,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.scanPrepare}');
    debugPrint('--- API CALL: MULTIPART POST $url ---');

    try {
      final request = http.MultipartRequest('POST', url);

      final token = await TokenStorage.getAccessToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Compress image before upload (resize + JPEG) to reduce size and upload time
      final compressed = await compressImageForScan(imageFile.path);
      if (compressed != null && compressed.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          compressed,
          filename: 'image.jpg',
        ));
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload Status Code: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Upload Error Body: ${response.body}');
      }

      final jsonBody = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse<ScanPrepareResponse>.fromJson(
          jsonBody,
          (data) => ScanPrepareResponse.fromJson(data as Map<String, dynamic>),
        );
      }
      return ApiResponse<ScanPrepareResponse>.fromJson(jsonBody, null);
    } catch (e) {
      debugPrint('EXCEPTION Caught: $e');
      return ApiResponse<ScanPrepareResponse>(
        success: false,
        message: 'Network error or unable to upload image',
        error: e.toString(),
      );
    }
  }

  Future<ApiResponse<FoodLog>> analyzeScan({
    required String scanId,
    required String mealType,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.scanAnalyze}');
    debugPrint('--- API CALL: POST $url ---');

    try {
      final response = await http.post(
        url,
        headers: await _getAuthHeaders(),
        body: jsonEncode({'scan_id': scanId, 'meal_type': mealType}),
      );

      debugPrint('Analyze Status Code: ${response.statusCode}');
      debugPrint('Analyze Response Body: ${response.body}');

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 202) {
        return ApiResponse<FoodLog>.fromJson(jsonBody, (data) {
          final d = data as Map<String, dynamic>;
          // API returns FoodLog nested under `log` key
          final logJson = d.containsKey('log')
              ? d['log'] as Map<String, dynamic>
              : d;
          return FoodLog.fromJson(logJson);
        });
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
