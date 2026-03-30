class BootstrapSummaryDto {
  const BootstrapSummaryDto({
    required this.sourceOfTruth,
    required this.importMode,
    required this.planSource,
    required this.taskGenerationMode,
  });

  final String sourceOfTruth;
  final String importMode;
  final String planSource;
  final String taskGenerationMode;

  Map<String, Object?> toJson() => {
    'sourceOfTruth': sourceOfTruth,
    'importMode': importMode,
    'planSource': planSource,
    'taskGenerationMode': taskGenerationMode,
  };
}
