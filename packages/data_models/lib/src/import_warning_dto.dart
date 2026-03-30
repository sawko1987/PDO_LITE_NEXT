class ImportWarningDto {
  const ImportWarningDto({
    required this.code,
    required this.message,
    this.rowNumber,
  });

  factory ImportWarningDto.fromJson(Map<String, Object?> json) {
    return ImportWarningDto(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      rowNumber: json['rowNumber'] as int?,
    );
  }

  final String code;
  final String message;
  final int? rowNumber;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    'rowNumber': rowNumber,
  };
}
