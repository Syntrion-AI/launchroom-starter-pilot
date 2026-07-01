# LaunchRoom Starter Pilot

LaunchRoom Starter is a public test package that turns a new or default Hermes profile into a safe local SaaS project operator room.

It is not AIRMIDA authority. It is a productization pilot for onboarding, profile setup, workspace setup, software inventory, starter capability readiness, communication setup paths, and a local SaaS operator kit.

## Start here

Use the canonical English entrypoint:

```text
https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST.md
```

Paste that link into a fresh Hermes session. The agent should use your language for conversation while keeping project documentation and machine contracts in English.

## What this package should do

- Verify the Hermes execution surface.
- Explain and configure the active profile using non-secret settings after your choice.
- Help choose/create a safe project workspace.
- Inventory local software and recommend a required/recommended/optional package.
- Inspect tools, skills, and memory readiness.
- Offer a starter capability pack.
- Prepare a communication channel path without secrets in chat.
- Create a local SaaS operator kit after Stage 6 confirmation.

## Permission model

LaunchRoom grants bounded local setup permissions instead of only listing restrictions:

- T0: read-only checks may run immediately after the wizard starts.
- T1: local profile/workspace setup may run after user choice.
- T2: software installs and external setup require a separate install/setup gate.
- T3: cloud, runtime, provider, billing, production, public release, and publication actions require a separate owner gate.

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
python scripts/validate_language_policy.py
python scripts/validate_archive_policy.py
python scripts/validate_profile_recipe.py
python scripts/validate_inventory_contract.py
python scripts/validate_pilot_seed.py
python -m py_compile scripts/*.py
```

## Test profile helper

Windows helper:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/reset_launchroom_test_profile.ps1 -ResetExisting
```

The helper targets the isolated `launchroom-zero` profile by default and does not reset the user's main/default/AIRMIDA profile.
