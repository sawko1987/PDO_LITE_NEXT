class ApiErrorDto {
  const ApiErrorDto({
    required this.code,
    required this.message,
    this.details = const <String, Object?>{},
  });

  factory ApiErrorDto.fromJson(Map<String, Object?> json) {
    final payload = (json['error'] as Map<Object?, Object?>? ?? const {})
        .cast<String, Object?>();
    return ApiErrorDto(
      code: payload['code'] as String? ?? '',
      message: payload['message'] as String? ?? '',
      details: (payload['details'] as Map<Object?, Object?>? ?? const {})
          .cast(),
    );
  }

  final String code;
  final String message;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() => {
    'error': {'code': code, 'message': message, 'details': details},
  };
}
