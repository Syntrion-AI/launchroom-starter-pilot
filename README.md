# LaunchRoom Starter Pilot

LaunchRoom Starter is a public test package that turns a new or default Hermes profile into a safe local SaaS project operator room.

It is not AIRMIDA authority. It is a productization pilot for onboarding, profile setup, workspace setup, software inventory, starter capability readiness, communication setup paths, a local SaaS operator kit, beginner Wizard Rooms, room transitions, and a first-run self-test demo.


## Full-System Bootstrap v0.7

LaunchRoom v0.7 is a full-system setup product. It does not start by asking for the SaaS/project brief. It starts by diagnosing and preparing the local Hermes execution surface for a real project-builder user.

Required order:

```text
Stage 0 greeting and diagnostic announcement -> Stage 1 full system diagnostic/setup/smoke -> Stage 2 profile inventory -> Stage 3 Default as Engineering SaaS Profile / Profile Factory -> Stage 4 user/project profile -> Stage 5 project/SaaS onboarding
```

Key corrections:

- The active conversation proves the current model path is usable for this session; target-profile model/provider smoke tests happen after that target profile exists.
- The system software check uses a full software and capability matrix, not a tiny checklist.
- Stage 1 creates a diagnostic report, setup plan, and smoke test report; Stage 1 pass is impossible without smoke tests.
- Missing required builder software creates a repair/install plan instead of being ignored as optional noise.
- Machine/profile instructions and skill bodies are written in English.


## Product-mode lock

When a Hermes agent receives this repository or a LaunchRoom release link, LaunchRoom becomes the temporary setup authority. The agent must ignore unrelated current projects, prior handoffs, and ambient profile habits until the Default/Profile Factory baseline is complete, the user stops, or a blocked report is delivered. Existing profile memory is evidence only, not routing authority.

## Stage result contract

Every stage must end with a short user-visible result in chat and a machine-readable report when the stage owns evidence. The user-visible result must show: status, what was checked, what changed, what was not touched, skills/software status, report path, and the next required decision. A bare `PARTIAL` is not enough; use `SAFE_SELF_TEST_PASS` or `PARTIAL_NEXT_GATE_REQUIRED` with the exact next gate.

## Start here

For a default Hermes agent that receives only this GitHub repository or release link, start with the Link-to-Operator Bootstrap:

```text
BOOTSTRAP_WITH_HERMES.md
```

Then use the canonical English runbook:

```text
https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST.md
```

Paste that link into a fresh Hermes session. The agent should use your language for conversation while keeping project documentation and machine contracts in English.

## Quickstart

1. Read this front page and confirm the package boundary: public test package, not AIRMIDA authority.
2. Open `RUN_ME_FIRST.md` or paste the raw `RUN_ME_FIRST.md` URL into a fresh Hermes session.
3. Run the self-test before real setup when you want a disposable proof run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

4. Run the primary installer only after choosing the target profile/workspace and understanding the non-secret mutation scope.
5. Stop before any release, tag, runtime, provider, gateway, cloud, n8n, broadcast, or secret-handling action unless a separate owner gate is granted.

## Primary setup tool

The real setup path is the Windows installer script, not only a chat walkthrough:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\LaunchRoom\launchroom" -UserLanguage auto -Yes
```

The script creates or selects the Hermes profile, applies non-secret config, writes profile `SOUL.md`, creates workspace `README.md`/`AGENTS.md`/`HERMES.md`, installs local LaunchRoom starter skills, collects a no-secret software inventory, and writes setup reports. It does not copy `.env`, `auth.json`, `state.db`, OAuth stores, session stores, or secret values.

## What this package should do

- Verify the Hermes execution surface.
- Explain and configure the active profile using non-secret settings after your choice.
- Help choose/create a safe project workspace.
- Inventory local software and recommend a required/recommended/optional package.
- Inspect tools, skills, and memory readiness.
- Offer a starter capability pack.
- Prepare a communication channel path without secrets in chat.
- Create a local SaaS operator kit after Stage 6 confirmation.
- Present 5 beginner Wizard Rooms over the machine stages.
- Use room transition prompts with real `clarify` choices when available.
- Demonstrate the first-run path through a safe self-test scenario.
- Prepare release/distribution readiness without performing release execution.

## Distribution artifact manifest

| Artifact | Role |
| --- | --- |
| `README.md` | Repository front page and quickstart |
| `BOOTSTRAP_WITH_HERMES.md` | Link-to-Operator Bootstrap for default Hermes agents receiving only a repo/release link |
| `RUN_ME_FIRST.md` | Canonical guided runbook |
| `generated/RUN_ME_FIRST.md` | Generated runbook mirror |
| `source/launchroom.starter.v0_5.json` | Source behavior/stage/UX/distribution contract |
| `source/full-system-bootstrap/launchroom-v0.7-stage-map.yaml` | Full-System Bootstrap v0.7 stage map |
| `source/full-system-bootstrap/full-system-software-and-capability-inventory.yaml` | Full software and capability matrix |
| `source/skillpacks/launchroom-full-system-skillpack.v0_7.yaml` | Full curated v0.7 LaunchRoom skillpack contract |
| `contracts/launchroom-full-system-bootstrap-contract.yaml` | Full-System Bootstrap v0.7 contract |
| `source/skillpacks/launchroom-skillpacks.v0_1.yaml` | Curated staged skillpack registry, including hidden/advanced candidates and sanitized abstraction pack boundaries |
| `source/skillpacks/SANITIZED_ABSTRACTION_BOUNDARY.md` | Boundary that forbids mutating AIRMIDA internal skills when creating LaunchRoom sanitized abstractions |
| `source/skills/launchroom-sanitized-abstractions/launchroom-memory-governance/SKILL.md` | First customer-safe LaunchRoom memory governance abstraction skill |
| `source/skills/launchroom-sanitized-abstractions/launchroom-positive-result-capture/SKILL.md` | Second customer-safe LaunchRoom positive-result capture abstraction skill |
| `source/skills/launchroom-sanitized-abstractions/launchroom-tool-readiness-smoke/SKILL.md` | Third customer-safe LaunchRoom tool-readiness smoke abstraction skill |
| `generated/SKILLPACKS.md` | Human-readable generated skillpack guide |
| `contracts/launchroom-stage-contract.json` | Generated contract artifact |
| `scripts/install_launchroom_profile.ps1` | Primary setup and self-test tool |
| `scripts/build_agentpack.py` | Generated artifact builder |
| `scripts/validate_behavior_contract.py` | Behavior/UX/distribution validator |
| `scripts/validate_skillpack_registry.py` | Skillpack registry validator |
| `scripts/validate_profile_setup_tool.py` | Installer self-test validator |
| `profile-distribution/launchroom-saas` | Profile distribution payload |

## Permission model

LaunchRoom grants bounded local setup permissions instead of only listing restrictions:

- T0: read-only checks may run immediately after the wizard starts.
- T1: local profile/workspace setup may run after user choice.
- T2: software installs and external setup require a separate install/setup gate.
- T3: cloud, runtime, provider, billing, production, public release, and publication actions require a separate owner gate.

## Release boundary

Release/distribution readiness is not release execution. This repository can prepare a clear public/test package, but the following actions are blocked until a separate owner release gate:

- git tag creation or push;
- GitHub release creation;
- package registry publication;
- public website or landing page publication;
- distribution broadcast to Telegram/Slack/email/other channels;
- provider/model/runtime changes;
- gateway pairing or home-channel changes;
- Cloudflare, Hetzner, or n8n mutation;
- secret collection, readback, or storage.

## Language model

- Canonical repository documentation: English.
- Canonical source contracts and validators: English.
- User interaction: detect and mirror the user's language.
- Localized triggers/examples may use the user's language when labeled.

## Validation

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
python scripts/validate_behavior_contract.py
python scripts/validate_full_system_bootstrap.py
python scripts/validate_link_bootstrap.py
python scripts/validate_language_policy.py
python scripts/validate_archive_policy.py
python scripts/validate_profile_recipe.py
python scripts/validate_inventory_contract.py
python scripts/validate_starter_capability_pack.py
python scripts/validate_messaging_contract.py
python scripts/validate_saas_operator_kit.py
python scripts/validate_first_slice_planning.py
python scripts/validate_local_pilot_execution.py
python scripts/validate_project_plan_integrity_audit.py
python scripts/validate_agent_execution_readiness.py
python scripts/validate_workspace_hygiene.py
python scripts/validate_skill_capture.py
python scripts/validate_skillpack_registry.py
python scripts/validate_execution_evidence_binder.py
python scripts/validate_profile_distribution.py
python scripts/validate_profile_setup_tool.py
python scripts/validate_pilot_seed.py
python -m py_compile scripts/*.py
```

## Test profile helper

Windows helper:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/reset_launchroom_test_profile.ps1 -ResetExisting
```

The helper targets the isolated `launchroom-zero` profile by default and does not reset the user's main/default/AIRMIDA profile.
