import 'import_preview.dart';
import 'import_source.dart';
import 'normalized_import_row.dart';

class ImportPreviewResult {
  const ImportPreviewResult({
    required this.sourceInfo,
    required this.preview,
    required this.normalizedRows,
    required this.warnings,
    this.machineName,
    this.machineCode,
  });

  final ImportSourceInfo sourceInfo;
  final ImportPreview preview;
  final List<NormalizedImportRow> normalizedRows;
  final List<ImportWarning> warnings;
  final String? machineName;
  final String? machineCode;

  bool get canConfirm => sourceInfo.canConfirm;
}
