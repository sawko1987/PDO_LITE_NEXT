import 'problem.dart';
import 'task.dart';
import 'wip_entry.dart';

class CompletionPolicy {
  const CompletionPolicy();

  CompletionDecision evaluate({
    required Iterable<ProductionTask> tasks,
    required Iterable<Problem> problems,
    required Iterable<WipEntry> wipEntries,
  }) {
    final blockers = <CompletionBlocker>[];

    final openTasks = tasks
        .where((task) => !task.isClosed)
        .map((task) => task.id)
        .toList(growable: false);
    if (openTasks.isNotEmpty) {
      blockers.add(
        CompletionBlocker(
          type: CompletionBlockerType.openTasks,
          entityIds: openTasks,
        ),
      );
    }

    final openProblems = problems
        .where((problem) => problem.isOpen)
        .map((problem) => problem.id)
        .toList(growable: false);
    if (openProblems.isNotEmpty) {
      blockers.add(
        CompletionBlocker(
          type: CompletionBlockerType.openProblems,
          entityIds: openProblems,
        ),
      );
    }

    final openWip = wipEntries
        .where((entry) => entry.blocksCompletion)
        .map((entry) => entry.id)
        .toList(growable: false);
    if (openWip.isNotEmpty) {
      blockers.add(
        CompletionBlocker(
          type: CompletionBlockerType.openWip,
          entityIds: openWip,
        ),
      );
    }

    return CompletionDecision(blockers: blockers);
  }
}

class CompletionDecision {
  const CompletionDecision({required this.blockers});

  final List<CompletionBlocker> blockers;

  bool get canComplete => blockers.isEmpty;
}

class CompletionBlocker {
  const CompletionBlocker({required this.type, required this.entityIds});

  final CompletionBlockerType type;
  final List<String> entityIds;
}

enum CompletionBlockerType { openTasks, openProblems, openWip }
