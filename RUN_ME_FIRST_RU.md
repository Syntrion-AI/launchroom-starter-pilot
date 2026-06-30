# AIRMIDA LaunchRoom — реальный мастер настройки нового Hermes Agent

`public LaunchRoom test package / not AIRMIDA authority`

Это главный файл для полного теста. Он предназначен для новой Hermes-сессии или нового пользователя, которому нужно пройти реальную настройку Hermes Agent для SaaS-проекта.

Не используй старую логику “Stage 1 only”. Этот файл запускает полный setup.

## Главный prompt для Hermes

Скопируй весь блок в новую Hermes-сессию:

```text
Ты — AIRMIDA LaunchRoom Real Hermes Setup Operator.

Режим: REAL_HERMES_SETUP.
Цель: провести меня через полную настройку нового Hermes Agent для SaaS-проекта.
Язык: русский.

Это сообщение является моим явным подтверждением пройти все уровни настройки Stage 1 → Stage 6 в одной сессии.
Не останавливайся после Stage 1 и не говори “это выходит за рамки Stage 1”.
Не резюмируй репозиторий и не отвечай “файл доступен”. Запусти мастер настройки.

Разрешено без дополнительного подтверждения:
- объяснять шаги;
- задавать короткие вопросы выбора;
- выполнять или просить выполнить safe read-only команды;
- интерпретировать безопасный вывод команд;
- помечать unavailable/deferred, если пользователь не хочет подключать канал или провайдера сейчас;
- переходить к следующему Stage, если текущий Stage pass/deferred/not_applicable.

Требует отдельного явного подтверждения перед действием:
- создание/изменение файлов;
- изменение Hermes config/profile/tools/gateway;
- установка skills;
- запуск gateway/service;
- git commit/push;
- Cloudflare/Hetzner/n8n/provider/runtime/deploy/billing операции.

Никогда не проси и не принимай секреты в чат: API keys, OAuth tokens, private keys, passwords, connection strings, .env, auth.json.
Если нужен секрет — объясни, где в Hermes UI/CLI/secret store его ввести, но не проси значение.

Если terminal/tools доступны — сначала используй safe read-only checks.
Если terminal/tools недоступны или падают на Windows/WSL — не блокируй весь setup. Дай мне PowerShell/CMD команды из этого файла, попроси вставить sanitized output, и продолжай.

Строго используй эти уровни:
Stage 1 — Hermes health + model/provider baseline
Stage 2 — Profile + workspace + Desktop project
Stage 3 — Tools + skills + memory + terminal/browser readiness
Stage 4 — Messaging/gateway readiness
Stage 5 — SaaS project operator kit
Stage 6 — CloudRoom + AgentOps readiness

Начни сейчас:
1. Покажи карту 6 stages одной таблицей.
2. Выполни Stage 1 checklist.
3. Если Stage 1 pass/deferred, сразу переходи к Stage 2 без повторного вопроса, пока не встретишь действие из списка “требует отдельного подтверждения”.
```

---

# Stage 1 — Hermes health + model/provider baseline

Цель: убедиться, что Hermes установлен/запускается, модель отвечает, понятен путь model/provider.

## Если у агента есть terminal/tools

Safe read-only commands:

```bash
hermes --version
hermes status
hermes doctor
hermes config path
```

Не читать и не печатать содержимое `.env`, `auth.json`, private config values, token stores.

## Если terminal недоступен: Windows PowerShell fallback

Пользователь может выполнить вручную в PowerShell:

```powershell
$ErrorActionPreference = "Continue"
Write-Host "PWD=$PWD"
where.exe hermes
hermes --version
hermes status
hermes doctor
hermes config path
```

Вставлять в чат можно только sanitized output. Не вставлять `.env`, токены, ключи, OAuth, auth.json.

## Stage 1 pass criteria

```yaml
hermes_cli: detected | missing | user_deferred
model_response: working | needs_setup | user_deferred
provider_path: subscription | api_key | oauth | local | unknown | user_deferred
config_path_known: yes | no | user_deferred
secrets_in_chat: false
stage_1_status: pass | blocked | deferred
```

If blocked: give exact install/setup next action, e.g. `hermes setup`, `hermes model`, or Hermes Desktop setup path.

---

# Stage 2 — Profile + workspace + Desktop project

Цель: выбрать профиль и workspace для SaaS-проекта.

## Safe read-only commands

```bash
hermes profile list
hermes profile show airmida 2>/dev/null || true
```

Если пользователь новый, предложить:

```bash
hermes profile create <project-name>
hermes profile use <project-name>
```

Но НЕ выполнять создание профиля без отдельного подтверждения.

## Workspace decision

Спросить один выбор:

```text
Где будет SaaS workspace?
A) текущая папка
B) новая пустая папка
C) позже выбрать вручную
```

Если Hermes Desktop доступен, объяснить:

```text
Hermes Desktop → Projects → Create Project → выбрать папку SaaS workspace.
```

## Stage 2 pass criteria

```yaml
profile_strategy: current | new_profile_planned | user_deferred
workspace_strategy: current | new_folder_planned | user_deferred
project_ui_path: desktop_project | cli_only | unknown
no_profile_mutation_without_gate: true
stage_2_status: pass | blocked | deferred
```

---

# Stage 3 — Tools + skills + memory + terminal/browser readiness

Цель: понять, какие Hermes capabilities доступны и что нужно включить для SaaS operator.

## Safe read-only commands

```bash
hermes tools list
hermes skills list
hermes memory status
hermes sessions list 2>/dev/null || true
```

Если `hermes tools list` недоступен, использовать:

```bash
hermes tools
```

только как UI-инструкцию, не включать ничего без подтверждения.

## Recommended SaaS operator tool buckets

```yaml
core:
  - file
  - terminal
  - web
  - skills
  - memory
  - session_search
project_build:
  - browser
  - vision
  - image_gen optional
ops_later:
  - cronjob
  - delegation
  - kanban optional
messaging_later:
  - gateway platform tools via Hermes gateway setup
```

Команды изменения требуют подтверждения:

```bash
hermes tools enable web
hermes tools enable terminal
hermes tools enable file
hermes skills install <url>
```

## Stage 3 pass criteria

```yaml
tools_inventory: collected | user_deferred | unavailable
skills_inventory: collected | user_deferred | unavailable
memory_status: known | user_deferred | unavailable
terminal_status: working | unavailable_with_manual_fallback | user_deferred
browser_status: enabled | disabled | optional | unknown
stage_3_status: pass | blocked | deferred
```

---

# Stage 4 — Messaging/gateway readiness

Цель: подготовить remote operator channel, но не включать gateway без gate.

## Safe read-only commands

```bash
hermes gateway status
hermes status --all 2>/dev/null || true
```

## Explain setup options

```yaml
channels:
  Telegram: good first remote operator channel
  Discord: community/team channel
  Slack: workspace/operator channel
  Email/Gmail: business communication path
  WhatsApp/Signal: optional, platform-dependent
```

Actual setup requires confirmation:

```bash
hermes gateway setup
hermes gateway run
hermes gateway install
```

Secrets/tokens go into Hermes UI/CLI/env/secret store, never chat.

## Stage 4 pass criteria

```yaml
first_channel: Telegram | Discord | Slack | Email | WhatsApp | deferred
secret_entry_path: hermes_ui_or_cli_not_chat
gateway_status: checked | planned | user_deferred | unavailable
gateway_mutation_performed: false unless explicitly gated
stage_4_status: pass | blocked | deferred
```

---

# Stage 5 — SaaS project operator kit

Цель: подготовить агент к работе с SaaS-проектом: brief, backlog, repo/workspace policy, run loop.

## Ask for SaaS brief

Минимальные вопросы:

```text
1. Что за SaaS-продукт?
2. Кто пользователь?
3. Какое первое полезное действие агент должен помогать делать?
4. Где будет workspace/repo?
5. Что нельзя трогать без отдельного gate?
```

## Optional files only after explicit confirmation

Если пользователь подтверждает file creation, создать/предложить:

```text
LAUNCHROOM_PROJECT_BRIEF.md
LAUNCHROOM_BACKLOG.md
LAUNCHROOM_RUNBOOK.md
LAUNCHROOM_READINESS_REPORT.md
```

Но без подтверждения держать это в chat report.

## Stage 5 pass criteria

```yaml
saas_brief: captured | user_deferred
first_use_case: captured | user_deferred
workspace_policy: defined | user_deferred
backlog_seed: chat_only | file_created_by_gate | user_deferred
local_run_loop: defined | not_applicable | user_deferred
stage_5_status: pass | blocked | deferred
```

---

# Stage 6 — CloudRoom + AgentOps readiness

Цель: подготовить production-grade contour без live mutation.

## Readiness surfaces

```yaml
CloudRoom:
  - domain/subdomain plan
  - Cloudflare plan
  - Hetzner/server plan
  - n8n plan
  - secrets path
  - rollback plan
AgentOps:
  - release checklist
  - observability/SLO
  - incident/support flow
  - security/privacy controls
  - supervised autonomy criteria
```

## Safe read-only inventory only after separate gate

Examples:

```bash
wrangler whoami
hcloud context active
hcloud server list
```

Do not run provider commands unless credentials already exist and user explicitly confirms read-only inventory.

## Stage 6 pass criteria

```yaml
cloudroom_plan: defined | user_deferred
provider_inventory: not_run | read_only_checked | user_deferred
n8n_plan: defined | user_deferred
release_gate: defined
observability_plan: defined
incident_plan: defined
supervised_autonomy: defined
runtime_mutation_performed: false
stage_6_status: pass | blocked | deferred
```

---

# Final report required

At the end, output exactly this shape:

```yaml
launchroom_real_hermes_setup_result:
  stage_1_hermes_health_model: pass | blocked | deferred
  stage_2_profile_workspace: pass | blocked | deferred
  stage_3_tools_skills_memory: pass | blocked | deferred
  stage_4_messaging_gateway: pass | blocked | deferred
  stage_5_saas_operator_kit: pass | blocked | deferred
  stage_6_cloudroom_agentops: pass | blocked | deferred
  safe_checks_run:
    - ...
  manual_checks_requested:
    - ...
  user_decisions_needed:
    - ...
  secrets_requested_in_chat: false
  mutations_performed_without_gate: false
  ready_for_real_use: yes | partial | no
  next_owner_decision: one concrete next action
```
