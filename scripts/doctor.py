#!/usr/bin/env python3
from __future__ import annotations
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CYRILLIC_RE = re.compile(r'[\u0400-\u04FF]')
REQUIRED = [
    'README.md','RUN_ME_FIRST.md','SKILL.md','START_HERE.md','INSTALL.md','SECURITY.md','UNDER_THE_HOOD.md','PUBLICATION_GATE.md','DEFAULT_PROFILE_TEST.md',
    'source/launchroom.starter.v0_5.json','source/locales/examples.ru.json',
    'source/recipes/profile-setup.json','source/recipes/workspace-setup.json','source/recipes/inventory.json','source/recipes/starter-skillpack.json','source/recipes/messaging.json','source/recipes/saas-operator-kit.json',
    'contracts/launchroom-language-policy.json','contracts/launchroom-permission-tiers.json','contracts/launchroom-stage-contract.json','contracts/launchroom-profile-recipe.json','contracts/launchroom-workspace-recipe.json','contracts/launchroom-inventory-contract.json','contracts/launchroom-archive-policy.json',
    'scripts/build_agentpack.py','scripts/doctor.py','scripts/validate_behavior_contract.py','scripts/validate_language_policy.py','scripts/validate_archive_policy.py','scripts/validate_profile_recipe.py','scripts/validate_inventory_contract.py','scripts/validate_profile_setup_tool.py','scripts/reset_launchroom_test_profile.ps1','scripts/install_launchroom_profile.ps1',
    'templates/profile/SOUL.md','templates/workspace/README.md','templates/workspace/AGENTS.md','templates/workspace/HERMES.md','templates/reports/launchroom-readiness-report.yaml','templates/starter-skills/launchroom-profile-operator/SKILL.md','templates/starter-skills/launchroom-saas-operator/SKILL.md',
    'generated/RUN_ME_FIRST.md','generated/HERMES_SKILL.md','generated/github-agents/airmida-launchroom.agent.md',
    'archive/20260630-rebuild-v0_5/ARCHIVE_MANIFEST.json'
]
CANONICAL_SCAN_EXTS = {'.md','.py','.ps1','.json','.yaml','.yml'}
ALLOWED_LOCALIZED_PREFIXES = ('archive/','source/locales/','generated/locale-examples/')
SECRET_PATTERNS = [
    re.compile(r'sk-[A-Za-z0-9]{20,}'),
    re.compile(r'xox[baprs]-[A-Za-z0-9-]{20,}'),
    re.compile(r'xapp-[A-Za-z0-9-]{20,}'),
    re.compile(r'ghp_[A-Za-z0-9]{20,}'),
    re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
]

def fail(msg: str) -> None:
    print(f'FAIL: {msg}')
    raise SystemExit(1)

def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()

def main() -> int:
    missing = [p for p in REQUIRED if not (ROOT/p).exists()]
    if missing:
        fail('missing required files: ' + ', '.join(missing))
    source = json.loads((ROOT/'source/launchroom.starter.v0_5.json').read_text(encoding='utf-8'))
    if source.get('canonical_documentation_language') != 'English':
        fail('canonical documentation language must be English')
    if source.get('interaction_language', {}).get('closed_language_allowlist') is not False:
        fail('interaction language must not use a closed allowlist')
    for tier in ['T0_read_only','T1_user_choice_setup','T2_install_or_external_setup','T3_runtime_provider_cloud']:
        if tier not in source.get('permission_tiers', {}):
            fail(f'missing permission tier {tier}')
    for recipe in source.get('recipes', []):
        if not (ROOT/recipe).exists():
            fail(f'missing recipe {recipe}')
    forbidden_roots = ['FULL_SETUP_TEST_RU.md','INSTALL_RU.md','REAL_HERMES_SETUP_RU.md','START_HERE_RU.md']
    for item in forbidden_roots:
        if (ROOT/item).exists():
            fail(f'superseded localized root file still active: {item}')
    for path in ROOT.rglob('*'):
        if not path.is_file() or '.git' in path.parts or path.suffix not in CANONICAL_SCAN_EXTS:
            continue
        r = rel(path)
        text = path.read_text(encoding='utf-8', errors='ignore')
        if any(pattern.search(text) for pattern in SECRET_PATTERNS):
            fail(f'secret-like marker in {r}')
        if CYRILLIC_RE.search(text) and not r.startswith(ALLOWED_LOCALIZED_PREFIXES):
            fail(f'localized text found outside allowed locale/archive path: {r}')
    print('doctor: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
