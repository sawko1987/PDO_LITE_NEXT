CREATE TABLE IF NOT EXISTS schema_migrations (
  version TEXT PRIMARY KEY,
  applied_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_items (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  kind TEXT NOT NULL,
  description TEXT,
  is_active INTEGER NOT NULL DEFAULT 1
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_catalog_items_code
  ON catalog_items(code);

CREATE TABLE IF NOT EXISTS machines (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL,
  name TEXT NOT NULL,
  active_version_id TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machines_code
  ON machines(code);

CREATE TABLE IF NOT EXISTS machine_versions (
  id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  label TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_machine_versions_machine_label
  ON machine_versions(machine_id, label);

CREATE TABLE IF NOT EXISTS structure_occurrences (
  id TEXT PRIMARY KEY,
  version_id TEXT NOT NULL,
  catalog_item_id TEXT NOT NULL,
  path_key TEXT NOT NULL,
  display_name TEXT NOT NULL,
  quantity_per_machine REAL NOT NULL,
  parent_occurrence_id TEXT,
  workshop TEXT,
  inherited_workshop INTEGER NOT NULL DEFAULT 0,
  source_position_number TEXT,
  source_owner_name TEXT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_structure_occurrences_version_path
  ON structure_occurrences(version_id, path_key);

CREATE TABLE IF NOT EXISTS operation_occurrences (
  id TEXT PRIMARY KEY,
  version_id TEXT NOT NULL,
  structure_occurrence_id TEXT NOT NULL,
  name TEXT NOT NULL,
  quantity_per_machine REAL NOT NULL,
  workshop TEXT,
  inherited_workshop INTEGER NOT NULL DEFAULT 0,
  source_position_number TEXT,
  source_quantity REAL
);

CREATE TABLE IF NOT EXISTS plans (
  id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  version_id TEXT NOT NULL,
  title TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS plan_items (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  machine_id TEXT NOT NULL,
  version_id TEXT NOT NULL,
  structure_occurrence_id TEXT NOT NULL,
  catalog_item_id TEXT NOT NULL,
  requested_quantity REAL NOT NULL,
  has_recorded_execution INTEGER NOT NULL DEFAULT 0
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_plan_items_plan_occurrence
  ON plan_items(plan_id, structure_occurrence_id);

CREATE TABLE IF NOT EXISTS plan_revisions (
  id TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  revision_number INTEGER NOT NULL,
  changed_by TEXT NOT NULL,
  changed_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_plan_revisions_plan_number
  ON plan_revisions(plan_id, revision_number);

CREATE TABLE IF NOT EXISTS plan_revision_changes (
  id TEXT PRIMARY KEY,
  revision_id TEXT NOT NULL,
  target_id TEXT NOT NULL,
  field TEXT NOT NULL,
  before_value TEXT NOT NULL,
  after_value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS production_tasks (
  id TEXT PRIMARY KEY,
  plan_item_id TEXT NOT NULL,
  operation_occurrence_id TEXT NOT NULL,
  required_quantity REAL NOT NULL,
  assignee_id TEXT,
  status TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_tasks_plan_item_operation
  ON production_tasks(plan_item_id, operation_occurrence_id);

CREATE TABLE IF NOT EXISTS execution_reports (
  id TEXT PRIMARY KEY,
  task_id TEXT NOT NULL,
  reported_by TEXT NOT NULL,
  reported_at TEXT NOT NULL,
  reported_quantity REAL NOT NULL,
  outcome TEXT NOT NULL,
  reason TEXT,
  accepted_at TEXT
);

CREATE TABLE IF NOT EXISTS problems (
  id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  task_id TEXT,
  title TEXT,
  type TEXT NOT NULL,
  created_at TEXT NOT NULL,
  status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS problem_messages (
  id TEXT PRIMARY KEY,
  problem_id TEXT NOT NULL,
  author_id TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS wip_entries (
  id TEXT PRIMARY KEY,
  machine_id TEXT NOT NULL,
  version_id TEXT NOT NULL,
  structure_occurrence_id TEXT NOT NULL,
  operation_occurrence_id TEXT NOT NULL,
  balance_quantity REAL NOT NULL,
  task_id TEXT,
  source_report_id TEXT,
  source_outcome TEXT,
  status TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS audit_entries (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action TEXT NOT NULL,
  changed_by TEXT NOT NULL,
  changed_at TEXT NOT NULL,
  field TEXT,
  before_value TEXT,
  after_value TEXT
);

CREATE TABLE IF NOT EXISTS idempotency_records (
  request_id TEXT PRIMARY KEY,
  category TEXT NOT NULL,
  signature TEXT NOT NULL,
  resource_id TEXT,
  secondary_resource_id TEXT,
  status TEXT,
  generated_count INTEGER
);

CREATE TABLE IF NOT EXISTS app_sequences (
  name TEXT PRIMARY KEY,
  value INTEGER NOT NULL
);
