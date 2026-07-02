#!/usr/bin/env python3
from __future__ import annotations
import json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]

def require(text: str, needle: str, label: str) -> None:
    if needle.lower() not in text.lower():
        print(f'FAIL: missing {label}: {needle}')
        raise SystemExit(1)

def main() -> int:
    run = (ROOT/'RUN_ME_FIRST.md').read_text(encoding='utf-8')
    skill = (ROOT/'SKILL.md').read_text(encoding='utf-8')
    source = json.loads((ROOT/'source/launchroom.starter.v0_5.json').read_text(encoding='utf-8'))
    for needle,label in [
        ('guided setup wizard','wizard behavior'),
        ('T0 - Read-only checks allowed immediately','T0 permissions'),
        ('Primary setup tool','primary setup tool section'),
        ('scripts/install_launchroom_profile.ps1','profile setup tool'),
        ('profile `SOUL.md`','profile SOUL requirement'),
        ('workspace `README.md`, `AGENTS.md`, and `HERMES.md`','workspace instructions requirement'),
        ('interactive decision buttons / `clarify`','decision UI requirement'),
        ('T1 - User-choice setup allowed after a clear choice','T1 permissions'),
        ('create the selected local workspace folder','workspace creation permission'),
        ('set non-secret Hermes config values','profile setup permission'),
        ('Tool readiness and software purpose map','inventory stage'),
        ('WSL is optional for Local backend','WSL optional rule'),
        ('starter capability pack','capability pack'),
        ('Starter capability pack','Stage 4 starter capability pack'),
        ('Communication surfaces and channel managers','Stage 5 communication map'),
        ('communication-channel-map.yaml','Stage 5 communication report'),
        ('SaaS operator kit','Stage 6 operator kit'),
        ('operator-kit/readiness_report.yaml','Stage 6 operator kit report'),
        ('failed_policy_violation','self-improvement hard fail'),
        ('invalid_bootstrap_report','contradiction guard'),
        ('language the user writes in','detect and mirror language'),
    ]:
        require(run, needle, label)
    require(skill, 'Positive setup permissions', 'skill positive permissions')
    require(skill, 'patches unrelated installed skills', 'unauthorized self-patch hard stop')
    if len(source.get('stages', [])) != 7:
        print('FAIL: expected bootstrap plus six stages')
        return 1
    if not any('selected allowed setup action' in x for x in source.get('stage_pass_requires', [])):
        print('FAIL: pass criteria do not require setup action verification')
        return 1
    print('validate_behavior_contract: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
