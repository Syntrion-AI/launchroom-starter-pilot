# AIRMIDA LaunchRoom — полный тест настройки Hermes Agent Stage 1 → Stage 6

`public LaunchRoom test package / not AIRMIDA authority`

Это главный файл для реального тестирования. Его задача — не объяснить репозиторий, а запустить мастер-проход настройки нового Hermes agent от Stage 1 до Stage 6.

## Скопируй в новую Hermes-сессию

```text
Ты — AIRMIDA LaunchRoom Setup Operator.

Режим: REAL_LOCAL_SETUP.
Я хочу пройти полный LaunchRoom setup нового Hermes agent от Stage 1 до Stage 6.
Работай по-русски.

Критически важно:
- НЕ резюмируй этот файл.
- НЕ останавливайся на Stage 1, если gate Stage 1 выполнен.
- Веди меня как мастер настройки: Stage 1 → Stage 2 → Stage 3 → Stage 4 → Stage 5 → Stage 6.
- После каждого Stage дай короткий отчет: status, что готово, что заблокировано, evidence, next_action.
- Перед переходом на следующий Stage спроси: «Переходим к Stage N?».
- Если у тебя есть terminal/tools, можешь выполнять только безопасные локальные non-secret checks.
- Если у тебя нет terminal/tools, дай мне точную команду, которую я сам выполню, и попроси вставить безопасный вывод без секретов.
- Никогда не проси вставлять секреты, tokens, OAuth values, private keys, passwords или connection strings в чат.
- Если нужна авторизация провайдера, объясни, где в Hermes UI/CLI её выполнить, но не проси значение секрета.
- Не делай Cloudflare/Hetzner/n8n/provider/runtime/git публикацию без отдельного явного gate.

Начни сейчас со Stage 1. Сначала покажи всю карту Stage 1–6 в 6 строках, затем выполни Stage 1 checklist.
```

## Что должно произойти

Агент должен провести тебя последовательно:

```text
Stage 1 — Starter Basic Safe Operator
Stage 2 — Creator / Communication Room
Stage 3 — SaaS Project Builder Workspace
Stage 4 — Governed Operator and Agent Team
Stage 5 — CloudRoom Runtime Readiness
Stage 6 — AgentOps SaaS Operations
```

Он не должен просто сказать: «файл доступен» или «я могу резюмировать». Если он так делает — тест провален, потому что активный setup не запустился.

## Stage 1 gate

Цель: понять, что Hermes отвечает, язык выбран, secrets не попадают в чат, profile/workspace/model path понятны.

Expected checks:

```yaml
language: selected
model_path: working | needs_setup | owner_deferred
profile_workspace: selected | owner_deferred
secrets_policy: no_secrets_in_chat
first_channel: selected | owner_deferred
stage_status: pass | blocked | owner_deferred
```

## Stage 2 gate

Цель: подготовить creative/communication layer.

Expected checks:

```yaml
content_workflow: defined
brand_context: captured | owner_deferred
communication_channel: selected | owner_deferred
voice_media_options: classified
stage_status: pass | blocked | owner_deferred
```

## Stage 3 gate

Цель: подготовить SaaS project builder workspace.

Expected checks:

```yaml
project_intent: captured
workspace_root: selected | owner_deferred
local_build_loop: defined | not_applicable
feature_backlog_seed: created_in_chat | file_created_by_explicit_gate
stage_status: pass | blocked | owner_deferred
```

## Stage 4 gate

Цель: подготовить governed operator/team mode.

Expected checks:

```yaml
roles: defined
packet_flow: defined
verification_arbiter: defined
run_record_template: defined
subagent_policy: bounded
stage_status: pass | blocked | owner_deferred
```

## Stage 5 gate

Цель: подготовить CloudRoom readiness без live mutation.

Expected checks:

```yaml
cloud_surfaces: mapped
secrets_path: outside_chat
cloudflare: planned | owner_deferred | read_only_checked
hetzner: planned | owner_deferred | read_only_checked
n8n: planned | owner_deferred | read_only_checked
runtime_mutation: not_performed_without_gate
stage_status: pass | blocked | owner_deferred
```

## Stage 6 gate

Цель: подготовить AgentOps/SaaS operations.

Expected checks:

```yaml
release_gate: defined
observability: defined
slo_incident_runbook: defined
security_privacy_controls: defined
supervised_autonomy_criteria: defined
final_status: ready_for_next_owner_decision | blocked
```

## Финальный отчет

В конце Stage 6 агент должен выдать:

```yaml
launchroom_full_setup_result:
  stage_1: pass | blocked | owner_deferred
  stage_2: pass | blocked | owner_deferred
  stage_3: pass | blocked | owner_deferred
  stage_4: pass | blocked | owner_deferred
  stage_5: pass | blocked | owner_deferred
  stage_6: pass | blocked | owner_deferred
  created_or_changed: []
  secrets_requested_in_chat: false
  runtime_mutations_performed: false
  next_owner_decision: one concrete next action
```
