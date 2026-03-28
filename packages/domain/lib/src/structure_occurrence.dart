class StructureOccurrence {
  const StructureOccurrence({
    required this.id,
    required this.versionId,
    required this.catalogItemId,
    required this.pathKey,
    required this.displayName,
    required this.quantityPerMachine,
    this.parentOccurrenceId,
    this.workshop,
    this.inheritedWorkshop = false,
    this.sourcePositionNumber,
    this.sourceOwnerName,
  });

  final String id;
  final String versionId;
  final String catalogItemId;
  final String pathKey;
  final String displayName;
  final double quantityPerMachine;
  final String? parentOccurrenceId;
  final String? workshop;
  final bool inheritedWorkshop;
  final String? sourcePositionNumber;
  final String? sourceOwnerName;

  String get occurrenceKey => '$versionId:$pathKey';
}
