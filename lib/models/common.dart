/// Mirrors `src/types/common.ts`'s `ApiResponse<T>`.
class ApiResponse<T> {
  ApiResponse({required this.statusCode, required this.message, this.data});

  final int statusCode;
  final String message;
  final T? data;

  static const successCode = 9000;
  bool get isSuccess => statusCode == successCode;

  factory ApiResponse.fromJson(dynamic json, T Function(dynamic json) fromData) {
    final map = json as Map<String, dynamic>;
    return ApiResponse<T>(
      statusCode: map['statusCode'] as int? ?? 0,
      message: map['message'] as String? ?? '',
      data: map['data'] == null ? null : fromData(map['data']),
    );
  }
}
