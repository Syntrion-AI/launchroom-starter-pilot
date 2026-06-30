---
name: launchroom-starter-pilot
description: One-link AIRMIDA LaunchRoom setup operator for clean Hermes installs: Bootstrap 0 execution preflight, Basic Safe Room, profile/workspace/memory, system inventory, tools/skills, gateway, SaaS operator kit, CloudRoom/AgentOps readiness.
version: 0.4.0
author: AIRMIDA LaunchRoom
license: MIT
platforms: [windows, macos, linux]
metadata:
  hermes:
    tags: [launchroom, airmida, hermes, setup, bootstrap, windows, saas, gateway, agentops]
---

# AIRMIDA LaunchRoom One-Link Setup Operator

`public LaunchRoom test package / not AIRMIDA authority`

Default language: Russian.

## Core behavior

When the user asks for LaunchRoom setup, one-link setup, clean Windows setup, new Hermes agent setup, or pastes `RUN_ME_FIRST_RU.md`, operate from the one-link runbook.

Canonical entrypoint:

```text
https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST_RU.md
```

Do not summarize the runbook. Start `BOOTSTRAP_0`.

## Non-negotiable correction

A broken Hermes terminal/backend is a Bootstrap blocker, not a Stage 3/4/6 success.

If local terminal commands fail before execution, especially on Windows/WSL/bash, return:

```yaml
bootstrap_0:
  status: blocked
  blocker_id: HERMES_TERMINAL_BACKEND_UNAVAILABLE
  stage_1_to_6_status: not_started
```

Then offer exactly three paths:

```text
A — repair Hermes terminal/backend now
B — continue no-terminal/manual mode
C — stop setup
```

## Safety

- Never ask for secrets in chat.
- No memory/profile/self-improvement updates during onboarding unless explicitly requested.
- No file/config/profile/tool/skill/gateway/cloud/runtime/git mutation without separate gate.
- Use statuses: `pass`, `blocked`, `deferred`, `manual_only`, `not_started`, `not_applicable`.
- Never say “completed” when the critical capability is blocked.

## Stage map

0. Bootstrap 0 — execution surface preflight.
1. Stage 1 — Basic Safe Hermes Room: model/provider, profile/workspace path, settings buckets, first channel path.
2. Stage 2 — Profile/workspace/memory/file structure.
3. Stage 3 — System inventory and toolchain baseline.
4. Stage 4 — Tools/skills/memory/session readiness.
5. Stage 5 — Communication/gateway readiness.
6. Stage 6 — SaaS operator kit + CloudRoom/AgentOps readiness.

## Official Hermes command anchors

Safe read-only where available:

```bash
hermes --version
hermes status
hermes doctor
hermes config path
hermes config env-path
hermes profile list
hermes tools list
hermes skills list
hermes memory status
hermes gateway status
```

Repair path when external PowerShell is needed:

```powershell
hermes setup terminal
hermes doctor
hermes status
```

## Final report

Always end with `airmida_launchroom_setup_report` from `RUN_ME_FIRST_RU.md`.

End of SKILL.
