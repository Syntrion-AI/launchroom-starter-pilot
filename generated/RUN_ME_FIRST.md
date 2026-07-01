# LaunchRoom Starter - Run Me First

> Public LaunchRoom test package / not AIRMIDA authority.

Use this file as the executable setup route for a new or default Hermes profile. It is a guided setup wizard, not a passive article. The agent should run the staged setup below, explain each stage in the user's language, and ask for choices before any profile or workspace mutation.

## Primary setup tool

The primary setup path is the real profile installer, not a manual stage walkthrough:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\LaunchRoom\launchroom" -UserLanguage auto -Yes
```

For CI-grade non-mutating generation checks, run the installer in self-test mode:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

`-TestOutputRoot` writes a simulated profile/workspace tree only under the supplied path and must not call `hermes profile create`, `hermes config set`, or `hermes tools enable`.

When the repository is used through a raw GitHub link, ask the user to clone or download the repository before running the script. If the script cannot be run, the agent may perform the equivalent steps manually from `profile-distribution/launchroom-saas`, but Stage 1/2/4 must not be marked `pass` until the same artifacts exist or are explicitly deferred:

- profile `SOUL.md`;
- profile `PROFILE_INSTRUCTIONS.md` and `LAUNCHROOM_PROFILE_CONTRACT.yaml`;
- profile `.env.EXAMPLE` with variable names only;
- non-secret Hermes config values including `terminal.cwd`, `approvals.mode`, secret redaction, Tirith safety, checkpoints, output limits, and memory settings;
- profile `reports/profile-foundation-report.yaml`, `reports/profile-apply-plan.yaml`, and `reports/stage-1-selected-settings.yaml`;
- workspace `README.md`, `AGENTS.md`, and `HERMES.md`;
- workspace `.hermes/reports/profile-setup-report.yaml`;
- workspace `.hermes/reports/software-inventory-report.yaml`;
- bundled LaunchRoom starter skills in the target profile.

## Decision UI contract

Use interactive decision buttons / `clarify` whenever the platform provides them. Required button decisions: profile strategy, workspace strategy, apply setup tool, software install gate, starter capability pack, communication channel, and every stage transition. If buttons are unavailable, use a short A/B/C fallback.

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

T1 is expected to create a configured LaunchRoom profile layer. A profile that remains blank/default after Stage 1 is not pass.

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
- profile setup tool run or explicitly deferred
- profile SOUL.md and non-secret config verified or explicitly deferred

### stage_2 - Workspace and project room

Purpose: Create or select the safe local workspace for the SaaS project.

Pass requires:
- workspace choice collected with button/clarify when available
- workspace created/selected or deferred
- workspace AGENTS.md and HERMES.md written or explicitly deferred
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
- LaunchRoom starter skills installed or explicitly deferred
- capability pack report present
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
