# Installation and Test Guide

## Real profile setup tool

After cloning or downloading this repository on Windows, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom -WorkspacePath "$env:USERPROFILE\LaunchRoom\launchroom" -UserLanguage auto -Yes
```

Use `-ShowPlanOnly` first if you want to preview the exact non-secret changes.

For a real file-generation self-test that does not create a Hermes profile and
does not mutate user config/toolsets, run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/install_launchroom_profile.ps1 -ProfileName launchroom-selftest -TestOutputRoot "$env:TEMP\launchroom-selftest" -Yes -NoInventory -NoToolsets
```

`-TestOutputRoot` must write only under the supplied test directory and must not
call `hermes profile create`, `hermes config set`, or `hermes tools enable`.

The installer now uses the full LaunchRoom SaaS profile distribution package:

```text
profile-distribution/launchroom-saas/
```

It writes profile `SOUL.md`, `PROFILE_INSTRUCTIONS.md`,
`LAUNCHROOM_PROFILE_CONTRACT.yaml`, `.env.EXAMPLE`, bundled starter skills,
profile reports, and source-backed non-secret Stage 1 config values. It must
not copy `.env`, `auth.json`, `state.db`, OAuth/session stores, memories, logs,
or raw MCP credential values.

## Clean test profile

On Windows, create or reset the isolated LaunchRoom profile:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/reset_launchroom_test_profile.ps1 -ResetExisting
```

Then start Hermes with that profile:

```powershell
hermes -p launchroom-zero
```

Paste the canonical raw entrypoint:

```text
https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST.md
```

## Local validation

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
python scripts/validate_behavior_contract.py
python scripts/validate_language_policy.py
python scripts/validate_archive_policy.py
python scripts/validate_profile_recipe.py
python scripts/validate_inventory_contract.py
python scripts/validate_profile_distribution.py
python scripts/validate_pilot_seed.py
python -m py_compile scripts/*.py
```
