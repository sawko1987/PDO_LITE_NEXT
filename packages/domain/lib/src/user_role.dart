enum UserRole { planner, supervisor, master }

extension UserRoleAccess on UserRole {
  bool get canManageUsers => this == UserRole.planner;

  bool get canViewUsers =>
      this == UserRole.planner || this == UserRole.supervisor;

  bool get canEditPlan =>
      this == UserRole.planner || this == UserRole.supervisor;

  bool get canClosePlan => this == UserRole.supervisor;

  bool get canViewAudit =>
      this == UserRole.planner || this == UserRole.supervisor;
}
