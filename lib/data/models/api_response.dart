class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final dynamic error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
      error: json['error'],
    );
  }

  String get readableErrorMessage {
    if (error == null) return message;

    if (error is Map) {
      final errMap = error as Map;
      dynamic detail = errMap;

      // Often validation errors are nested under 'detail' or 'error'
      if (errMap.containsKey('detail')) {
        detail = errMap['detail'];
      } else if (errMap.containsKey('errors')) {
        detail = errMap['errors'];
      }

      if (detail is String) {
        return detail;
      } else if (detail is Map) {
        List<String> messages = [];
        detail.forEach((key, value) {
          if (value is List) {
            for (var v in value) {
              messages.add(v.toString());
            }
          } else {
            messages.add(value.toString());
          }
        });
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      } else if (detail is List) {
        return detail.map((e) => e.toString()).join('\n');
      }
      return detail.toString();
    } else if (error is String) {
      return error as String;
    }

    return error.toString();
  }
}
