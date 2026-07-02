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
        ('Use the Hermes `clarify` tool for interactive decisions','decision UI clarify tool requirement'),
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
        ('First slice implementation planning and local pilot readiness','Stage 7 first-slice planning'),
        ('READINESS_REPORT.yaml parses as YAML','Stage 7 first-slice report'),
        ('Local pilot execution packet','Stage 8 local pilot execution packet'),
        ('local-pilot/READINESS_REPORT.yaml','Stage 8 local pilot report'),
        ('Project plan integrity and drift audit','Stage 9 project plan integrity audit'),
        ('project-audit/AUDIT_REPORT.yaml','Stage 9 project audit report'),
        ('Agent execution readiness and toolchain activation plan','Stage 10 agent execution readiness'),
        ('agent-readiness/EXECUTION_READINESS_REPORT.yaml','Stage 10 agent readiness report'),
        ('Workspace hygiene, cleanup, and artifact lifecycle','Stage 11 workspace hygiene'),
        ('hygiene/HYGIENE_REPORT.yaml','Stage 11 hygiene report'),
        ('Skill capture and stage skill integration pack','Stage 12 skill capture'),
        ('skills/SKILL_INTEGRATION_REPORT.yaml','Stage 12 skill integration report'),
        ('Local execution evidence binder','Stage 13 execution evidence binder'),
        ('execution-evidence/EXECUTION_EVIDENCE_REPORT.yaml','Stage 13 execution evidence report'),
        ('failed_policy_violation','self-improvement hard fail'),
        ('invalid_bootstrap_report','contradiction guard'),
        ('language the user writes in','detect and mirror language'),
    ]:
        require(run, needle, label)
    require(skill, 'Positive setup permissions', 'skill positive permissions')
    require(skill, 'patches unrelated installed skills', 'unauthorized self-patch hard stop')
    if len(source.get('stages', [])) != 14:
        print('FAIL: expected bootstrap plus thirteen stages')
        return 1
    if not any('selected allowed setup action' in x for x in source.get('stage_pass_requires', [])):
        print('FAIL: pass criteria do not require setup action verification')
        return 1

    decision = source.get('decision_ui_contract', {})
    clarify = decision.get('clarify_tool_contract', {})
    required_clarify_markers = {
        'clarify_tool_required_when_available': True,
        'choices_must_be_tool_choices_array': True,
        'do_not_embed_options_in_question_text': True,
        'plain_text_options_are_fallback_only': True,
        'desktop_requires_pending_clarify_tool_call': True,
        'telegram_native_buttons_are_adapter_specific': True,
    }
    for key, expected in required_clarify_markers.items():
        if clarify.get(key) is not expected:
            print(f'FAIL: decision UI clarify contract missing {key}={expected}')
            return 1
    for point in ['git publication gate','implementation gate','runtime/provider/secret/destructive-action gate']:
        if point not in decision.get('required_decision_points', []):
            print('FAIL: decision UI required point missing ' + point)
            return 1


    rooms_contract = source.get('wizard_rooms_contract', {})
    if rooms_contract.get('enabled') is not True:
        print('FAIL: wizard rooms contract is not enabled')
        return 1
    if rooms_contract.get('machine_stages_remain_authoritative') is not True:
        print('FAIL: wizard rooms must not replace machine stages')
        return 1
    if rooms_contract.get('rooms_are_user_navigation_only') is not True:
        print('FAIL: wizard rooms must be user navigation only')
        return 1
    rooms = rooms_contract.get('rooms', [])
    if rooms_contract.get('room_count') != 5 or len(rooms) != 5:
        print('FAIL: expected five beginner wizard rooms')
        return 1
    expected_room_names = [
        'Foundation Room',
        'Capability Room',
        'Product Starter Room',
        'Readiness & Drift Room',
        'Control & Evidence Room',
    ]
    if [room.get('name') for room in rooms] != expected_room_names:
        print('FAIL: wizard room names/order mismatch')
        return 1
    source_stage_ids = [stage.get('id') for stage in source.get('stages', [])]
    room_stage_ids = [stage_id for room in rooms for stage_id in room.get('stages', [])]
    if room_stage_ids != source_stage_ids:
        print('FAIL: wizard rooms must cover every source stage exactly once and preserve order')
        return 1
    for room in rooms:
        for key in ['id', 'name', 'label', 'stages', 'user_goal', 'plain_language_result', 'next_decision']:
            if not room.get(key):
                print(f'FAIL: wizard room missing {key}')
                return 1
    interaction_rule = rooms_contract.get('interaction_rule', '')
    if 'clarify' not in interaction_rule or 'fallback only' not in interaction_rule:
        print('FAIL: wizard room interaction rule must require clarify and mark plain text as fallback')
        return 1
    for needle,label in [
        ('Beginner Wizard Rooms','wizard rooms section'),
        ('Room 1: Foundation Room','foundation room'),
        ('Room 2: Capability Room','capability room'),
        ('Room 3: Product Starter Room','product starter room'),
        ('Room 4: Readiness & Drift Room','readiness drift room'),
        ('Room 5: Control & Evidence Room','control evidence room'),
        ('do not replace or collapse the stage contracts','machine stage preservation'),
        ('Room transitions should use the Hermes `clarify` tool','wizard room clarify transitions'),
    ]:
        require(run, needle, label)
    print('validate_behavior_contract: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
