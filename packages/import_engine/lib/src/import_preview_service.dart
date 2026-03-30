import 'import_format_detector.dart';
import 'import_normalizer.dart';
import 'import_preview.dart';
import 'import_preview_builder.dart';
import 'import_preview_result.dart';
import 'import_source.dart';
import 'import_source_reader.dart';
import 'import_validator.dart';

class ImportPreviewService {
  const ImportPreviewService({
    this.formatDetector = const ImportFormatDetector(),
    this.excelReader = const ExcelImportSourceReader(),
    this.mxlReader = const MxlImportSourceReader(),
    this.normalizer = const ImportNormalizer(),
    this.validator = const ImportValidator(),
    this.previewBuilder = const ImportPreviewBuilder(),
  });

  final ImportFormatDetector formatDetector;
  final ExcelImportSourceReader excelReader;
  final MxlImportSourceReader mxlReader;
  final ImportNormalizer normalizer;
  final ImportValidator validator;
  final ImportPreviewBuilder previewBuilder;

  ImportPreviewResult buildPreview({
    required String machineVersionId,
    required ImportSourceFile source,
  }) {
    final detection = formatDetector.detect(source);
    if (detection.format == ImportSourceFormat.unsupported) {
      final conflict = ImportConflict(rowNumber: 0, reason: detection.reason);
      final preview = ImportPreview(
        catalogItems: const [],
        structureOccurrences: const [],
        operationOccurrences: const [],
        conflicts: [conflict],
        skippedRows: const [],
      );
      return ImportPreviewResult(
        sourceInfo: ImportSourceInfo(
          fileName: source.fileName,
          format: detection.format,
          detectionReason: detection.reason,
          rowCount: 0,
          canConfirm: false,
        ),
        preview: preview,
        normalizedRows: const [],
        warnings: const [],
      );
    }

    final reader = switch (detection.format) {
      ImportSourceFormat.excel => excelReader,
      ImportSourceFormat.mxl => mxlReader,
      ImportSourceFormat.unsupported => throw StateError('Unsupported reader'),
    };

    final parsedDocument = reader.read(source);
    final normalized = normalizer.normalize(parsedDocument);
    final validation = validator.validate(normalized.rows);
    final preview = previewBuilder.build(
      machineVersionId: machineVersionId,
      rows: normalized.rows,
      externalConflicts: [...normalized.conflicts, ...validation.conflicts],
      externalWarnings: [...normalized.warnings, ...validation.warnings],
    );
    final canConfirm =
        preview.conflicts.isEmpty && preview.structureOccurrences.isNotEmpty;

    return ImportPreviewResult(
      sourceInfo: ImportSourceInfo(
        fileName: source.fileName,
        format: detection.format,
        detectionReason: detection.reason,
        rowCount: normalized.rows.length,
        canConfirm: canConfirm,
      ),
      preview: preview,
      normalizedRows: normalized.rows,
      warnings: preview.warnings,
      machineName: normalized.machineName,
      machineCode: normalized.machineCode,
    );
  }
}
