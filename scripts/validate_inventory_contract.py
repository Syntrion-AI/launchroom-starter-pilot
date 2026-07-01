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
    if 'must not block Starter' not in recipe.get('rule', ''):
        print('FAIL: WSL optional rule missing')
        return 1
    print('validate_inventory_contract: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
