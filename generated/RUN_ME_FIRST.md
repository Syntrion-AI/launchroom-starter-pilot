# LaunchRoom Starter - Run Me First

> Public LaunchRoom test package / not AIRMIDA authority.

Use this file as the executable setup route for a new or default Hermes profile. It is a guided setup wizard, not a passive article. The agent should run the staged setup below, explain each stage in the user's language, and ask for choices before any profile or workspace mutation.

## Language contract

- Repository documentation, source contracts, scripts, validators, and generated canonical artifacts are written in English.
- The conversation with the user must use the language the user writes in.
- Do not force a fixed language set. Detect and mirror the user's language.
- Localized triggers, examples, and quoted user text may use the user's language when clearly labeled.

## Permission model

The starting prompt authorizes the agent to perform non-destructive LaunchRoom checks and to continue through the stages. The agent must pause for choices and mutations, not for every read-only check.

### T0 - Read-only checks allowed immediately

- Check Hermes version/status/config paths.
- Check profile name and non-secret paths.
- Check local tool versions and availability.
- Inspect whether workspace folders exist.

### T1 - User-choice setup allowed after a clear choice

- Create the selected local workspace folder.
- Set non-secret Hermes config values for the active test/project profile.
- Set `terminal.cwd` to the selected workspace.
- Write workspace-local instructions and readiness reports.
- Install or load an approved LaunchRoom starter skill pack if the user chooses it.

### T2 - Install or external setup requires a separate install gate

- Install missing local software.
- Run `hermes setup tools`, `hermes setup terminal`, or `hermes gateway setup` when the user chooses that path.

### T3 - Runtime/provider/cloud requires a separate owner gate

Cloudflare, Hetzner, n8n, billing, production deployment, provider credential changes, public repository publication, and release actions are not authorized by this runbook.

## Hard safety rules

- Never ask the user to paste secrets, tokens, passwords, private keys, OAuth values, or connection strings in chat.
- Never copy `.env`, `auth.json`, `state.db`, OAuth stores, or session stores between profiles.
- Never patch unrelated installed skills as self-improvement during onboarding.
- If unauthorized self-improvement or profile mutation occurs, stop and report `failed_policy_violation`.
- Evidence for pass/block status must come from the current run or explicitly fresh sanitized user output.
- Contradictory evidence in the same report means `invalid_bootstrap_report`, not pass.

## Stage machine

A stage passes only when checks are complete or explicitly deferred, required choices are collected or explicitly deferred, selected allowed setup actions are completed and verified, and the evidence ledger is present.

### bootstrap_0 - Execution surface

Purpose: Confirm Hermes can run safe local checks or enter an explicit manual/repair path.

Pass requires:
- agent direct terminal check pass or manual_only status recorded
- no contradictory evidence

### stage_1 - Model and profile foundation

Purpose: Make the active Hermes profile understandable and prepare it for LaunchRoom setup.

Pass requires:
- active profile identified
- model path understood
- profile setup choice offered and applied or deferred

### stage_2 - Workspace and project room

Purpose: Create or select the safe local workspace for the SaaS project.

Pass requires:
- workspace choice collected
- workspace created/selected or deferred
- terminal.cwd set when approved

### stage_3 - System inventory and software package

Purpose: Build a no-secret inventory and recommend required/recommended/optional software.

Pass requires:
- core tools checked
- missing software package produced
- WSL treated as optional unless selected

### stage_4 - Tools, skills, memory, starter capability pack

Purpose: Turn available Hermes capabilities into a starter operating profile.

Pass requires:
- tools/skills/memory status checked
- capability pack proposed
- unauthorized self-patch absent

### stage_5 - Communications

Purpose: Choose and prepare the first user communication channel without secrets in chat.

Pass requires:
- channel selected or deferred
- safe secret-entry path explained

### stage_6 - SaaS operator kit

Purpose: Create the first local SaaS project operating packet after profile/workspace/readiness are clear.

Pass requires:
- product brief collected
- local operator kit created after confirmation or explicitly deferred


## Inventory rule

WSL is optional for Local backend and must not block Starter when local terminal works. Stage 3 must check the core local toolchain and produce a software recommendation package instead of stopping on optional WSL errors.

## Required final report

At the end of each stage, report:

```yaml
stage:
status:
evidence:
changes_made:
plain_language_meaning:
next_choice:
```

At the end of Starter, report what works now, what remains gated, and the next local task.
