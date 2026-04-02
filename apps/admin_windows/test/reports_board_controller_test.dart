import 'package:admin_windows/src/import/admin_backend_client.dart';
import 'package:admin_windows/src/reports/reports_board_controller.dart';
import 'package:data_models/data_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportsBoardController', () {
    test('bootstrap loads machines, plans, and summary', () async {
      final controller = ReportsBoardController(
        client: _FakeReportsBackendClient(),
      );

      await controller.bootstrap();

      expect(controller.machines, hasLength(1));
      expect(controller.plans, hasLength(1));
      expect(controller.summary?.totalPlans, 1);
      expect(controller.errorMessage, isNull);
    });

    test('loadPlanFactReport updates list and clears error', () async {
      final controller = ReportsBoardController(
        client: _FakeReportsBackendClient(),
      );

      await controller.loadPlanFactReport(
        machineId: 'machine-1',
        planId: 'plan-1',
        fromDate: '2026-03-01',
        toDate: '2026-03-31',
      );

      expect(controller.planFactReport, hasLength(1));
      expect(controller.planFactReport.single.reportedQuantity, 6);
      expect(controller.errorMessage, isNull);
    });

    test('loadShiftReport with date returns rows', () async {
      final controller = ReportsBoardController(
        client: _FakeReportsBackendClient(),
      );

      await controller.loadShiftReport('2026-03-28');

      expect(controller.shiftReport, hasLength(1));
      expect(controller.shiftReport.single.taskId, 'task-1');
      expect(controller.shiftReport.single.reports, hasLength(1));
    });

    test('loadProblemReport filters by status', () async {
      final controller = ReportsBoardController(
        client: _FakeReportsBackendClient(),
      );

      await controller.loadProblemReport(status: 'closed');

      expect(controller.problemReport, hasLength(1));
      expect(controller.problemReport.single.problemId, 'problem-2');
      expect(controller.problemReport.single.status, 'closed');
    });

    test('backend error exposes errorMessage', () async {
      final controller = ReportsBoardController(
        client: _FakeReportsBackendClient(failSummary: true),
      );

      await controller.loadSummary();

      expect(controller.errorMessage, 'Summary failed.');
    });
  });
}

class _FakeReportsBackendClient implements AdminBackendClient {
  _FakeReportsBackendClient({this.failSummary = false});

  final bool failSummary;

  @override
  Future<ApiListResponseDto<MachineSummaryDto>> listMachines() async {
    return const ApiListResponseDto(
      items: [
        MachineSummaryDto(
          id: 'machine-1',
          code: 'PDO-100',
          name: 'Machine 100',
          activeVersionId: 'ver-1',
        ),
      ],
      meta: {'resource': 'machines'},
    );
  }

  @override
  Future<ApiListResponseDto<PlanSummaryDto>> listPlans() async {
    return ApiListResponseDto(
      items: [
        PlanSummaryDto(
          id: 'plan-1',
          machineId: 'machine-1',
          versionId: 'ver-1',
          title: 'Seed plan',
          createdAt: DateTime.utc(2026, 3, 28),
          status: 'released',
          itemCount: 1,
          revisionCount: 0,
        ),
      ],
      meta: {'resource': 'plans'},
    );
  }

  @override
  Future<ReportSummaryDto> getReportSummary({String? machineId}) async {
    if (failSummary) {
      throw const AdminBackendException(message: 'Summary failed.');
    }
    return const ReportSummaryDto(
      totalPlans: 1,
      draftPlans: 0,
      releasedPlans: 1,
      completedPlans: 0,
      totalTasks: 1,
      activeTasks: 1,
      completedTasks: 0,
      totalProblems: 2,
      openProblems: 1,
      closedProblems: 1,
      totalWipEntries: 1,
      blockingWipEntries: 1,
      totalExecutionReports: 1,
    );
  }

  @override
  Future<ApiListResponseDto<PlanFactReportItemDto>> getPlanFactReport({
    String? machineId,
    String? versionId,
    String? planId,
    String? fromDate,
    String? toDate,
  }) async {
    return const ApiListResponseDto(
      items: [
        PlanFactReportItemDto(
          structureOccurrenceId: 'occ-1',
          displayName: 'Frame',
          pathKey: 'machine/frame',
          workshop: 'WS-1',
          planId: 'plan-1',
          planTitle: 'Seed plan',
          requestedQuantity: 12,
          reportedQuantity: 6,
          remainingQuantity: 6,
          completionPercent: 50,
          taskCount: 1,
          closedTaskCount: 0,
          operationName: 'Cut',
        ),
      ],
      meta: {'resource': 'plan_fact_reports'},
    );
  }

  @override
  Future<ApiListResponseDto<ShiftReportItemDto>> getShiftReport({
    required String date,
    String? machineId,
    String? assigneeId,
  }) async {
    return ApiListResponseDto(
      items: [
        ShiftReportItemDto(
          taskId: 'task-1',
          assigneeId: 'master-1',
          structureDisplayName: 'Frame',
          operationName: 'Cut',
          workshop: 'WS-1',
          requiredQuantity: 12,
          reportedQuantity: 6,
          remainingQuantity: 6,
          status: 'inProgress',
          isClosed: false,
          reports: [
            ExecutionReportDto(
              id: 'report-1',
              taskId: 'task-1',
              reportedBy: 'master-1',
              reportedAt: DateTime.utc(2026, 3, 28, 10, 30),
              reportedQuantity: 6,
              outcome: 'partial',
              reason: 'Waiting on tooling.',
              isAccepted: true,
            ),
          ],
        ),
      ],
      meta: {'resource': 'shift_reports', 'date': date},
    );
  }

  @override
  Future<ApiListResponseDto<ProblemReportItemDto>> getProblemReport({
    String? machineId,
    String? status,
    String? type,
    String? fromDate,
    String? toDate,
  }) async {
    final items = [
      ProblemReportItemDto(
        problemId: 'problem-1',
        title: 'Missing blanks',
        type: 'materials',
        status: 'open',
        isOpen: true,
        machineId: 'machine-1',
        taskId: 'task-1',
        createdAt: DateTime.utc(2026, 4, 1, 8),
        closedAt: null,
        messageCount: 1,
        structureDisplayName: 'Frame',
        operationName: 'Cut',
      ),
      ProblemReportItemDto(
        problemId: 'problem-2',
        title: 'Resolved issue',
        type: 'equipment',
        status: 'closed',
        isOpen: false,
        machineId: 'machine-1',
        taskId: 'task-2',
        createdAt: DateTime.utc(2026, 4, 1, 9),
        closedAt: DateTime.utc(2026, 4, 1, 10),
        messageCount: 2,
        structureDisplayName: 'Panel',
        operationName: 'Weld',
      ),
    ];
    final filtered = items
        .where((item) {
          if (status != null && status.isNotEmpty && item.status != status) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return ApiListResponseDto(
      items: filtered,
      meta: {'resource': 'problem_reports'},
    );
  }

  @override
  Future<ProblemDetailDto> createProblem(
    String taskId,
    CreateProblemRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmImportResultDto> confirmImport(
    String sessionId,
    ConfirmImportRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<CreateExecutionReportResultDto> createExecutionReport(
    String taskId,
    CreateExecutionReportRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ImportSessionSummaryDto> createImportPreview(
    CreateImportPreviewRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> createDraftMachineVersion(
    String machineId,
    String versionId,
    CreateDraftMachineVersionRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  void dispose() {}

  @override
  Future<MachineVersionDetailDto> createOperationOccurrence(
    String machineId,
    String versionId,
    CreateOperationOccurrenceRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> createPlan(CreatePlanRequestDto request) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> createStructureOccurrence(
    String machineId,
    String versionId,
    CreateStructureOccurrenceRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> deleteOperationOccurrence(
    String machineId,
    String versionId,
    String operationId,
    DeleteOperationOccurrenceRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> deleteStructureOccurrence(
    String machineId,
    String versionId,
    String occurrenceId,
    DeleteStructureOccurrenceRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> getMachineVersionDetail(
    String machineId,
    String versionId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ImportSessionSummaryDto> getImportSession(String sessionId) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionDecisionDto> getPlanCompletionDecision(
    String planId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanDetailDto> getPlan(String planId) async {
    throw UnimplementedError();
  }

  @override
  Future<ProblemDetailDto> getProblem(String problemId) async {
    throw UnimplementedError();
  }

  @override
  Future<TaskDetailDto> getTask(String taskId) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<MachineVersionSummaryDto>> listMachineVersions(
    String machineId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<PlanningSourceOccurrenceDto>> listPlanningSource(
    String machineId,
    String versionId,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ProblemSummaryDto>> listProblems({
    String? taskId,
    String? status,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<TaskSummaryDto>> listTasks({String? status}) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<WipEntryDto>> listWipEntries() async {
    throw UnimplementedError();
  }

  @override
  Future<PlanCompletionResultDto> completePlan(
    String planId,
    CompletePlanRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<PlanReleaseResultDto> releasePlan(
    String planId,
    ReleasePlanRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ProblemDetailDto> addProblemMessage(
    String problemId,
    AddProblemMessageRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ProblemDetailDto> transitionProblem(
    String problemId,
    TransitionProblemRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<MachineVersionDetailDto> publishMachineVersion(
    String machineId,
    String versionId,
    PublishMachineVersionRequestDto request,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiListResponseDto<ExecutionReportDto>> listTaskReports(
    String taskId,
  ) async {
    throw UnimplementedError();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
