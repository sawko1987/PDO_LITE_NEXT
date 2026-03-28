# PDO Lite Next

New production planning system built as a separate product:
- `apps/admin_windows` - Flutter Windows panel for planners and supervisors
- `apps/master_mobile` - Flutter mobile app for masters
- `backend` - local Dart API and sync coordinator
- `packages/domain` - core domain entities
- `packages/data_models` - DTOs shared by backend and clients
- `packages/import_engine` - preview-first import rules for machine versions
- `packages/shared_ui` - shared Flutter theme and shell widgets

The repository intentionally does not reuse the legacy Flask/Tkinter architecture.

Project docs:
- `docs/architecture.md` - target architecture and source-of-truth rules
- `docs/implementation-roadmap.md` - staged delivery plan
- `docs/development-rules.md` - development rules, module boundaries, and quality gates
