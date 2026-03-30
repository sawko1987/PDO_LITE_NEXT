# Backend API v1

## Назначение
Документ фиксирует контракт локального backend API для этапа 3. Это не финальная полная реализация, а стабильный v1-каркас, на который должны опираться backend, Windows-клиент и mobile-клиент.

## Общие правила
- Базовый префикс API: `/v1`.
- Формат ответов: JSON.
- Для списков используется общий envelope:

```json
{
  "items": [],
  "count": 0,
  "meta": {}
}
```

- Для ошибок используется общий envelope:

```json
{
  "error": {
    "code": "machine_not_found",
    "message": "Machine was not found.",
    "details": {}
  }
}
```

- Идемпотентные операции создания/подтверждения в последующей реализации должны принимать `requestId` или другой явный ключ идемпотентности.

## Системные endpoint'ы

### `GET /health`
Назначение: liveliness/healthcheck backend.

Ответ `200`:
- `status`
- `service`
- `timestamp`

### `GET /bootstrap`
Назначение: отдать клиентам базовые архитектурные флаги инстанса.

Ответ `200`:
- `sourceOfTruth`
- `importMode`
- `planSource`
- `taskGenerationMode`

## Машины и версии

### `GET /v1/machines`
Назначение: список машин верхнего уровня.

Элемент списка:
- `id`
- `code`
- `name`
- `activeVersionId`

### `GET /v1/machines/{machineId}/versions`
Назначение: список версий конкретной машины.

Элемент списка:
- `id`
- `machineId`
- `label`
- `createdAt`
- `status`
- `isImmutable`

Ошибки:
- `404 machine_not_found`

### `GET /v1/machines/{machineId}/versions/{versionId}/planning-source`
Назначение: источник планирования для выбранной версии машины.

Элемент списка:
- `id`
- `catalogItemId`
- `displayName`
- `pathKey`
- `quantityPerMachine`
- `workshop`
- `operationCount`

Ошибки:
- `404 machine_not_found`
- `404 machine_version_not_found`

## Планы и задания

### `GET /v1/plans`
Назначение: сводный список планов.

Элемент списка:
- `id`
- `machineId`
- `versionId`
- `title`
- `createdAt`
- `status`
- `itemCount`
- `revisionCount`

### `POST /v1/plans`
Назначение: создать `draft`-план по конкретной версии машины.

Тело запроса:
- `requestId`
- `machineId`
- `versionId`
- `title`
- `items[]`

Элемент `items[]`:
- `structureOccurrenceId`
- `requestedQuantity`

Ответ `201`:
- детальный объект плана;
- `status = draft`;
- `canRelease`;
- `items[]` с source occurrence контекстом.

Ошибки:
- `404 machine_not_found`
- `404 machine_version_not_found`
- `404 structure_occurrence_not_found`
- `409 plan_request_replayed_with_different_payload`
- `422 plan_requires_items`
- `422 duplicate_structure_occurrence`
- `422 invalid_requested_quantity`
- `422 structure_occurrence_version_mismatch`

### `GET /v1/plans/{planId}`
Назначение: получить детальный план с плановыми позициями.

Поля ответа:
- `id`
- `machineId`
- `versionId`
- `title`
- `createdAt`
- `status`
- `canRelease`
- `itemCount`
- `revisionCount`
- `items[]`

Элемент `items[]`:
- `id`
- `structureOccurrenceId`
- `catalogItemId`
- `displayName`
- `pathKey`
- `requestedQuantity`
- `hasRecordedExecution`
- `canEdit`
- `workshop`

Ошибки:
- `404 plan_not_found`

### `POST /v1/plans/{planId}/release`
Назначение: перевести `draft`-план в `released` и сгенерировать задания по операциям.

Тело запроса:
- `requestId`
- `releasedBy`

Ответ `200`:
- `planId`
- `status`
- `generatedTaskCount`

Ошибки:
- `404 plan_not_found`
- `409 plan_release_not_allowed`
- `409 plan_request_replayed_with_different_payload`
- `422 invalid_request`

### `GET /v1/tasks`
Назначение: сводный список выданных заданий.

Элемент списка:
- `id`
- `planItemId`
- `operationOccurrenceId`
- `requiredQuantity`
- `assigneeId`
- `status`
- `isClosed`

### `GET /v1/tasks/{taskId}/reports`
Назначение: факты выполнения по конкретному заданию.

Элемент списка:
- `id`
- `taskId`
- `reportedBy`
- `reportedAt`
- `reportedQuantity`
- `reason`
- `acceptedAt`
- `isAccepted`

Ошибки:
- `404 task_not_found`

## Проблемы, НЗП и аудит

### `GET /v1/problems`
Назначение: список открытых и архивных проблем.

Элемент списка:
- `id`
- `machineId`
- `taskId`
- `title`
- `status`
- `isOpen`

### `GET /v1/wip`
Назначение: текущее состояние НЗП.

Элемент списка:
- `id`
- `machineId`
- `versionId`
- `structureOccurrenceId`
- `operationOccurrenceId`
- `balanceQuantity`
- `status`
- `blocksCompletion`

### `GET /v1/audit`
Назначение: аудит критичных изменений.

Элемент списка:
- `id`
- `entityType`
- `entityId`
- `action`
- `changedBy`
- `changedAt`
- `field`
- `beforeValue`
- `afterValue`

## Следующие write-контракты
Следующими после этапа 3 должны быть зафиксированы команды:
- создание/публикация версии машины;
- создание import session и подтверждение импорта;
- создание/выпуск плана;
- приём execution report от мастера;
- создание проблемы и сообщений чата;
- подтверждение завершения изделия начальником.

Для этих операций обязателен единый подход:
- command DTO;
- idempotency key;
- `409` для конфликтов жизненного цикла;
- `422` для нарушения бизнес-инвариантов;
- аудит критичных действий.
