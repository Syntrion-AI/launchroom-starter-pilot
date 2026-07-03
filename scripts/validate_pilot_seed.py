#!/usr/bin/env python3
from __future__ import annotations
import subprocess, sys
checks = [
    ['scripts/doctor.py'],
    ['scripts/validate_behavior_contract.py'],
    ['scripts/validate_link_bootstrap.py'],
    ['scripts/validate_language_policy.py'],
    ['scripts/validate_archive_policy.py'],
    ['scripts/validate_profile_recipe.py'],
    ['scripts/validate_inventory_contract.py'],
    ['scripts/validate_starter_capability_pack.py'],
    ['scripts/validate_messaging_contract.py'],
    ['scripts/validate_saas_operator_kit.py'],
    ['scripts/validate_first_slice_planning.py'],
    ['scripts/validate_local_pilot_execution.py'],
    ['scripts/validate_project_plan_integrity_audit.py'],
    ['scripts/validate_agent_execution_readiness.py'],
    ['scripts/validate_workspace_hygiene.py'],
    ['scripts/validate_skill_capture.py'],
    ['scripts/validate_execution_evidence_binder.py'],
    ['scripts/validate_profile_distribution.py'],
    ['scripts/validate_profile_setup_tool.py'],
]
for check in checks:
    code = subprocess.call([sys.executable] + check)
    if code != 0:
        raise SystemExit(code)
print('validate_pilot_seed: ok')
