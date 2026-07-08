# LaunchRoom Starter - Run Me First

> Public LaunchRoom test package / not AIRMIDA authority.

Use this file as the executable setup route for a new or default Hermes profile. It is a guided setup wizard, not a passive article. The agent should run the staged setup below, explain each stage in the user's language, and ask for choices before any profile or workspace mutation.

## Full-System Bootstrap v0.7

LaunchRoom v0.7 starts as a Full-System Bootstrap, not a tiny profile checklist. The agent must first make the local Hermes execution surface usable for a real project-builder user, then configure the Default profile as an Engineering SaaS Profile / Profile Factory, then create the user's project profile, and only then begin SaaS/project onboarding.

Corrected first-run order:

```text
Stage 0 -> explain full diagnostic -> Stage 1 full system diagnostic/setup/smoke -> Stage 2 profile inventory -> Stage 3 Engineering SaaS Profile default -> Stage 4 project profile -> Stage 5 project/SaaS onboarding
```

### Corrected model/provider rule

The active conversation proves the current model path is usable for this session. Do not create an early standalone model/provider blocker just because a target profile has not been created yet. Record the active conversation as current-session evidence. Run target-profile model/provider smoke tests after the target profile exists and has its own configuration.

### Full software and capability matrix

Stage 1 must inspect the full software and capability matrix, not a narrow hand-written shortlist. Missing required project-builder software creates a repair or install plan and the agent proceeds to allowed local setup. Only secrets, OAuth, gateway pairing, cloud/runtime/provider mutation, n8n mutation, production deployment, release/tag/publication, and destructive actions remain separately gated.

### Smoke-test rule

Stage 1 pass is impossible without smoke tests. A diagnostic report alone is not enough. The agent must create a diagnostic report, setup plan, perform allowed local non-secret setup or record a gated blocker, then run smoke tests before profile work is allowed.

### Default/profile-factory policy

LaunchRoom creates or uses an isolated Profile Factory profile by default. Promoting or overwriting a real `default` profile is a separate reviewed decision. The Profile Factory must understand Hermes config, profiles, skills, toolsets, memory/context, messaging, MCP readiness, advanced settings, workspace boundaries, gates, smoke tests, and project-profile creation. Machine/profile instructions and skill bodies are written in English.

### Product-mode lock

When this repo or release link is the active task, LaunchRoom becomes the temporary setup authority. The agent must ignore unrelated current projects, prior handoffs, and ambient profile habits until the Default/Profile Factory baseline is complete, the user stops, or a blocked report is delivered. Existing profile memory is evidence only.

### Stage result and transition contract

Every stage must show a short result in chat and save a machine-readable report when the stage owns evidence. Do not hide the meaningful result only in a file. Do not move to the next stage until required steps are complete or blocked, stage status is declared, the chat summary is delivered, required report files are written, and the next decision is explicit.

### Skills/software inventory rule

Before Profile Factory or project-profile decisions, show the skills/software/toolsets inventory, separate LaunchRoom setup needs from later project/SaaS runtime needs, and propose missing installs or skill loads only behind explicit gates.


## Link-to-Operator Bootstrap

If a Hermes agent receives only a GitHub repository or release link, treat this package as a setup package, not a passive article. Prefer the release tag over mutable `main` for installation or acceptance testing. Read `BOOTSTRAP_WITH_HERMES.md`, then this runbook, before scanning the rest of the repository.

First explain the safe boundary in the user's language: local self-test and local profile/workspace setup are separate from runtime, provider, cloud, n8n, gateway, git publication, release, and secret handling.

Do not ask the first project/SaaS brief before Stage 5. Before real setup, offer Full-System Bootstrap setup modes with `clarify` choices when available:

- self-test only
- Engineering SaaS Profile foundation
- existing Hermes profile repair
- advanced/custom

Run the `-TestOutputRoot` self-test before any real setup. Do not ask for secret values in chat, do not copy credential files, and do not mutate runtime/provider/cloud/n8n/gateway surfaces unless a separate gate is granted.

Required safe order:

```text
link -> bootstrap -> RUN_ME_FIRST -> explain full diagnostic -> full-system self-test -> explicit setup gate -> allowed local setup/repair -> smoke tests -> Default Engineering SaaS Profile -> project profile -> PASS/PARTIAL/BLOCKED summary
```


## Project Intake, Surface Routing, and Template Safety

This v0.7.2 layer strengthens the handoff from profile setup into a real project. It is inspired by external starter-template patterns, but LaunchRoom remains the authority for gates and safety. These rules do not authorize implementation, publication, deployment, provider/runtime changes, or secret handling.

### Project intake contract

Collect project intake only after the Profile Factory foundation is ready or explicitly deferred. Do not ask project/product questions before the LaunchRoom setup stages allow it.

Required intake fields:

- `project_name_or_slug`
- `product_goal`
- `first_user_journey`
- `active_surfaces`
- `deferred_surfaces`
- `needs_auth`
- `needs_persistence`
- `needs_uploads_or_media`
- `needs_payments`
- `needs_admin_tools`
- `needs_external_integrations`
- `needs_realtime_or_collaboration`
- `deployment_needed_now`
- `validation_scope`

Plain-language rule: Ask what the user wants to build and which product surfaces are active now; do not force technical stack choices onto a beginner.

### Active/deferred surface routing

Before project-profile or first-slice work, classify each product surface as active now, deferred, gated later, not applicable, or unknown requiring a choice.

Required surfaces:

- `website_public_seo`
- `webapp_authenticated_csr`
- `backend_api`
- `mobile_app`
- `automation_or_n8n`
- `cloud_runtime`

Website/public SEO rule: Use website/public surface for landing pages, docs, catalog/listing/product pages, public SEO, and rich link previews.

Webapp/authenticated CSR rule: Use webapp/authenticated surface for login-protected dashboards, account flows, admin panels, settings, and tools that do not need SEO.

Do not build SEO pages inside the authenticated webapp by habit, and do not move the full authenticated app into the website by habit.

Mobile policy: mobile is `deferred_or_gated_later` by default and activates only after an explicit mobile choice; Expo/EAS/App Store/Google Play/IAP/push remain provider/publication gated.

### Template-origin and git publication safety

Before branch, commit, push, PR, release, or deploy work, inspect `git remote -v` and classify the git work mode.

Git work modes: improving_template, creating_user_project_from_template, existing_project_work

If origin points to the starter/template and this is a new user project: detach/remove template origin or leave publishing unconfigured until the user chooses their own destination repository.

Do not open a PR to the template repository unless the user explicitly grants a template-contribution gate. Do not push without a publication gate. Release/deploy work requires a clean, synced source.

### Acceptance contract

Every non-trivial implementation or local pilot packet must define `primary_signal`, 3-5 `pass_criteria`, `secondary_signals`, `evidence_required`, and `cannot_claim_done_if` before execution.

Cannot claim done if:

- only a plan or stub was written for a requested working result
- only terminal output exists and no user-visible stage result was delivered
- validators or smoke tests were skipped without an explicit partial/blocker explanation
- acceptance evidence is fabricated or copied from a previous run

### Local pilot isolation

Local pilots and data-backed tests must use test data only. If a database URL is present, test plans require a `*_test` database name or an explicit override gate, prefer repo-derived/isolated ports for parallel checkouts, and stop instead of repairing when the data target is ambiguous.

## Primary setup tool

For CI-grade non-mutating generation checks, run the installer in self-test mode:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

`-TestOutputRoot` writes a simulated profile/workspace tree only under the supplied path and must not call `hermes profile create`, `hermes config set`, or `hermes tools enable`.

The primary setup path after self-test and explicit target approval is the real profile installer, not a manual stage walkthrough:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\LaunchRoom\launchroom" -UserLanguage auto -Yes
```

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

Use the Hermes `clarify` tool for interactive decisions whenever it is available. Real Desktop buttons require a pending `clarify` tool call with a non-empty `choices` array; Telegram native buttons are adapter-specific and also come from `clarify`, not from markdown. Put selectable options only in the `choices` array, not inside the question text. Required clarify decisions: profile strategy, workspace strategy, apply setup tool, software install gate, starter capability pack, communication channel, every stage transition, git publication gate, implementation gate, and runtime/provider/secret/destructive-action gates. Plain A/B/C or numbered text is fallback only when `clarify` or native buttons are unavailable.

## Beginner Wizard Rooms

These rooms are a user-facing navigation layer over the machine stages. They do not replace or collapse the stage contracts; validators still check each stage separately.

### Room 1: Foundation Room

Stages: bootstrap_0, stage_1, stage_2

User goal: Make Hermes, the profile, and the project workspace understandable and safe before any larger setup.

Plain-language result: You know where you are working, which profile is active, what local workspace is selected, and what is allowed next.

Next decision: Continue to capability checks or pause after foundation setup.

### Room 2: Capability Room

Stages: stage_3, stage_4, stage_5

User goal: Understand local software, Hermes capabilities, starter skills, and communication surfaces without enabling gated integrations automatically.

Plain-language result: You know what the operator can do locally, what is missing, and which communication channels are possible after separate gates.

Next decision: Choose a product starter path or pause with a capability map.

### Room 3: Product Starter Room

Stages: stage_6, stage_7, stage_8

User goal: Turn an idea or pain point into a tiny SaaS/workflow slice, then prepare a bounded local execution packet.

Plain-language result: You have a product/workflow brief, first-slice plan, acceptance tests, demo script, command plan, and next execution gate.

Next decision: Audit the plan before any real implementation.

### Room 4: Readiness & Drift Room

Stages: stage_9, stage_10

User goal: Check plan integrity, contradictions, missing fragments, drift risk, and real agent/toolchain readiness before implementation.

Plain-language result: You know whether the plan is coherent, what blocks execution, which tools/skills/agents are needed, and what remains gated.

Next decision: Repair blockers, accept readiness, or pause before control/evidence setup.

### Room 5: Control & Evidence Room

Stages: stage_11, stage_12, stage_13

User goal: Prevent artifact drift, capture reusable skills, and prepare a real execution evidence binder before claiming work is complete.

Plain-language result: You know which artifacts are active, which skills matter, and where real commands/files/tests/results must be recorded after execution.

Next decision: Open a separate implementation gate or close the setup flow with evidence.

Room transitions should use the Hermes `clarify` tool with `choices` when available; plain text choices are fallback only.

## Wizard Room Transition UX

This is a room-level interaction layer over the Beginner Wizard Rooms. It is not Stage 14, does not replace machine stages, and does not authorize implementation, runtime, provider, gateway, n8n, git publication, or secret handling by itself.

Required transition actions: enter_room, complete_room, pause, inspect_evidence, continue_to_next_room, retry_or_repair

### Clarify prompt contract

Room transition prompts must use the Hermes `clarify` tool with a non-empty `choices` array when available. The question text contains only the question; selectable options live only in `choices`. Plain A/B/C or numbered text is fallback only when `clarify` or native buttons are unavailable. Timeout or silence is not approval.

### Prompt templates

#### room_entry

Purpose: Ask whether to enter the room, inspect current evidence, repair an issue, or pause.

Choices: Enter room, Inspect evidence, Retry or repair, Pause

#### room_completion

Purpose: Ask whether the room is complete, whether to continue, inspect evidence, or pause.

Choices: Complete room, Continue to next room, Inspect evidence, Pause

#### blocked_room

Purpose: Ask how to handle a room blocker without treating timeout or prose as approval.

Choices: Retry or repair, Inspect evidence, Pause

#### final_room_completion

Purpose: Ask how to close the final room without implying implementation or runtime approval.

Choices: Complete room, Inspect evidence, Pause

### Room transition map

- Foundation Room: entry `room_entry`, completion `room_completion`, blocked `blocked_room`, next `room_2_capability`
- Capability Room: entry `room_entry`, completion `room_completion`, blocked `blocked_room`, next `room_3_product_starter`
- Product Starter Room: entry `room_entry`, completion `room_completion`, blocked `blocked_room`, next `room_4_readiness_and_drift`
- Readiness & Drift Room: entry `room_entry`, completion `room_completion`, blocked `blocked_room`, next `room_5_control_and_evidence`
- Control & Evidence Room: entry `room_entry`, completion `final_room_completion`, blocked `blocked_room`, next `final closeout / next gated decision`

## First-run Demo / Self-test Scenario

This scenario demonstrates LaunchRoom Starter as a beginner-safe onboarding wizard. It uses self-test mode only, is not a new stage, and must stop before installs, gateway pairing, provider/runtime changes, cloud/n8n mutation, git publication, secret handling, or implementation execution.

### Self-test command

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

### Demo path

#### demo_1_prepare_repo

Room/context: repo/self-test

Action: prepare_repo

User-visible text: Clone or open the LaunchRoom Starter repository and read RUN_ME_FIRST.md.

Expected evidence: RUN_ME_FIRST.md exists; scripts/install_launchroom_profile.ps1 exists

#### demo_2_run_self_test

Room/context: repo/self-test

Action: run_self_test

User-visible text: Run the self-test command with -TestOutputRoot so generated files go to a disposable test tree.

Expected evidence: validate_profile_setup_tool self-test generated files ok; no live Hermes profile/config/toolset mutation

#### demo_3_enter_foundation_room

Room/context: room_1_foundation

Action: enter_room

User-visible text: Enter Foundation Room and confirm what profile/workspace foundation means.

Expected evidence: Foundation Room is visible; room_entry clarify choices are available or fallback is labeled

#### demo_4_inspect_foundation_evidence

Room/context: room_1_foundation

Action: inspect_evidence

User-visible text: Inspect generated foundation evidence before continuing.

Expected evidence: profile SOUL.md or deferred marker; profile contract/report artifacts or deferred marker; workspace README/AGENTS/HERMES or deferred marker

#### demo_5_continue_to_capability_room

Room/context: room_2_capability

Action: continue_to_next_room

User-visible text: Continue to Capability Room without enabling tools, installing software, or connecting communication channels.

Expected evidence: Capability Room is visible; software/toolset/channel steps remain recommendations or gated decisions

#### demo_6_stop_at_gated_decision

Room/context: room_2_capability

Action: pause

User-visible text: Stop at the first gated decision and report what was demonstrated versus what remains gated.

Expected evidence: runtime/cloud/gateway/n8n/git/secret/implementation actions remain false or gated; next decision is explicit

### Expected self-test outputs

- simulated profile directory under TestOutputRoot
- profile SOUL.md
- profile PROFILE_INSTRUCTIONS.md
- profile LAUNCHROOM_PROFILE_CONTRACT.yaml
- profile .env.EXAMPLE with variable names only
- profile reports/profile-foundation-report.yaml
- profile reports/profile-apply-plan.yaml
- profile reports/stage-1-selected-settings.yaml
- workspace README.md
- workspace AGENTS.md
- workspace HERMES.md
- workspace .hermes/reports/profile-setup-report.yaml
- LaunchRoom starter skill pack in the simulated profile tree

### What the user should see

- User can see the 5 Wizard Rooms as the simple navigation layer.
- User can see room transition choices for enter, inspect evidence, continue, retry/repair, and pause.
- User can identify where self-test files were generated.
- User can distinguish demonstrated self-test behavior from real profile/workspace mutation.
- User can see that installs, gateway pairing, provider/runtime, n8n/cloud, git publication, secret handling, and implementation remain gated.
- User receives a clear next decision after the demo stops.

### Stop before gated actions

- software_install
- hermes_toolset_enablement
- gateway_setup_or_pairing
- provider_or_model_runtime_change
- cloud_or_vps_mutation
- n8n_mutation
- git_publication_or_release
- secret_readback_or_storage
- implementation_execution

## Release / Distribution Readiness

This section prepares LaunchRoom Starter for a clear public/test distribution package. It is readiness only: it does not create a GitHub release, tag, package publication, deployment, provider/runtime change, gateway pairing, Cloudflare/Hetzner/n8n mutation, distribution broadcast, or secret-handling path.

### Distribution quickstart

#### dist_1_read_repository_front_page

Surface: README.md

User action: Read what LaunchRoom Starter is, what it is not, and where the canonical runbook lives.

Expected result: User understands this is a public test package and not AIRMIDA authority.

#### dist_2_open_canonical_runbook

Surface: RUN_ME_FIRST.md

User action: Open the canonical runbook or raw GitHub RUN_ME_FIRST link in a fresh Hermes session.

Expected result: Hermes receives the guided setup route and mirrors the user language in conversation.

#### dist_3_run_safe_self_test

Surface: scripts/install_launchroom_profile.ps1

User action: Run the self-test command with -TestOutputRoot before doing real profile/workspace setup.

Expected result: Generated files appear in the disposable self-test tree without live Hermes profile/config/toolset mutation.

#### dist_4_run_primary_installer_after_choice

Surface: scripts/install_launchroom_profile.ps1

User action: Run the primary installer only after choosing the target profile/workspace and understanding the non-secret mutation scope.

Expected result: Profile/workspace setup artifacts are generated locally; runtime/provider/gateway/cloud/n8n/git/secret actions remain gated.

#### dist_5_stop_at_release_gate

Surface: release gate

User action: Do not create tags, GitHub releases, package publication, public website updates, or distribution broadcasts without a separate owner release gate.

Expected result: Release readiness can be reported without performing public release actions.

### Artifact manifest

- `README.md` — repository front page and quickstart (required)
- `RUN_ME_FIRST.md` — canonical guided runbook (required)
- `generated/RUN_ME_FIRST.md` — generated runbook mirror (required)
- `source/launchroom.starter.v0_5.json` — source behavior/stage/UX/distribution contract (required)
- `contracts/launchroom-stage-contract.json` — generated contract artifact (required)
- `scripts/install_launchroom_profile.ps1` — primary setup and self-test tool (required)
- `scripts/build_agentpack.py` — generated artifact builder (required)
- `scripts/validate_behavior_contract.py` — behavior/UX/distribution validator (required)
- `scripts/validate_profile_setup_tool.py` — installer self-test validator (required)
- `profile-distribution/launchroom-saas` — profile distribution payload (required)

### Release readiness checklist

- README explains package purpose, quickstart, validation, and release boundary.
- RUN_ME_FIRST contains primary setup path, self-test path, wizard rooms, room transitions, first-run demo, and distribution readiness section.
- Source and generated contracts include the release/distribution readiness contract.
- Artifact manifest points to required user-facing, source, generated, installer, and validator surfaces.
- Validation commands are listed and run locally before PR publication.
- Secret-handling rules are explicit; .env/auth/state/OAuth stores are never copied or printed.
- No GitHub release, tag, package publication, website publication, runtime/provider/gateway/cloud/n8n mutation, or broadcast is performed without a separate owner release gate.

### Blocked until separate owner release gate

- git_tag_creation
- git_tag_push
- github_release_creation
- package_registry_publication
- public_website_or_landing_page_publication
- distribution_broadcast_to_channels
- provider_or_model_runtime_change
- gateway_pairing_or_home_channel_change
- cloudflare_hetzner_n8n_mutation
- secret_collection_readback_or_storage

Release readiness is not release execution. No tag, GitHub release, package publication, website publication, runtime/provider/gateway/cloud/n8n mutation, distribution broadcast, or secret handling is authorized by this section.

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

### stage_6 - SaaS operator kit and project intake

Purpose: Run an agent-led SaaS operator kit stage: explain Stage 6, collect product intake, classify active/deferred surfaces, create structure, offer common default workflows when the user has no idea, transform idea/workflow into project blueprint, and show the gated path from blueprint to working result without runtime/cloud/provider/gateway/n8n mutation.

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
- project intake report records project name/slug, product goal, first user journey, active/deferred surfaces, auth/persistence/uploads/payments/realtime/deployment needs, and validation scope
- website vs webapp routing is explained in product terms when browser surfaces are active
- mobile surface remains deferred/gated unless the user explicitly activates mobile
- template-origin git safety mode is classified before publication or PR work

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
- acceptance contract defines primary signal, 3-5 pass criteria, secondary signals, required evidence, and cannot-claim-done conditions
- active/deferred surfaces from Stage 6 are referenced before first-slice implementation planning

### stage_8 - Local pilot execution packet

Purpose: Convert the Stage 7 first-slice planning packet into a bounded local-only execution packet with file-change scope, command plan, test plan, external best-practice inputs, evidence log, review checklist, handoff summary, and explicit next gate without executing implementation or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- local pilot execution folder exists
- EXECUTION_PACKET.md, FILE_CHANGE_PLAN.md, COMMAND_PLAN.md, TEST_PLAN.md, EXTERNAL_PRACTICE_INPUTS.md, EVIDENCE_LOG.md, REVIEW_CHECKLIST.md, HANDOFF_SUMMARY.md, and READINESS_REPORT.yaml exist
- local-pilot/READINESS_REPORT.yaml parses as YAML
- Stage 7 implementation brief, local pilot plan, acceptance tests, user demo script, risks/rollback, decision gate, and readiness report are referenced
- file change plan separates allowed, forbidden, and approval-required paths
- command plan separates read-only commands, gated local commands, and forbidden commands
- test plan maps checks to expected evidence and acceptance criteria
- evidence log is scaffolded and does not fabricate execution results
- implementation, file changes, commands, tests, dependencies, runtime, cloud, gateway, n8n, git publication, and secrets remain false or gated
- external starter-template practices are mapped into LaunchRoom rules instead of copied as authority
- package manager, workspace scripts, command sources, test level selection, data target, port strategy, provider gates, and mobile gates are recorded before execution
- commands are derived from inspected repository scripts or explicit owner-approved commands, not guessed from framework habit
- next execution gate is explicit
- local pilot isolation rules forbid tests against production/development data targets
- data-backed test plans require *_test database names or an explicit override gate when applicable
- repo-derived or isolated ports are preferred for parallel local checkouts

### stage_9 - Project plan integrity and drift audit

Purpose: Audit the Stage 6 blueprint, Stage 7 first-slice plan, and Stage 8 local execution packet before implementation; detect missing fragments, contradictions, incompatible assumptions, skipped stages, execution drift risk, and repair recommendations without executing implementation or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- project audit folder exists
- PLAN_INTEGRITY_REPORT.md, EXPECTED_RESULT_MAP.md, MISSING_FRAGMENTS.md, AUDIT_FINDINGS.yaml, CONTRADICTION_SCAN.md, STAGE_DRIFT_SCAN.md, ASSUMPTION_REGISTER.md, IMPLEMENTATION_BLOCKERS.md, REPAIR_RECOMMENDATIONS.md, and AUDIT_REPORT.yaml exist
- project-audit/AUDIT_REPORT.yaml parses as YAML
- Stage 6 blueprint, Stage 7 first-slice plan, and Stage 8 local execution packet are referenced
- Stage 8 external practice inputs are referenced before auditing execution readiness
- expected result map separates planned result, user-visible result, acceptance signal, and non-goals
- missing fragments and assumptions are explicitly recorded
- AUDIT_FINDINGS.yaml records stable finding IDs, categories, severity, status, source artifacts, execution-block impact, and required repair actions
- Audit findings are consumed by Stage 10 before agent/toolchain readiness can claim execution readiness
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
- Stage 9 audit report and audit findings, Stage 8 execution packet, Stage 3 software reports, and Stage 4 starter capability pack are referenced
- Stage 9 audit findings inform execution blockers and owner repair decisions before any implementation gate
- Stage 8 external practice inputs inform toolchain, command, test, provider, and mobile gate readiness without activating anything automatically
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

### stage_12 - Skill capture and stage skill integration pack

Purpose: Create a stage skill matrix and skill-capture package after Stage 11 so future LaunchRoom runs know which skills are required, optional, missing, capture-worthy, and promotion-gated without installing, patching, promoting, loading skills automatically, writing memory, executing implementation, or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- skills folder and skills-candidates root exist
- START_HERE.md, STAGE_SKILL_MATRIX.md, REQUIRED_SKILLS.md, OPTIONAL_SKILLS.md, MISSING_SKILLS.md, SKILL_CAPTURE_GUIDE.md, SKILL_CANDIDATE_TEMPLATE.md, SKILL_PROMOTION_GATE.md, SKILL_INTEGRATION_REPORT.yaml, and skills-candidates/README.md exist
- skills/SKILL_INTEGRATION_REPORT.yaml parses as YAML
- Stage 11 hygiene, Stage 10 readiness, Stage 9 audit, Stage 4 capability pack, and Stage 3 capability graph are referenced
- stage skill matrix maps Stage 1 through Stage 12 to required skills, optional skills, and load timing
- required, optional, and missing skill registers distinguish available/recommended/gated candidates without claiming automatic installation
- skill capture guide explains when a proven workflow should become a skill candidate and what evidence is required
- candidate template includes SKILL.md, evidence, validation, and promotion gate sections
- promotion gate requires owner review, validation evidence, no secret content, no stale task progress, and explicit install/promote decision
- skill install, patch, promotion, memory write, implementation, runtime/cloud/gateway/n8n/git/secret actions remain false

### stage_13 - Local execution evidence binder

Purpose: Create a local execution evidence binder after Stage 12 so future gated implementation can record real executed commands, changed files, test results, acceptance evidence, user-visible results, residual risks, and rollback/handoff without fabricating evidence, executing implementation, or mutating runtime/cloud/provider/gateway/n8n surfaces.

Pass requires:
- execution-evidence folder exists
- START_HERE.md, EXECUTED_COMMANDS.md, CHANGED_FILES.md, TEST_RESULTS.md, ACCEPTANCE_EVIDENCE.md, USER_VISIBLE_RESULT.md, RESIDUAL_RISKS.md, ROLLBACK_AND_HANDOFF.md, and EXECUTION_EVIDENCE_REPORT.yaml exist
- execution-evidence/EXECUTION_EVIDENCE_REPORT.yaml parses as YAML
- Stage 12 skills, Stage 11 hygiene, Stage 10 readiness, Stage 9 audit, and Stage 8 local pilot execution packet are referenced
- executed commands, changed files, test results, acceptance evidence, and user-visible result files are clearly marked as scaffolds until real gated execution fills them
- binder forbids fabricated evidence and distinguishes planned commands from executed commands
- residual risks and rollback/handoff sections exist for closeout
- Stage 13 does not execute implementation, commands, tests, file changes, dependency installs, runtime/cloud/gateway/n8n/git/secret actions
- acceptance evidence is tied back to the acceptance contract primary signal and pass criteria
- execution evidence distinguishes planned commands from actually executed commands and never fabricates results


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
