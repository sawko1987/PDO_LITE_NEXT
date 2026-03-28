import 'import_object_type.dart';

class NormalizedImportRow {
  const NormalizedImportRow({
    required this.rowNumber,
    required this.positionNumber,
    required this.name,
    required this.code,
    required this.objectType,
    this.ownerName,
    this.nomSv,
    this.workshop,
    this.quantity,
    this.level,
  });

  final int rowNumber;
  final String positionNumber;
  final String name;
  final String code;
  final ImportObjectType objectType;
  final String? ownerName;
  final String? nomSv;
  final String? workshop;
  final double? quantity;
  final int? level;

  bool get isOperation => objectType == ImportObjectType.operation;
  bool get isSpecialProcess => objectType == ImportObjectType.specialProcess;
  bool get isStructural => !isOperation && !isSpecialProcess;
}
