class OperationOccurrence {
  const OperationOccurrence({
    required this.id,
    required this.versionId,
    required this.structureOccurrenceId,
    required this.name,
    required this.quantityPerMachine,
    this.workshop,
    this.inheritedWorkshop = false,
    this.sourcePositionNumber,
    this.sourceQuantity,
  });

  final String id;
  final String versionId;
  final String structureOccurrenceId;
  final String name;
  final double quantityPerMachine;
  final String? workshop;
  final bool inheritedWorkshop;
  final String? sourcePositionNumber;
  final double? sourceQuantity;
}
