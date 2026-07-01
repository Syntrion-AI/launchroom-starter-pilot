# Installation and Test Guide

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
python scripts/validate_pilot_seed.py
python -m py_compile scripts/*.py
```
