#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def main() -> int:
    recipe = json.loads((ROOT/'source/recipes/profile-setup.json').read_text(encoding='utf-8'))
    required = [
        'profile-distribution/launchroom-saas package presence',
        'run non-mutating installer self-test with -TestOutputRoot',
        'generate simulated profile/workspace tree under -TestOutputRoot without calling hermes profile/config/tools',
        'set source-backed non-secret Stage 1 Hermes config values',
        'set terminal.cwd to the selected workspace',
        'write profile SOUL.md from profile-distribution/launchroom-saas',
        'write PROFILE_INSTRUCTIONS.md and LAUNCHROOM_PROFILE_CONTRACT.yaml',
        'write .env.EXAMPLE with variable names only',
        'write reports/profile-foundation-report.yaml',
        'write reports/stage-1-selected-settings.yaml',
        'write reports/config.yaml.draft without applying unresolved placeholders live',
        'install bundled LaunchRoom starter skills into the target profile',
        'write no-secret software inventory report',
        'live config.yaml contains no __LAUNCHROOM_RESOLVE__ placeholders',
        'installer self-test creates simulated profile files under TestOutputRoot',
    ]
    text = json.dumps(recipe)
    for item in required:
        if item not in text:
            print(f'FAIL: profile recipe missing {item}')
            return 1
    forbidden_required = [
        'copy credential files',
        'print secret values',
        'write unresolved __LAUNCHROOM_RESOLVE__ placeholders into live config.yaml',
        'patch unrelated skills',
        'mutate provider/cloud/runtime/gateway credentials',
        'self-test mode must not call hermes profile create, hermes config set, or hermes tools enable',
    ]
    for item in forbidden_required:
        if item not in text:
            print(f'FAIL: profile recipe missing hard forbidden action {item}')
            return 1
    contract = json.loads((ROOT/'contracts/launchroom-profile-recipe.json').read_text(encoding='utf-8'))
    if recipe != contract:
        print('FAIL: source/recipes/profile-setup.json drifted from contracts/launchroom-profile-recipe.json')
        return 1
    print('validate_profile_recipe: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
