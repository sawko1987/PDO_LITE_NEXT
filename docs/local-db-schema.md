# Локальная БД v1

## Назначение
Этот документ фиксирует проект локальной БД для этапа 3. БД обслуживает локальный backend и остаётся главным источником истины для всей истории производства, версий машин, планов, заданий, факта, НЗП, проблем и аудита.

## Выбранный подход
- Основная БД: реляционная, нормализованная, локальная.
- Базовая цель v1: PostgreSQL-совместимая схема без runtime-ALTER и без денормализации как основного механизма.
- Все изменения схемы проводятся только управляемыми миграциями.
- Облако не хранит единственный экземпляр истории; транспортный контур синхронизации использует только временные активные данные.

## Логические домены и таблицы

### Справочники и пользователи
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `users` | учётные записи планировщиков, начальников и мастеров | `id`, `login`, `password_hash`, `role`, `display_name`, `is_active`, `created_at` |
| `workshops` | справочник цехов/участков | `id`, `code`, `name`, `created_at` |

### Машины и версии
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `machines` | карточка машины верхнего уровня | `id`, `code`, `name`, `active_version_id`, `created_at`, `updated_at` |
| `machine_versions` | неизменяемые версии структуры машины | `id`, `machine_id`, `label`, `status`, `created_at`, `published_at`, `created_by` |
| `catalog_items` | единый справочник номенклатурных объектов | `id`, `code`, `name`, `kind`, `created_at` |
| `structure_occurrences` | вхождения номенклатуры в конкретную версию машины | `id`, `version_id`, `catalog_item_id`, `parent_occurrence_id`, `path_key`, `display_name`, `quantity_per_machine`, `workshop_id`, `source_position_number`, `source_owner_name` |
| `operation_occurrences` | операции, привязанные к конкретному structure occurrence | `id`, `version_id`, `structure_occurrence_id`, `name`, `quantity_per_machine`, `workshop_id`, `source_position_number`, `source_quantity` |

### Импорт
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `import_sessions` | сессия предпросмотра импорта до подтверждения | `id`, `machine_id`, `source_file_name`, `source_format`, `status`, `created_by`, `created_at`, `confirmed_at` |
| `import_conflicts` | найденные конфликты и ошибки импорта | `id`, `session_id`, `row_number`, `reason`, `payload_json` |
| `import_artifacts` | нормализованный preview-слой импорта | `id`, `session_id`, `artifact_type`, `payload_json` |

### Планирование и выпуск
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `plans` | производственные планы | `id`, `machine_id`, `version_id`, `title`, `status`, `created_at`, `created_by`, `released_at`, `completed_at` |
| `plan_items` | позиции плана по конкретным occurrence | `id`, `plan_id`, `structure_occurrence_id`, `catalog_item_id`, `requested_quantity`, `has_recorded_execution`, `created_at` |
| `plan_revisions` | шапка ревизии плана | `id`, `plan_id`, `revision_number`, `changed_by`, `changed_at` |
| `plan_revision_changes` | diff по полям ревизии плана | `id`, `revision_id`, `target_id`, `field`, `before_value`, `after_value` |
| `production_tasks` | задания мастерам по операциям | `id`, `plan_item_id`, `operation_occurrence_id`, `required_quantity`, `assignee_id`, `status`, `created_at`, `released_at`, `closed_at` |

### Факт, НЗП и проблемы
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `execution_reports` | факты выполнения от мастеров | `id`, `task_id`, `reported_by`, `reported_at`, `reported_quantity`, `reason`, `accepted_at`, `accepted_by` |
| `wip_entries` | остатки НЗП и перевыполнение | `id`, `machine_id`, `version_id`, `structure_occurrence_id`, `operation_occurrence_id`, `balance_quantity`, `status`, `created_at`, `closed_at` |
| `problems` | инциденты по заданиям/машинам | `id`, `machine_id`, `task_id`, `title`, `status`, `created_by`, `created_at`, `closed_at` |
| `problem_messages` | сообщения чата по проблеме | `id`, `problem_id`, `author_id`, `message`, `created_at` |

### Аудит и синхронизация
| Таблица | Назначение | Ключевые поля |
| --- | --- | --- |
| `audit_entries` | обязательный аудит критичных изменений | `id`, `entity_type`, `entity_id`, `action`, `field`, `before_value`, `after_value`, `changed_by`, `changed_at` |
| `sync_queue` | очередь публикации/приёма мобильных событий | `id`, `direction`, `topic`, `entity_type`, `entity_id`, `payload_json`, `status`, `attempt_count`, `available_at`, `created_at`, `processed_at` |
| `sync_errors` | журнал синхронизационных ошибок | `id`, `queue_id`, `error_code`, `error_message`, `captured_at` |
| `backup_history` | журнал резервных копий и восстановления | `id`, `file_name`, `operation`, `status`, `created_by`, `created_at` |

## Ограничения и индексы
- `machines.code` уникален.
- `catalog_items.code` уникален в пределах справочника.
- `machine_versions(machine_id, label)` уникален.
- `structure_occurrences(version_id, path_key)` уникален.
- `plan_revisions(plan_id, revision_number)` уникален.
- `production_tasks(plan_item_id, operation_occurrence_id)` уникален.
- Индексы обязательны на все внешние ключи, а также на:
  - `plans(status, created_at)`;
  - `production_tasks(status, assignee_id)`;
  - `execution_reports(task_id, reported_at)`;
  - `wip_entries(machine_id, status)`;
  - `problems(status, machine_id)`;
  - `audit_entries(entity_type, entity_id, changed_at)`;
  - `sync_queue(status, available_at)`.

## Правила миграций
- Миграции только прямые и воспроизводимые: `up`/`down` либо `versioned forward-only` с явным журналом.
- Запрещены runtime-проверки вида "если колонки нет, добавить".
- Первая миграция создаёт весь базовый скелет доменов.
- Отдельные последующие миграции допустимы для:
  - синхронизационного контура;
  - резервного копирования;
  - производительных индексов по результатам пилота.

## Архивные и активные данные
- Локальная БД хранит и активные, и архивные записи бессрочно.
- Архивность определяется статусами и временными метками, а не переносом истории в стороннюю БД.
- Облако может содержать только публикации активных заданий и неподтверждённых событий, но не архив.

## Идемпотентность
- Повторная публикация в `sync_queue` по одному ключу события не создаёт дублирующий финальный факт.
- Подтверждение принятого `execution_report` должно быть идемпотентным.
- Повторный запрос на выпуск заданий по уже выпущенному плану не должен повторно создавать те же `production_tasks`.
