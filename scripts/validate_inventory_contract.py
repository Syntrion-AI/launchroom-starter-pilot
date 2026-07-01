#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    recipe = json.loads((ROOT/'source/recipes/inventory.json').read_text(encoding='utf-8'))
    required = ['os','shell','hermes','python','git','node','npm','docker','ripgrep','uv','winget_or_package_manager']
    checks = recipe.get('required_checks', [])
    missing = [item for item in required if item not in checks]
    if missing:
        print('FAIL: missing inventory checks: ' + ', '.join(missing))
        return 1
    if 'wsl' not in recipe.get('optional_checks', []):
        print('FAIL: WSL must be optional')
        return 1
    rules_text = recipe.get('rule', '') + '\n' + '\n'.join(recipe.get('rules', []))
    if 'must not block Starter' not in rules_text:
        print('FAIL: WSL optional rule missing')
        return 1
    if 'stage_3_contract' not in recipe:
        print('FAIL: Stage 3 contract pointer missing')
        return 1
    if not (ROOT / recipe['stage_3_contract']).exists():
        print('FAIL: Stage 3 contract file missing')
        return 1
    for key in ['software_purpose_map','software_install_recommendation','do_not_run_without_gate']:
        if key not in recipe.get('output', []):
            print('FAIL: missing Stage 3 inventory output: ' + key)
            return 1
    tiers = recipe.get('readiness_tiers', {})
    for tier, names in {'required':['hermes','python','git'], 'recommended':['node','npm','ripgrep','uv','winget_or_package_manager'], 'optional':['docker','wsl']}.items():
        missing_tier = [name for name in names if name not in tiers.get(tier, [])]
        if missing_tier:
            print(f'FAIL: readiness tier {tier} missing: ' + ', '.join(missing_tier))
            return 1
    for field in ['tool','tier','status','purpose','agent_use','install_hint']:
        if field not in recipe.get('purpose_map_required_fields', []):
            print('FAIL: purpose map required field missing: ' + field)
            return 1
    if 'never installs software without a separate explicit owner install gate' not in rules_text:
        print('FAIL: explicit no-install-without-gate rule missing')
        return 1
    if 'purpose and agent_use' not in rules_text:
        print('FAIL: purpose/agent_use map rule missing')
        return 1
    print('validate_inventory_contract: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
