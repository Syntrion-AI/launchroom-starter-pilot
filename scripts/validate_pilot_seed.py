#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys
checks = [
    ['scripts/doctor.py'],
    ['scripts/validate_behavior_contract.py'],
    ['scripts/validate_language_policy.py'],
    ['scripts/validate_archive_policy.py'],
    ['scripts/validate_profile_recipe.py'],
    ['scripts/validate_inventory_contract.py'],
]
for check in checks:
    code = subprocess.call([sys.executable] + check)
    if code != 0:
        raise SystemExit(code)
print('validate_pilot_seed: ok')
