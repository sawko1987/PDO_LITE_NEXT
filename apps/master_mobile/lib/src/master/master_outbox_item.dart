enum MasterOutboxStatus { pending, failed, sent }

enum MasterOutboxOperationType {
  executionReport,
  problemCreate,
  problemMessage,
  problemTransition,
}

class MasterOutboxItem {
  const MasterOutboxItem({
    required this.localId,
    required this.operationType,
    required this.requestId,
    required this.authorId,
    required this.createdAt,
    required this.status,
    this.taskId,
    this.problemId,
    this.reportedQuantity,
    this.reason,
    this.title,
    this.problemType,
    this.message,
    this.toStatus,
    this.lastError,
  });

  factory MasterOutboxItem.fromJson(Map<String, Object?> json) {
    return MasterOutboxItem(
      localId: json['localId'] as String? ?? '',
      operationType: MasterOutboxOperationType.values.byName(
        json['operationType'] as String? ??
            MasterOutboxOperationType.executionReport.name,
      ),
      requestId: json['requestId'] as String? ?? '',
      authorId: json['authorId'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: MasterOutboxStatus.values.byName(
        json['status'] as String? ?? MasterOutboxStatus.pending.name,
      ),
      taskId: json['taskId'] as String?,
      problemId: json['problemId'] as String?,
      reportedQuantity: (json['reportedQuantity'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
      title: json['title'] as String?,
      problemType: json['problemType'] as String?,
      message: json['message'] as String?,
      toStatus: json['toStatus'] as String?,
      lastError: json['lastError'] as String?,
    );
  }

  final String authorId;
  final DateTime createdAt;
  final String? lastError;
  final String localId;
  final String? message;
  final MasterOutboxOperationType operationType;
  final String? problemId;
  final String? problemType;
  final double? reportedQuantity;
  final String? reason;
  final String requestId;
  final MasterOutboxStatus status;
  final String? taskId;
  final String? title;
  final String? toStatus;

  MasterOutboxItem copyWith({
    String? authorId,
    DateTime? createdAt,
    bool clearLastError = false,
    String? lastError,
    String? localId,
    String? message,
    MasterOutboxOperationType? operationType,
    String? problemId,
    String? problemType,
    double? reportedQuantity,
    String? reason,
    String? requestId,
    MasterOutboxStatus? status,
    String? taskId,
    String? title,
    String? toStatus,
  }) {
    return MasterOutboxItem(
      localId: localId ?? this.localId,
      operationType: operationType ?? this.operationType,
      requestId: requestId ?? this.requestId,
      authorId: authorId ?? this.authorId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      taskId: taskId ?? this.taskId,
      problemId: problemId ?? this.problemId,
      reportedQuantity: reportedQuantity ?? this.reportedQuantity,
      reason: reason ?? this.reason,
      title: title ?? this.title,
      problemType: problemType ?? this.problemType,
      message: message ?? this.message,
      toStatus: toStatus ?? this.toStatus,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  String get displayLabel {
    return switch (operationType) {
      MasterOutboxOperationType.executionReport =>
        '${taskId ?? 'task'} | ${reportedQuantity ?? 0} pcs',
      MasterOutboxOperationType.problemCreate =>
        '${taskId ?? 'task'} | create problem "${title ?? ''}"',
      MasterOutboxOperationType.problemMessage =>
        '${problemId ?? 'problem'} | message',
      MasterOutboxOperationType.problemTransition =>
        '${problemId ?? 'problem'} | ${toStatus ?? 'transition'}',
    };
  }

  Map<String, Object?> toJson() => {
    'localId': localId,
    'operationType': operationType.name,
    'requestId': requestId,
    'authorId': authorId,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'taskId': taskId,
    'problemId': problemId,
    'reportedQuantity': reportedQuantity,
    'reason': reason,
    'title': title,
    'problemType': problemType,
    'message': message,
    'toStatus': toStatus,
    'lastError': lastError,
  };
}
