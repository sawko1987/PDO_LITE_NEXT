import 'import_preview_dto.dart';

class ImportSessionSummaryDto {
  const ImportSessionSummaryDto({
    required this.sessionId,
    required this.status,
    required this.createdAt,
    required this.preview,
    this.confirmedAt,
  });

  factory ImportSessionSummaryDto.fromJson(Map<String, Object?> json) {
    return ImportSessionSummaryDto(
      sessionId: json['sessionId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] as String? ??
            DateTime.fromMillisecondsSinceEpoch(0).toIso8601String(),
      ),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
      preview: ImportPreviewDto.fromJson(
        (json['preview'] as Map<Object?, Object?>? ?? const {}).cast(),
      ),
    );
  }

  final String sessionId;
  final String status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final ImportPreviewDto preview;

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
    'preview': preview.toJson(),
  };
}
