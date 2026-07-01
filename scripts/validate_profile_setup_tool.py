#!/usr/bin/env python3
from __future__ import annotations
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts' / 'install_launchroom_profile.ps1'
DIST = ROOT / 'profile-distribution' / 'launchroom-saas'

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
        ('profile-distribution/launchroom-saas','uses profile distribution package'),
        ('LaunchRoom SaaS profile-distribution package','script purpose'),
        ('config','uses hermes config'),
        ('terminal.cwd','sets terminal cwd'),
        ('approvals.mode','sets approvals mode'),
        ('security.redact_secrets','sets secret redaction'),
        ('security.tirith_enabled','sets tirith safety'),
        ('checkpoints.enabled','sets checkpoints'),
        ('memory.memory_enabled','sets memory'),
        ('PROFILE_INSTRUCTIONS.md','writes profile instructions'),
        ('LAUNCHROOM_PROFILE_CONTRACT.yaml','writes profile contract'),
        ('reports/profile-foundation-report.yaml','writes foundation report'),
        ('reports/stage-1-selected-settings.yaml','writes selected settings report'),
        ('reports/config.yaml.draft','writes config draft report'),
        ('.env.EXAMPLE','writes env example only'),
        ('skills/launchroom','installs bundled skills'),
        ('software-inventory-report.yaml','writes inventory report'),
        ('Never copies .env, auth.json, state.db','secret boundary'),
        ('live_config_has_launchroom_placeholders','checks live placeholders'),
        ('hermes tools enable','enables toolsets where supported'),
    ]:
        require(text, needle, label)
    required_files = [
        'profile-distribution/launchroom-saas/distribution.yaml',
        'profile-distribution/launchroom-saas/config.yaml.template',
        'profile-distribution/launchroom-saas/SOUL.md',
        'profile-distribution/launchroom-saas/PROFILE_INSTRUCTIONS.md',
        'profile-distribution/launchroom-saas/LAUNCHROOM_PROFILE_CONTRACT.yaml',
        'profile-distribution/launchroom-saas/.env.EXAMPLE',
        'profile-distribution/launchroom-saas/skills/launchroom-profile-operator/SKILL.md',
        'profile-distribution/launchroom-saas/skills/launchroom-hermes-settings-guide/SKILL.md',
        'profile-distribution/launchroom-saas/skills/launchroom-saas-operator/SKILL.md',
        'source/stages/output/stage-1-selected-settings.example.yaml',
    ]
    missing = [p for p in required_files if not (ROOT / p).exists()]
    if missing:
        print('FAIL: missing setup distribution files: ' + ', '.join(missing))
        return 1
    if not DIST.exists():
        print('FAIL: distribution root missing')
        return 1
    print('validate_profile_setup_tool: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
