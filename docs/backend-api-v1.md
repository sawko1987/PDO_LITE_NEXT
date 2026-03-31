# Backend API v1

## Назначение
Документ фиксирует текущий контракт локального backend API для `PDO_LITE_NEXT`.
Это не полный финальный контракт системы, а стабильный v1-каркас, на который уже опираются backend, Windows-клиент и mobile-клиент мастера.

## Общие правила
- Базовый префикс API: `/v1`.
- Формат ответов: JSON.
- Для списков используется envelope:

```json
{
  "items": [],
  "count": 0,
  "meta": {}
}
```

- Для ошибок используется envelope:

```json
{
  "error": {
    "code": "task_not_found",
    "message": "Task was not found.",
    "details": {}
  }
}
```

- Все write-операции v1 используют `requestId` как ключ идемпотентности.
- Повторный запрос с тем же `requestId` и тем же payload должен вернуть тот же результат.
- Повторный запрос с тем же `requestId`, но другим payload должен возвращать `409`.

## Системные endpoint'ы

### `GET /health`
Назначение: liveliness/healthcheck backend.

Ответ `200`:
- `status`
- `service`
- `timestamp`

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

## Импорт

### `POST /v1/import-sessions/preview`
Назначение: создать preview import-session для Excel/MXL.

Тело запроса:
- `requestId`
- `fileName`
- `fileContentBase64`

Ответ `201`:
- `sessionId`
- `status`
- `preview`

### `GET /v1/import-sessions/{sessionId}`
Назначение: получить ранее созданный preview import-session.

Ответ `200`:
- `sessionId`
- `status`
- `preview`

### `POST /v1/import-sessions/{sessionId}/confirm`
Назначение: подтвердить импорт.

Тело запроса:
- `requestId`
- `mode`
- `targetMachineId` для `create_version`

Ответ `200`:
- `sessionId`
- `mode`
- `machineId`
- `versionId`

## Планы

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

## Задания и факты выполнения

### `GET /v1/tasks`
Назначение: сводный список выданных заданий.

Параметры query:
- `assigneeId` optional
- `status` optional

Элемент списка:
- `id`
- `planItemId`
- `operationOccurrenceId`
- `requiredQuantity`
- `assigneeId`
- `status`
- `isClosed`

### `GET /v1/tasks/{taskId}`
Назначение: детальная карточка задания мастера с контекстом операции и прогрессом.

Поля ответа:
- `id`
- `planItemId`
- `operationOccurrenceId`
- `machineId`
- `versionId`
- `structureOccurrenceId`
- `structureDisplayName`
- `operationName`
- `workshop`
- `requiredQuantity`
- `reportedQuantity`
- `remainingQuantity`
- `assigneeId`
- `status`
- `isClosed`

Ошибки:
- `404 task_not_found`

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

### `POST /v1/tasks/{taskId}/reports`
Назначение: принять execution report от мастера по заданию.

Тело запроса:
- `requestId`
- `reportedBy`
- `reportedQuantity`
- `reason`

Ответ `201`:
- `report`
- `taskStatus`
- `reportedQuantityTotal`
- `remainingQuantity`
- `outboxStatus`

Правила:
- пока запрещено перевыполнение сверх `remainingQuantity`;
- статус задания меняется `pending -> inProgress -> completed`;
- закрытое задание не принимает новый report.

Ошибки:
- `404 task_not_found`
- `409 execution_report_replayed_with_different_payload`
- `409 task_report_not_allowed`
- `422 invalid_reported_quantity`
- `422 report_exceeds_required_quantity`

## Проблемы и чат

### Общие правила проблем v1
- Проблема в текущем v1 создаётся только из конкретного `taskId`.
- `machineId` и `taskId` сервер выводит из контекста задания.
- Жизненный цикл проблемы в v1: `open -> inProgress -> closed`.
- Статус `resolved` в v1 не используется.
- В v1 мастер может сам перевести проблему в `inProgress` и `closed`.
- Закрытая проблема не принимает новые сообщения и не переоткрывается в этом этапе.

### Классификатор `Problem.type`
- `equipment`
- `materials`
- `documentation`
- `planning_error`
- `technology_error`
- `blocked_by_other_workshop`
- `other`

### `GET /v1/problems`
Назначение: список проблем.

Параметры query:
- `taskId` optional
- `status` optional

Элемент списка:
- `id`
- `machineId`
- `type`
- `taskId`
- `title`
- `status`
- `isOpen`
- `createdAt`
- `messageCount`

### `GET /v1/problems/{problemId}`
Назначение: получить карточку проблемы вместе с лентой сообщений.

Поля ответа:
- `id`
- `machineId`
- `type`
- `taskId`
- `title`
- `status`
- `isOpen`
- `createdAt`
- `messages[]`

Элемент `messages[]`:
- `id`
- `problemId`
- `authorId`
- `message`
- `createdAt`

Ошибки:
- `404 problem_not_found`

### `POST /v1/tasks/{taskId}/problems`
Назначение: создать проблему из карточки задания.

Тело запроса:
- `requestId`
- `createdBy`
- `type`
- `title`
- `description`

Ответ `201`:
- `ProblemDetailDto`

Правила:
- `description` становится первым сообщением треда;
- новая проблема создаётся в статусе `open`.

Ошибки:
- `404 task_not_found`
- `409 problem_request_replayed_with_different_payload`
- `422 invalid_problem_type`
- `422 invalid_problem_message`

### `POST /v1/problems/{problemId}/messages`
Назначение: добавить сообщение в чат проблемы.

Тело запроса:
- `requestId`
- `authorId`
- `message`

Ответ `200`:
- актуальный `ProblemDetailDto`

Ошибки:
- `404 problem_not_found`
- `409 problem_request_replayed_with_different_payload`
- `422 invalid_problem_message`
- `422 problem_message_not_allowed`

### `POST /v1/problems/{problemId}/transition`
Назначение: изменить статус проблемы.

Тело запроса:
- `requestId`
- `changedBy`
- `toStatus`

Допустимые `toStatus`:
- `inProgress`
- `closed`

Ответ `200`:
- актуальный `ProblemDetailDto`

Ошибки:
- `404 problem_not_found`
- `409 problem_request_replayed_with_different_payload`
- `409 problem_transition_not_allowed`
- `422 invalid_request`

## НЗП и аудит

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
Следующими после текущего этапа должны быть зафиксированы команды:
- создание и публикация версий машины;
- полноценный модуль НЗП;
- подтверждение завершения изделия начальником;
- полный sync-контур с конфликтами и повторными попытками.
