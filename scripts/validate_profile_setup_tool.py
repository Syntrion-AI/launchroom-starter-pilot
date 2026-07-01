#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts' / 'install_launchroom_profile.ps1'

def require(text: str, needle: str, label: str) -> None:
    if needle.lower() not in text.lower():
        print(f'FAIL: missing {label}: {needle}')
        raise SystemExit(1)

def main() -> int:
    if not SCRIPT.exists():
        print('FAIL: scripts/install_launchroom_profile.ps1 missing')
        return 1
    text = SCRIPT.read_text(encoding='utf-8')
    for needle, label in [
        ('config','uses hermes config'),
        ('terminal.cwd','sets terminal cwd'),
        ('approvals.mode','sets approvals mode'),
        ('security.redact_secrets','sets secret redaction'),
        ('memory.memory_enabled','sets memory'),
        ('SOUL.md','writes profile SOUL'),
        ('workspace/AGENTS.md','uses workspace AGENTS template'),
        ('workspace/HERMES.md','uses workspace HERMES template'),
        ('starter-skills','installs starter skills'),
        ('software-inventory-report.yaml','writes inventory report'),
        ('Never copies .env, auth.json, state.db','secret boundary'),
    ]:
        require(text, needle, label)
    required_files = [
        'templates/profile/SOUL.md',
        'templates/workspace/AGENTS.md',
        'templates/workspace/HERMES.md',
        'templates/starter-skills/launchroom-profile-operator/SKILL.md',
        'templates/starter-skills/launchroom-saas-operator/SKILL.md',
    ]
    missing = [p for p in required_files if not (ROOT / p).exists()]
    if missing:
        print('FAIL: missing setup templates: ' + ', '.join(missing))
        return 1
    print('validate_profile_setup_tool: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
