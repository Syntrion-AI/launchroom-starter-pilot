#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'source' / 'launchroom.starter.v0_5.json'

def load_source() -> dict:
    return json.loads(SOURCE.read_text(encoding='utf-8'))

def render_runbook(source: dict) -> str:
    stages = []
    for stage in source['stages']:
        stages.append(f"### {stage['id']} - {stage['name']}\n\nPurpose: {stage['purpose']}\n\nPass requires:\n" + ''.join(f"- {item}\n" for item in stage['pass_requires']))
    return """# LaunchRoom Starter - Run Me First

> Public LaunchRoom test package / not AIRMIDA authority.

Use this file as the executable setup route for a new or default Hermes profile. It is a guided setup wizard, not a passive article. The agent should run the staged setup below, explain each stage in the user's language, and ask for choices before any profile or workspace mutation.

## Primary setup tool

The primary setup path is the real profile installer, not a manual stage walkthrough:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\LaunchRoom\launchroom" -UserLanguage auto -Yes
```

When the repository is used through a raw GitHub link, ask the user to clone or download the repository before running the script. If the script cannot be run, the agent may perform the equivalent steps manually, but Stage 1/2/4 must not be marked `pass` until the same artifacts exist or are explicitly deferred:

- profile `SOUL.md`;
- non-secret Hermes config values including `terminal.cwd`, `approvals.mode`, secret redaction, and memory settings;
- workspace `README.md`, `AGENTS.md`, and `HERMES.md`;
- workspace `.hermes/reports/profile-setup-report.yaml`;
- workspace `.hermes/reports/software-inventory-report.yaml`;
- local LaunchRoom starter skills in the target profile.

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
version: 0.5.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [launchroom, hermes, onboarding, profile, workspace, saas, setup]
---

# AIRMIDA LaunchRoom Starter

Use this skill when the user asks to set up, test, rebuild, or run LaunchRoom Starter for a Hermes profile or SaaS project workspace.

## Core behavior

- Use `RUN_ME_FIRST.md` as the canonical executable route.
- Speak with the user in the language they use. Do not force a fixed language set.
- Keep repository documentation and machine contracts in English.
- Treat the package as a guided setup wizard, not a read-only audit.
- Prefer the real setup tool `scripts/install_launchroom_profile.ps1` for profile/workspace installation.
- Run safe T0 checks without extra ceremony after the user starts the wizard.
- Ask before T1 profile/workspace setup.
- Require separate gates for software installs, gateway setup, cloud/runtime/provider changes, git publication, and secrets.

## Positive setup permissions

After the user chooses the relevant option, the agent may:

- create the selected local workspace;
- set non-secret Hermes config values for the active test/project profile;
- set `terminal.cwd` to the selected workspace;
- write profile `SOUL.md` instructions;
- write workspace `AGENTS.md` and `HERMES.md` instructions;
- install local LaunchRoom starter skills into the target profile;
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

- Use `RUN_ME_FIRST.md` as the route.
- Speak in the user's language.
- Keep canonical repository documentation and contracts in English.
- Perform T0 safe checks after the wizard starts.
- Ask before T1 profile/workspace setup.
- Recommend installs but do not install without a separate gate.
- Do not mutate cloud/runtime/provider/publication surfaces without a separate owner gate.
- Use `scripts/install_launchroom_profile.ps1` or manually create equivalent artifacts before claiming profile setup pass.
- Build a real setup outcome: profile SOUL, workspace instructions, terminal.cwd, software inventory, capability pack, communication path, and Stage 6 local SaaS operator kit.
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
