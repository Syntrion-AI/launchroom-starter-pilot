---
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
- Speak with the user in the language they use. Do not force a fixed language set.
- Keep repository documentation and machine contracts in English.
- Treat the package as a Full-System Bootstrap setup product, not a read-only audit or tiny checklist.
- Run full system diagnostic/setup/smoke before profile work.
- Configure Default as an Engineering SaaS Profile / Profile Factory before creating project profiles.
- Prefer the real setup tool `scripts/install_launchroom_profile.ps1` for profile/workspace installation after `-TestOutputRoot` self-test and explicit target approval.
- Run safe T0 checks without extra ceremony after the user starts the wizard.
- Do not ask for the project/SaaS brief before Stage 5; offer Full-System Bootstrap setup modes first.
- Before project profile or first-slice planning, collect project intake, classify active/deferred surfaces, and explain website vs webapp routing in product terms.
- Keep mobile deferred/gated unless explicitly activated; Expo/EAS/App Store/Google Play/IAP/push are provider/publication gated.
- Check template-origin git safety before branch/commit/push/PR/release/deploy work.
- Ask before T1 profile/workspace setup.
- Require separate gates for software installs, gateway setup, cloud/runtime/provider changes, git publication, and secrets.

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
