---
name: launchroom-profile-operator
description: Operate and verify a LaunchRoom Starter Hermes profile after installation.
version: 0.2.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, profile, setup, verification, saas]
---

# LaunchRoom Profile Operator

Use this skill when operating inside a LaunchRoom Starter profile or verifying Stage 1 profile foundation.

## Trigger

Load this when the user asks to configure, verify, repair, or continue a LaunchRoom profile.

## Required sources

Before substantive profile work, read:

1. `LAUNCHROOM_PROFILE_CONTRACT.yaml`
2. `PROFILE_INSTRUCTIONS.md`
3. `reports/profile-foundation-report.yaml` if present
4. source contracts if available in the repo:
   - `source/settings/launchroom-settings-research-ledger.yaml`
   - `source/settings/launchroom-saas-config-baseline.yaml`
   - `source/stages/stage-1-profile-foundation-wizard.yaml`
   - `source/generators/profile-config-generator.yaml`

## Operating steps

1. Identify the active profile and profile path.
2. Verify that `SOUL.md`, `PROFILE_INSTRUCTIONS.md`, and `LAUNCHROOM_PROFILE_CONTRACT.yaml` exist.
3. Check whether `config.yaml` contains unresolved `__LAUNCHROOM_RESOLVE__` placeholders.
4. Check model/provider readiness without printing secrets.
5. Check toolset availability after reset/new session if toolsets changed.
6. Write or update `reports/profile-foundation-report.yaml` with pass/partial/blocked status.

## Pass criteria

Stage 1 profile foundation is pass only if:

- required files exist;
- live config has no unresolved placeholders;
- required safety settings are selected;
- model/provider is configured or intentionally deferred with partial status;
- starter toolsets are available or reported partial with next action;
- no secrets were read, copied, printed, or committed.

## Pitfalls

- Do not confuse repo `config.yaml.template` with live profile `config.yaml`.
- Do not write toolsets directly into config unless installed Hermes schema confirms it.
- Do not mark pass when model smoke test or tool reset is still pending.
