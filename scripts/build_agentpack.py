#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'source' / 'launchroom.starter.v0_5.json'

def load_source() -> dict:
    return json.loads(SOURCE.read_text(encoding='utf-8'))

def render_wizard_rooms(source: dict) -> str:
    contract = source.get('wizard_rooms_contract', {})
    rooms = contract.get('rooms', [])
    if not rooms:
        return ''
    lines = [
        '## Beginner Wizard Rooms',
        '',
        'These rooms are a user-facing navigation layer over the machine stages. They do not replace or collapse the stage contracts; validators still check each stage separately.',
        '',
    ]
    for index, room in enumerate(rooms, start=1):
        stages = ', '.join(room.get('stages', []))
        lines.extend([
            f"### Room {index}: {room.get('name', '')}",
            '',
            f"Stages: {stages}",
            '',
            f"User goal: {room.get('user_goal', '')}",
            '',
            f"Plain-language result: {room.get('plain_language_result', '')}",
            '',
            f"Next decision: {room.get('next_decision', '')}",
            '',
        ])
    lines.append('Room transitions should use the Hermes `clarify` tool with `choices` when available; plain text choices are fallback only.')
    return '\n'.join(lines)

def render_wizard_room_transitions(source: dict) -> str:
    contract = source.get('wizard_room_transition_contract', {})
    if not contract.get('enabled'):
        return ''
    actions = ', '.join(contract.get('required_transition_actions', []))
    lines = [
        '## Wizard Room Transition UX',
        '',
        'This is a room-level interaction layer over the Beginner Wizard Rooms. It is not Stage 14, does not replace machine stages, and does not authorize implementation, runtime, provider, gateway, n8n, git publication, or secret handling by itself.',
        '',
        f"Required transition actions: {actions}",
        '',
        '### Clarify prompt contract',
        '',
        'Room transition prompts must use the Hermes `clarify` tool with a non-empty `choices` array when available. The question text contains only the question; selectable options live only in `choices`. Plain A/B/C or numbered text is fallback only when `clarify` or native buttons are unavailable. Timeout or silence is not approval.',
        '',
        '### Prompt templates',
        '',
    ]
    for template_id, template in contract.get('prompt_templates', {}).items():
        choices = ', '.join(template.get('choices', []))
        lines.extend([
            f"#### {template_id}",
            '',
            f"Purpose: {template.get('question_purpose', '')}",
            '',
            f"Choices: {choices}",
            '',
        ])
    lines.extend([
        '### Room transition map',
        '',
    ])
    for item in contract.get('room_transitions', []):
        next_room = item.get('next_room_id') or 'final closeout / next gated decision'
        lines.extend([
            f"- {item.get('room_name', '')}: entry `{item.get('entry_prompt_template')}`, completion `{item.get('completion_prompt_template')}`, blocked `{item.get('blocked_prompt_template')}`, next `{next_room}`",
        ])
    return '\n'.join(lines)

def render_first_run_demo(source: dict) -> str:
    contract = source.get('first_run_demo_contract', {})
    if not contract.get('enabled'):
        return ''
    lines = [
        '## First-run Demo / Self-test Scenario',
        '',
        'This scenario demonstrates LaunchRoom Starter as a beginner-safe onboarding wizard. It uses self-test mode only, is not a new stage, and must stop before installs, gateway pairing, provider/runtime changes, cloud/n8n mutation, git publication, secret handling, or implementation execution.',
        '',
        '### Self-test command',
        '',
        '```powershell',
        contract.get('self_test_command', ''),
        '```',
        '',
        '### Demo path',
        '',
    ]
    for step in contract.get('demo_path', []):
        evidence = '; '.join(step.get('expected_evidence', []))
        room = step.get('room_id') or 'repo/self-test'
        lines.extend([
            f"#### {step.get('step_id', '')}",
            '',
            f"Room/context: {room}",
            '',
            f"Action: {step.get('action', '')}",
            '',
            f"User-visible text: {step.get('user_visible_text', '')}",
            '',
            f"Expected evidence: {evidence}",
            '',
        ])
    lines.extend([
        '### Expected self-test outputs',
        '',
    ])
    for output in contract.get('expected_self_test_outputs', []):
        lines.append(f"- {output}")
    lines.extend([
        '',
        '### What the user should see',
        '',
    ])
    for item in contract.get('user_visible_checklist', []):
        lines.append(f"- {item}")
    lines.extend([
        '',
        '### Stop before gated actions',
        '',
    ])
    for action in contract.get('stop_before_gated_actions', []):
        lines.append(f"- {action}")
    return '\n'.join(lines)


def render_full_system_bootstrap(source: dict) -> str:
    contract = source.get('full_system_bootstrap_contract', {})
    if not contract.get('enabled'):
        return ''
    return """## Full-System Bootstrap v0.7

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
"""

def render_link_bootstrap(source: dict) -> str:
    contract = source.get('link_bootstrap_contract', {})
    if not contract.get('enabled'):
        return ''
    modes = contract.get('setup_modes', [])
    labels = {
        'self_test_only': 'self-test only',
        'engineering_saas_profile_foundation': 'Engineering SaaS Profile foundation',
        'existing_hermes_profile_repair': 'existing Hermes profile repair',
        'advanced_custom': 'advanced/custom',
    }
    mode_lines = '\n'.join(f"- {labels.get(mode, mode.replace('_', ' '))}" for mode in modes)
    return f"""## Link-to-Operator Bootstrap

If a Hermes agent receives only a GitHub repository or release link, treat this package as a setup package, not a passive article. Prefer the release tag over mutable `main` for installation or acceptance testing. Read `BOOTSTRAP_WITH_HERMES.md`, then this runbook, before scanning the rest of the repository.

First explain the safe boundary in the user's language: local self-test and local profile/workspace setup are separate from runtime, provider, cloud, n8n, gateway, git publication, release, and secret handling.

Do not ask the first project/SaaS brief before Stage 5. Before real setup, offer Full-System Bootstrap setup modes with `clarify` choices when available:

{mode_lines}

Run the `-TestOutputRoot` self-test before any real setup. Do not ask for secret values in chat, do not copy credential files, and do not mutate runtime/provider/cloud/n8n/gateway surfaces unless a separate gate is granted.

Required safe order:

```text
link -> bootstrap -> RUN_ME_FIRST -> explain full diagnostic -> full-system self-test -> explicit setup gate -> allowed local setup/repair -> smoke tests -> Default Engineering SaaS Profile -> project profile -> PASS/PARTIAL/BLOCKED summary
```
"""

def render_fresh_agent_first_reply(source: dict) -> str:
    contract = source.get('fresh_agent_first_reply_contract', {})
    if not contract.get('enabled'):
        return ''
    lines = [
        '## Fresh Agent First Reply Contract',
        '',
        'This contract applies when a fresh or separate agent is asked what to do first with LaunchRoom. It prevents ambient profile memory or unrelated domain context from replacing the LaunchRoom onboarding path.',
        '',
        '### First answer must include',
        '',
    ]
    for item in contract.get('first_answer_must_include', []):
        lines.append(f'- {item}')
    lines.extend([
        '',
        '### First answer must not start with',
        '',
    ])
    for item in contract.get('first_answer_must_not_start_with', []):
        lines.append(f'- {item}')
    lines.extend([
        '',
        '### Plain-language sequence',
        '',
    ])
    for index, item in enumerate(contract.get('plain_language_sequence', []), start=1):
        lines.append(f'{index}. {item}')
    lines.extend([
        '',
        '### Fresh-agent acceptance markers',
        '',
    ])
    for marker in contract.get('fresh_agent_acceptance_markers', []):
        lines.append(f'- {marker}')
    lines.extend([
        '',
        '### Behavior failure markers',
        '',
    ])
    for marker in contract.get('behavior_failure_markers', []):
        lines.append(f'- {marker}')
    return '\n'.join(lines)

def render_project_intake_and_template_safety(source: dict) -> str:
    intake = source.get('project_intake_contract', {})
    surfaces = source.get('active_deferred_surfaces_contract', {})
    git_safety = source.get('template_origin_safety_contract', {})
    acceptance = source.get('acceptance_contract', {})
    isolation = source.get('local_pilot_isolation_contract', {})
    if not any(section.get('enabled') for section in [intake, surfaces, git_safety, acceptance, isolation]):
        return ''

    lines = [
        '## Project Intake, Surface Routing, and Template Safety',
        '',
        'This v0.7.2 layer strengthens the handoff from profile setup into a real project. It is inspired by external starter-template patterns, but LaunchRoom remains the authority for gates and safety. These rules do not authorize implementation, publication, deployment, provider/runtime changes, or secret handling.',
        '',
    ]
    if intake.get('enabled'):
        lines.extend([
            '### Project intake contract',
            '',
            'Collect project intake only after the Profile Factory foundation is ready or explicitly deferred. Do not ask project/product questions before the LaunchRoom setup stages allow it.',
            '',
            'Required intake fields:',
            '',
        ])
        for field in intake.get('required_fields', []):
            lines.append(f'- `{field}`')
        lines.extend([
            '',
            f"Plain-language rule: {intake.get('plain_language_rule', '')}",
            '',
        ])
    if surfaces.get('enabled'):
        lines.extend([
            '### Active/deferred surface routing',
            '',
            'Before project-profile or first-slice work, classify each product surface as active now, deferred, gated later, not applicable, or unknown requiring a choice.',
            '',
            'Required surfaces:',
            '',
        ])
        for surface in surfaces.get('required_surfaces', []):
            lines.append(f'- `{surface}`')
        routing = surfaces.get('browser_routing_rule', {})
        mobile = surfaces.get('mobile_policy', {})
        lines.extend([
            '',
            f"Website/public SEO rule: {routing.get('website_public_seo', '')}",
            '',
            f"Webapp/authenticated CSR rule: {routing.get('webapp_authenticated_csr', '')}",
            '',
            'Do not build SEO pages inside the authenticated webapp by habit, and do not move the full authenticated app into the website by habit.',
            '',
            f"Mobile policy: mobile is `{mobile.get('default_status', 'deferred')}` by default and activates only after an explicit mobile choice; Expo/EAS/App Store/Google Play/IAP/push remain provider/publication gated.",
            '',
        ])
    if git_safety.get('enabled'):
        modes = ', '.join(git_safety.get('classify_git_work_mode_before_publication', []))
        lines.extend([
            '### Template-origin and git publication safety',
            '',
            'Before branch, commit, push, PR, release, or deploy work, inspect `git remote -v` and classify the git work mode.',
            '',
            f'Git work modes: {modes}',
            '',
            f"If origin points to the starter/template and this is a new user project: {git_safety.get('if_origin_points_to_template_and_mode_is_new_project', '')}.",
            '',
            'Do not open a PR to the template repository unless the user explicitly grants a template-contribution gate. Do not push without a publication gate. Release/deploy work requires a clean, synced source.',
            '',
        ])
    if acceptance.get('enabled'):
        lines.extend([
            '### Acceptance contract',
            '',
            'Every non-trivial implementation or local pilot packet must define `primary_signal`, 3-5 `pass_criteria`, `secondary_signals`, `evidence_required`, and `cannot_claim_done_if` before execution.',
            '',
            'Cannot claim done if:',
            '',
        ])
        for item in acceptance.get('cannot_claim_done_if', []):
            lines.append(f'- {item}')
        lines.append('')
    if isolation.get('enabled'):
        lines.extend([
            '### Local pilot isolation',
            '',
            'Local pilots and data-backed tests must use test data only. If a database URL is present, test plans require a `*_test` database name or an explicit override gate, prefer repo-derived/isolated ports for parallel checkouts, and stop instead of repairing when the data target is ambiguous.',
        ])
    return '\n'.join(lines)


def render_product_boundary_and_e2e(source: dict) -> str:
    boundary = source.get('product_boundary_contract', {})
    e2e = source.get('end_to_end_acceptance_contract', {})
    if not boundary.get('enabled') and not e2e.get('enabled'):
        return ''
    lines = [
        '## Product Boundary / Definition of Done',
        '',
        'LaunchRoom Starter is a bounded product, not an infinite setup stream. It is complete when it turns a new or weak Hermes profile into a safe local SaaS/project operator and stops at a clear first execution gate.',
        '',
        f"Definition of done: {boundary.get('starter_definition_of_done', '')}",
        '',
        'No new setup stages are authorized by this section. New setup stages require a named real user-facing acceptance failure; otherwise the work belongs after v1.0 or in CloudRoom/AgentOps.',
        '',
        '### starter_in_scope',
        '',
    ]
    for item in boundary.get('starter_in_scope', []):
        lines.append(f'- {item}')
    lines.extend(['', '### starter_out_of_scope', ''])
    for item in boundary.get('starter_out_of_scope', []):
        lines.append(f'- {item}')
    lines.extend(['', '### v1_completion_gates', ''])
    for item in boundary.get('v1_completion_gates', []):
        lines.append(f'- {item}')
    lines.extend([
        '',
        '## End-to-End Acceptance Path',
        '',
        'End-to-end acceptance proves the product path from repository link to safe local operator readiness. It does not authorize release execution; release/tag remains blocked until a separate owner release gate.',
        '',
    ])
    for scenario in e2e.get('scenarios', []):
        lines.extend([
            f"### {scenario.get('id', '')}",
            '',
            f"Goal: {scenario.get('goal', '')}",
            '',
            f"Entry surface: {scenario.get('entry_surface', '')}",
            '',
            'Pass signals:',
            '',
        ])
        for signal in scenario.get('pass_signals', []):
            lines.append(f'- {signal}')
        lines.extend(['', 'Blocked if:', ''])
        for blocker in scenario.get('blocked_if', []):
            lines.append(f'- {blocker}')
        lines.extend(['', 'Forbidden actions:', ''])
        for action in scenario.get('forbidden_actions', []):
            lines.append(f'- {action}')
        lines.append('')
    lines.extend(['### Blocked until separate gate', ''])
    for action in e2e.get('blocked_until_separate_gate', []):
        lines.append(f'- {action}')
    return '\n'.join(lines)

def render_release_distribution_readiness(source: dict) -> str:
    contract = source.get('release_distribution_readiness_contract', {})
    if not contract.get('enabled'):
        return ''
    lines = [
        '## Release / Distribution Readiness',
        '',
        'This section prepares LaunchRoom Starter for a clear public/test distribution package. It is readiness only: it does not create a GitHub release, tag, package publication, deployment, provider/runtime change, gateway pairing, Cloudflare/Hetzner/n8n mutation, distribution broadcast, or secret-handling path.',
        '',
        '### Distribution quickstart',
        '',
    ]
    for step in contract.get('distribution_quickstart', []):
        lines.extend([
            f"#### {step.get('step_id', '')}",
            '',
            f"Surface: {step.get('surface', '')}",
            '',
            f"User action: {step.get('user_action', '')}",
            '',
            f"Expected result: {step.get('expected_result', '')}",
            '',
        ])
    lines.extend([
        '### Artifact manifest',
        '',
    ])
    for item in contract.get('artifact_manifest', []):
        required = 'required' if item.get('required') else 'optional'
        lines.append(f"- `{item.get('path', '')}` — {item.get('role', '')} ({required})")
    lines.extend([
        '',
        '### Release readiness checklist',
        '',
    ])
    for item in contract.get('release_readiness_checklist', []):
        lines.append(f"- {item}")
    lines.extend([
        '',
        '### Blocked until separate owner release gate',
        '',
    ])
    for action in contract.get('blocked_until_separate_release_gate', []):
        lines.append(f"- {action}")
    lines.extend([
        '',
        'Release readiness is not release execution. No tag, GitHub release, package publication, website publication, runtime/provider/gateway/cloud/n8n mutation, distribution broadcast, or secret handling is authorized by this section.',
    ])
    return '\n'.join(lines)

def render_runbook(source: dict) -> str:
    stages = []
    for stage in source['stages']:
        stages.append(f"### {stage['id']} - {stage['name']}\n\nPurpose: {stage['purpose']}\n\nPass requires:\n" + ''.join(f"- {item}\n" for item in stage['pass_requires']))
    return """# LaunchRoom Starter - Run Me First

> Public LaunchRoom test package / not AIRMIDA authority.

Use this file as the executable setup route for a new or default Hermes profile. It is a guided setup wizard, not a passive article. The agent should run the staged setup below, explain each stage in the user's language, and ask for choices before any profile or workspace mutation.

""" + render_full_system_bootstrap(source) + "\n\n" + render_link_bootstrap(source) + "\n\n" + render_fresh_agent_first_reply(source) + "\n\n" + render_project_intake_and_template_safety(source) + """

## Primary setup tool

For CI-grade non-mutating generation checks, run the installer in self-test mode:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

`-TestOutputRoot` writes a simulated profile/workspace tree only under the supplied path and must not call `hermes profile create`, `hermes config set`, or `hermes tools enable`.

The primary setup path after self-test and explicit target approval is the real profile installer, not a manual stage walkthrough:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\\LaunchRoom\\launchroom" -UserLanguage auto -Yes
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

""" + render_wizard_rooms(source) + "\n\n" + render_wizard_room_transitions(source) + "\n\n" + render_first_run_demo(source) + "\n\n" + render_product_boundary_and_e2e(source) + "\n\n" + render_release_distribution_readiness(source) + """

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

""" + '\n'.join(stages) + """

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
"""

def render_skill() -> str:
    return """---
name: airmida-launchroom-starter
description: LaunchRoom Starter setup wizard for turning a new/default Hermes profile into a safe SaaS project operator room.
version: 0.7.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [launchroom, hermes, onboarding, profile, workspace, saas, setup]
---

# AIRMIDA LaunchRoom Starter

Use this skill when the user asks to set up, test, rebuild, or run LaunchRoom Starter for a Hermes profile or SaaS project workspace.

## Core behavior

- Use `BOOTSTRAP_WITH_HERMES.md` first as the link-to-operator bootstrap when the agent receives a repository or release link.
- Use `RUN_ME_FIRST.md` as the canonical executable route after bootstrap.
- On the first answer from a fresh/separate agent, state the safe dry path, profile/workspace boundary, disposable `-TestOutputRoot` self-test, Stage 6 product intake/surface routing, Stage 7 first-slice acceptance, and Stage 8 local pilot gate before any domain-specific intake.
- Speak with the user in the language they use. Do not force a fixed language set.
- Keep repository documentation and machine contracts in English.
- Treat the package as a Full-System Bootstrap setup product, not a read-only audit or tiny checklist.
- Run full system diagnostic/setup/smoke before profile work.
- Configure Default as an Engineering SaaS Profile / Profile Factory before creating project profiles.
- Prefer the real setup tool `scripts/install_launchroom_profile.ps1` for profile/workspace installation after `-TestOutputRoot` self-test and explicit target approval.
- Run safe T0 checks without extra ceremony after the user starts the wizard.
- Do not ask for the project/SaaS brief before Stage 5; offer Full-System Bootstrap setup modes first.
- Do not start with domain-specific item intake such as equipment photos, nameplates, prices, or SKUs before the LaunchRoom boundary, self-test, and Stage 6/7/8 path are clear.
- Before project profile or first-slice planning, collect project intake, classify active/deferred surfaces, and explain website vs webapp routing in product terms.
- Keep mobile deferred/gated unless explicitly activated; Expo/EAS/App Store/Google Play/IAP/push are provider/publication gated.
- Check template-origin git safety before branch/commit/push/PR/release/deploy work.
- Ask before T1 profile/workspace setup.
- Require separate gates for software installs, gateway setup, cloud/runtime/provider changes, git publication, and secrets.

## Fresh Agent First Reply Contract

When the user asks what to do first with LaunchRoom, answer with this order before any domain-specific intake:

1. Safe dry path before live setup.
2. Profile/workspace boundary in plain language.
3. Disposable `-TestOutputRoot` self-test as the first technical proof step.
4. Stage 6 product intake and active/deferred surface routing after setup boundary.
5. Stage 7 first-slice acceptance before implementation.
6. Stage 8 local pilot gate before commands, file changes, tests, dependencies, or runtime work.
7. No live setup, toolset enablement, runtime/provider/cloud/n8n/gateway/git publication, implementation, or secrets without separate owner gate.

Do not start with domain-specific item intake such as equipment photos, nameplates, prices, or SKUs before this LaunchRoom boundary and first-run path are clear.

## Positive setup permissions

After the user chooses the relevant option, the agent may:

- create the selected local workspace;
- set source-backed non-secret Hermes config values for the active test/project profile;
- set `terminal.cwd` to the selected workspace;
- write profile `SOUL.md`, `PROFILE_INSTRUCTIONS.md`, and `LAUNCHROOM_PROFILE_CONTRACT.yaml` from `profile-distribution/launchroom-saas`;
- write `.env.EXAMPLE` with variable names only;
- write profile reports including foundation report, apply plan, selected settings, and config draft;
- write workspace `AGENTS.md` and `HERMES.md` instructions;
- install bundled LaunchRoom starter skills into the target profile;
- write workspace-local instructions and readiness reports;
- recommend and optionally load/install the approved LaunchRoom starter capability pack;
- create a local SaaS operator kit at Stage 6.

## Hard stops

Stop and report `failed_policy_violation` if the agent:

- asks for secrets in chat;
- copies credential/session files between profiles;
- patches unrelated installed skills as self-improvement during onboarding;
- claims pass with contradictory evidence;
- mutates provider/cloud/runtime/publication surfaces without a separate gate.

## Stage pass rule

A stage passes only when checks are complete or explicitly deferred, required user choices are collected or explicitly deferred, selected allowed setup actions are completed and verified, and an evidence ledger exists.
"""

def render_agent() -> str:
    return """# AIRMIDA LaunchRoom Agent

You operate the LaunchRoom Starter wizard.

- Use `BOOTSTRAP_WITH_HERMES.md` first when the user provides a repository or release link.
- Use `RUN_ME_FIRST.md` as the route after bootstrap.
- First response must explain safe dry path, profile/workspace boundary, disposable `-TestOutputRoot` self-test, Stage 6 product intake/surface routing, Stage 7 first-slice acceptance, and Stage 8 local pilot gate before domain-specific intake.
- Speak in the user's language.
- Keep canonical repository documentation and contracts in English.
- Perform T0 safe checks after the wizard starts.
- Do not ask for the project/SaaS brief before Stage 5; offer Full-System Bootstrap setup modes first.
- Do not start with equipment photos/nameplates/prices/SKUs or another domain-specific checklist before the LaunchRoom boundary and first-run path are clear.
- Ask before T1 profile/workspace setup.
- Recommend installs but do not install without a separate gate.
- Do not mutate cloud/runtime/provider/publication surfaces without a separate owner gate.
- Use `scripts/install_launchroom_profile.ps1` or manually create equivalent artifacts before claiming profile setup pass.
- Build a real setup outcome: full system diagnostic, setup plan, smoke test report, Engineering SaaS Profile default, project profile handoff, workspace instructions, terminal.cwd, software inventory, capability pack, communication path, and Stage 6 local SaaS operator kit.

## Fresh Agent First Reply Contract

When the user asks what to do first with LaunchRoom, first explain: safe dry path, profile/workspace boundary, disposable `-TestOutputRoot` self-test, Stage 6 product intake/surface routing, Stage 7 first-slice acceptance, and Stage 8 local pilot gate. Do this before equipment photos, nameplates, prices, SKUs, code, installs, live profile setup, provider/runtime/cloud/n8n/gateway/git work, or secrets.
"""

def expected_files(source: dict) -> dict[Path, str]:
    return {
        ROOT / 'RUN_ME_FIRST.md': render_runbook(source),
        ROOT / 'generated' / 'RUN_ME_FIRST.md': render_runbook(source),
        ROOT / 'SKILL.md': render_skill(),
        ROOT / 'generated' / 'HERMES_SKILL.md': render_skill(),
        ROOT / 'generated' / 'github-agents' / 'airmida-launchroom.agent.md': render_agent(),
    }

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    source = load_source()
    changed = []
    for path, content in expected_files(source).items():
        path.parent.mkdir(parents=True, exist_ok=True)
        old = path.read_text(encoding='utf-8') if path.exists() else None
        if old != content:
            if args.check:
                changed.append(str(path.relative_to(ROOT)))
            else:
                path.write_text(content, encoding='utf-8', newline='\n')
                changed.append(str(path.relative_to(ROOT)))
    if args.check and changed:
        print('Generated files are stale:')
        for item in changed:
            print(f'- {item}')
        return 1
    print('build_agentpack: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
