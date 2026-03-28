# Repository Guidelines

## Project Structure & Module Organization
`PDO_LITE_NEXT` is a Dart/Flutter monorepo. Use `apps/` for deployable clients, `packages/` for shared libraries, and `backend/` for the local Dart API.

- `apps/admin_windows/`: Flutter Windows planner and supervisor panel
- `apps/master_mobile/`: Flutter mobile app for masters
- `backend/`: Shelf-based local API and sync coordinator (`bin/`, `lib/`, `test/`)
- `packages/domain/`: core entities and business rules
- `packages/data_models/`: DTOs shared across backend and clients
- `packages/import_engine/`: import preview and normalization logic
- `packages/shared_ui/`: shared theme and reusable widgets

Keep feature code under each package's `lib/`, and keep tests alongside it in `test/`.

## Build, Test, and Development Commands
Run commands from the package or app directory you are working in.

- `flutter pub get`: install app/package dependencies for Flutter targets
- `dart pub get`: install dependencies for pure Dart packages and `backend/`
- `flutter run -d windows`: run `apps/admin_windows`
- `flutter run`: run `apps/master_mobile` on the selected device/emulator
- `dart run bin/backend.dart`: start the local backend
- `flutter test`: run widget/unit tests in a Flutter app or package
- `dart test -r expanded`: run backend or pure Dart package tests
- `flutter analyze` or `dart analyze`: static analysis using project lint rules
- `dart format .`: format Dart sources before submitting changes

## Coding Style & Naming Conventions
Follow standard Dart style: 2-space indentation, trailing commas where formatter adds them, `PascalCase` for types, `camelCase` for members, and `snake_case.dart` for files. Keep widgets small and reusable; shared visual building blocks belong in `packages/shared_ui/lib/src/`. Do not hand-edit generated or transient output such as `build/`, `.dart_tool/`, or platform-generated registrants.

## Testing Guidelines
This repo uses `flutter_test` for Flutter targets and `package:test` for Dart packages. Name tests `*_test.dart`. Add or update tests in the same module you change, for example `packages/domain/test/` or `apps/admin_windows/test/`. Prefer fast unit tests for domain/import logic and widget tests for UI shells.

## Commit & Pull Request Guidelines
This workspace snapshot does not include `.git` history, so no local convention can be derived from prior commits. Use short, imperative commit subjects scoped to the module, for example: `domain: add immutable machine version guard`. PRs should describe the affected module, summarize behavior changes, list validation commands run, and include screenshots for UI changes in `apps/admin_windows` or `apps/master_mobile`.
