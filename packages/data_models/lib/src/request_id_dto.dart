class RequestIdDto {
  const RequestIdDto({required this.requestId});

  factory RequestIdDto.fromJson(Map<String, Object?> json) {
    return RequestIdDto(requestId: json['requestId'] as String? ?? '');
  }

  final String requestId;

  Map<String, Object?> toJson() => {'requestId': requestId};
}
