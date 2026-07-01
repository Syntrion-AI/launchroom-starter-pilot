#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    recipe = json.loads((ROOT/'source/recipes/profile-setup.json').read_text(encoding='utf-8'))
    required = ['set display.language to detected/user-selected language','set approvals.mode to smart','set security.redact_secrets to true','write profile SOUL.md','write workspace README.md, AGENTS.md, and HERMES.md','install local LaunchRoom starter skills into the target profile','write profile setup report','write no-secret software inventory report']
    text = json.dumps(recipe)
    for item in required:
        if item not in text:
            print(f'FAIL: profile recipe missing {item}')
            return 1
    if 'copy credential files' not in text or 'patch unrelated skills' not in text:
        print('FAIL: profile recipe missing hard forbidden actions')
        return 1
    print('validate_profile_recipe: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
