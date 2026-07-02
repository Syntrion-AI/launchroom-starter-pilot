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

### stage_2 - Workspace and project onboarding

Purpose: Create or select the safe local workspace, classify project type, write workspace instructions, and verify terminal.cwd without touching secrets, git, or runtime surfaces.

Pass requires:
- workspace choice collected with button/clarify when available
- project type selected or explicitly deferred
- workspace path validated as not root, home, Hermes runtime, or credential directory
- workspace README.md, AGENTS.md, and HERMES.md written or explicitly deferred
- workspace .hermes/reports/workspace-onboarding-report.yaml exists and parses as YAML
- terminal.cwd equals selected workspace or mismatch is explicitly partial/deferred
- Stage 2 safe scan excludes .env, auth.json, state.db, and .git internals
- no git, provider, gateway, n8n, Cloudflare, Hetzner, or production runtime mutation

### stage_3 - Tool readiness and software purpose map

Purpose: Build a no-secret local tool inventory, explain what each software component is for, and prepare a gated install recommendation package without installing anything.

Pass requires:
- core required tools checked: hermes, python, git
- recommended tools checked: node, npm, ripgrep, uv, winget/package manager
- optional tools checked/deferred: docker, wsl
- software-purpose-map.yaml exists and maps every checked tool to purpose and agent use
- software-install-recommendation.yaml exists and requires explicit install gate
- missing software package produced without running install commands
- WSL treated as optional unless selected
- Docker not started or mutated by Stage 3

### stage_4 - Starter capability pack

Purpose: Map the Stage 3 capability graph to Hermes starter toolsets, skills, memory policy, and workflow playbooks without enabling gated capabilities automatically.

Pass requires:
- Stage 3 capability graph consumed or explicitly deferred
- starter-capability-pack.yaml exists and parses as YAML
- task classes mapped to starter toolsets, skills, memory policy, workflows, gates, and verification
- toolset enablement recommendations recorded without unauthorized enablement
- persistent memory writes require explicit user approval and are not automatic
- network skill installs and unrelated self-patches are absent

### stage_5 - Communication surfaces and channel managers

Purpose: Map Desktop, Telegram, Slack, Email, Discord, additional messaging adapters, and webhooks/API to real user options, official sources, safe guides, gates, and verification without exposing secrets or mutating gateways automatically.

Pass requires:
- communication-channel-map.yaml exists and parses as YAML
- communication-user-guide.md exists and explains available channels in user language
- Desktop, Telegram, Slack, Email, Discord, additional adapters, and webhooks/API are mapped to managers, real options, official sources, gates, and verification
- safe secret-entry paths are explained without asking for tokens in chat
- gateway setup, pairing, home-channel, autostart, and delivery tests remain gated
- no provider/runtime/cloud/n8n mutation is executed

### stage_6 - SaaS operator kit

Purpose: Run an agent-led SaaS operator kit stage: explain Stage 6, create structure, offer common default workflows when the user has no idea, transform idea/workflow into project blueprint, and show the gated path from blueprint to working result without runtime/cloud/provider/gateway/n8n mutation.

Pass requires:
- implementation roadmap explains blueprint to working result
- default workflow catalog exists for users without an idea
- guided-session scaffold exists
- pain-to-workflow examples each include pain, workflow, output, verification, and next decision
- beginner can verify what was generated and what was not executed
- START_HERE.md, NEXT_DECISION.md, CHECK_IT_WORKS.md, and PAIN_TO_WORKFLOW_EXAMPLES.md exist
- .hermes/operator-kit/readiness_report.yaml exists and parses as YAML
- product_brief.md, target_user.md, first_workflow.md, backlog.md, local_task_packet.md, and gates.md exist
- operator kit carries Hermes working artifact / not AIRMIDA authority marker
- first workflow follows intent -> scope -> evidence -> structure -> delivery packet -> execution -> verification -> handoff -> next decision
- runtime/cloud/provider/gateway/n8n/git/secret actions remain false or gated
- next owner decision is explicit

### stage_7 - First slice implementation planning and local pilot readiness

Purpose: Convert the Stage 6 blueprint and first-slice packet into a concrete implementation brief, local pilot plan, acceptance tests, user demo script, rollback plan, and decision gate without executing implementation or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- first-slice planning folder exists
- IMPLEMENTATION_BRIEF.md, LOCAL_PILOT_PLAN.md, ACCEPTANCE_TESTS.md, USER_DEMO_SCRIPT.md, RISKS_AND_ROLLBACK.md, DECISION_GATE.md, and READINESS_REPORT.yaml exist
- READINESS_REPORT.yaml parses as YAML
- Stage 6 blueprint, first slice packet, roadmap, and default workflow catalog are referenced
- acceptance tests and user demo script explain the user-visible working result
- implementation, dependencies, runtime, cloud, gateway, n8n, git publication, and secrets remain false or gated
- next implementation gate is explicit

### stage_8 - Local pilot execution packet

Purpose: Convert the Stage 7 first-slice planning packet into a bounded local-only execution packet with file-change scope, command plan, test plan, evidence log, review checklist, handoff summary, and explicit next gate without executing implementation or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- local pilot execution folder exists
- EXECUTION_PACKET.md, FILE_CHANGE_PLAN.md, COMMAND_PLAN.md, TEST_PLAN.md, EVIDENCE_LOG.md, REVIEW_CHECKLIST.md, HANDOFF_SUMMARY.md, and READINESS_REPORT.yaml exist
- local-pilot/READINESS_REPORT.yaml parses as YAML
- Stage 7 implementation brief, local pilot plan, acceptance tests, user demo script, risks/rollback, decision gate, and readiness report are referenced
- file change plan separates allowed, forbidden, and approval-required paths
- command plan separates read-only commands, gated local commands, and forbidden commands
- test plan maps checks to expected evidence and acceptance criteria
- evidence log is scaffolded and does not fabricate execution results
- implementation, file changes, commands, tests, dependencies, runtime, cloud, gateway, n8n, git publication, and secrets remain false or gated
- next execution gate is explicit

### stage_9 - Project plan integrity and drift audit

Purpose: Audit the Stage 6 blueprint, Stage 7 first-slice plan, and Stage 8 local execution packet before implementation; detect missing fragments, contradictions, incompatible assumptions, skipped stages, execution drift risk, and repair recommendations without executing implementation or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- project audit folder exists
- PLAN_INTEGRITY_REPORT.md, EXPECTED_RESULT_MAP.md, MISSING_FRAGMENTS.md, CONTRADICTION_SCAN.md, STAGE_DRIFT_SCAN.md, ASSUMPTION_REGISTER.md, IMPLEMENTATION_BLOCKERS.md, REPAIR_RECOMMENDATIONS.md, and AUDIT_REPORT.yaml exist
- project-audit/AUDIT_REPORT.yaml parses as YAML
- Stage 6 blueprint, Stage 7 first-slice plan, and Stage 8 local execution packet are referenced
- expected result map separates planned result, user-visible result, acceptance signal, and non-goals
- missing fragments and assumptions are explicitly recorded
- contradiction scan checks blueprint vs first slice vs execution packet vs gates
- stage drift scan checks skipped stages, premature implementation, runtime bypass, and evidence gaps
- execution_allowed is false by default until blockers are resolved or owner accepts partial audit for Stage 10 only
- implementation, file changes, commands, tests, dependencies, runtime, cloud, gateway, n8n, git publication, and secrets remain false or gated
- next repair/readiness decision is explicit

### stage_10 - Agent execution readiness and toolchain activation plan

Purpose: Map the Stage 9 project audit to concrete software, Hermes toolsets, skills, agent pipeline, install gates, command readiness, and execution blockers without installing, enabling, spawning, executing implementation, or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- agent-readiness folder exists
- PROJECT_TOOLCHAIN_REQUIREMENTS.md, SOFTWARE_GAP_ANALYSIS.md, HERMES_TOOLSET_PLAN.md, SKILL_LOAD_PLAN.md, AGENT_PIPELINE_PLAN.md, INSTALL_PLAN.md, COMMAND_READINESS.md, and EXECUTION_READINESS_REPORT.yaml exist
- agent-readiness/EXECUTION_READINESS_REPORT.yaml parses as YAML
- Stage 9 audit, Stage 8 execution packet, Stage 3 software reports, and Stage 4 starter capability pack are referenced
- toolchain requirements map project work to software, Hermes toolsets, skills, agent roles, commands, gates, and verification
- software gap analysis separates present, missing/unknown, optional, and gated install candidates
- install plan includes why, command shape, verification command, risk, rollback, admin/restart/PATH notes, and owner gate
- toolset and skill plans recommend activation/load order without enabling or installing anything automatically
- agent pipeline plan defines planner/repair, toolchain verifier, implementer, verification arbiter, and owner gate without spawning agents
- command readiness separates read-only inspection, gated local commands, install commands, and forbidden runtime/secret/git/publication commands
- execution_ready and execution_allowed remain false until Stage 9 issues are repaired, Stage 10 readiness is accepted, and a separate implementation gate is granted

### stage_11 - Workspace hygiene, cleanup, and artifact lifecycle

Purpose: Create a workspace hygiene and artifact lifecycle package after Stage 10 so future agents know which LaunchRoom workspace artifacts are active, draft, superseded, broken/stale, temporary, do-not-use, archive candidates, and deletion-gated candidates without deleting, moving, renaming, archiving, executing implementation, or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- hygiene folder exists
- START_HERE.md, ARTIFACT_INDEX.md, ACTIVE_FILES.md, SUPERSEDED_FILES.md, BROKEN_OR_STALE_FILES.md, DO_NOT_USE.md, CLEANUP_PLAN.md, ARCHIVE_PLAN.md, DELETION_GATE.md, and HYGIENE_REPORT.yaml exist
- hygiene/HYGIENE_REPORT.yaml parses as YAML
- Stage 10 agent readiness, Stage 9 audit, Stage 8 local pilot, Stage 7 first slice, Stage 6 operator kit, and Stage 3/4 reports are referenced
- artifact index separates active, supporting, draft, superseded, broken/stale, temporary, archive candidate, and deletion-gated classes
- active files identify the current canonical LaunchRoom generated surfaces for future agents
- DO_NOT_USE explains that stale/broken/superseded files must not be used as planning authority and points to replacements when known
- cleanup, archive, and deletion plans remain proposals only and require explicit owner gate
- cleanup, archive, deletion, rename, move, implementation, runtime/cloud/gateway/n8n/git/secret actions remain false


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
