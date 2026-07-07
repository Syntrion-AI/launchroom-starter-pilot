#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','IMPLEMENTATION_BRIEF.md','LOCAL_PILOT_PLAN.md','ACCEPTANCE_TESTS.md','USER_DEMO_SCRIPT.md','RISKS_AND_ROLLBACK.md','DECISION_GATE.md','READINESS_REPORT.yaml']
REQUIRED_FLAGS = ['implementation_executed: false','dependencies_installed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','local_pilot_plan_present: true','acceptance_tests_present: true','user_demo_script_present: true','next_implementation_gate_present: true','acceptance_contract_present: true','primary_signal_present: true','pass_criteria_present: true','secondary_signals_present: true','evidence_required_present: true','cannot_claim_done_if_present: true']
REQUIRED_CONSUMES = ['.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md','.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md','.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md','.hermes/operator-kit/guided-session/DEFAULT_WORKFLOW_CATALOG.md']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'first-slice-planning.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-first-slice-planning-v0_7':
        print('FAIL: unexpected first slice recipe_id')
        return 1
    if recipe.get('first_slice_root') != '.hermes/first-slice':
        print('FAIL: unexpected first slice root')
        return 1
    for f in REQUIRED_FILES:
        if f not in recipe.get('required_files', []):
            print('FAIL: recipe missing required file: ' + f)
            return 1
    for f in REQUIRED_CONSUMES:
        if f not in recipe.get('consumes', []):
            print('FAIL: recipe missing consumed Stage 6 artifact: ' + f)
            return 1
    for flag in REQUIRED_FLAGS:
        if flag not in recipe.get('required_readiness_flags', []):
            print('FAIL: recipe missing readiness flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_7_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 7 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_7_FIRST_SLICE_PLANNING_v0_1',
        'First Slice Implementation Planning and Local Pilot Readiness',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/first-slice/',
        'IMPLEMENTATION_BRIEF.md',
        'LOCAL_PILOT_PLAN.md',
        'ACCEPTANCE_TESTS.md',
        'USER_DEMO_SCRIPT.md',
        'RISKS_AND_ROLLBACK.md',
        'DECISION_GATE.md',
        'READINESS_REPORT.yaml',
        'blueprint -> first slice packet -> implementation brief -> local pilot plan -> acceptance tests -> demo script -> decision gate',
        'local_pilot_plan_present: true',
        'acceptance_tests_present: true',
        'user_demo_script_present: true',
        'next_implementation_gate_present: true',
        'acceptance_contract:',
        'required_for_non_trivial_packets: true',
        'primary_signal_required: true',
        'pass_criteria_minimum: 3',
        'secondary_signals_required: true',
        'acceptance_contract_present: true',
        'primary_signal_present: true',
        'pass_criteria_present: true',
        'secondary_signals_present: true',
        'evidence_required_present: true',
        'cannot_claim_done_if_present: true',
    ]:
        if marker not in contract:
            print('FAIL: Stage 7 contract marker missing: ' + marker)
            return 1
    acceptance = recipe.get('acceptance_contract', {})
    if acceptance.get('required_for_non_trivial_packets') is not True:
        print('FAIL: recipe acceptance contract must be required for non-trivial packets')
        return 1
    for field in ['primary_signal','pass_criteria','secondary_signals','evidence_required','cannot_claim_done_if']:
        if field not in acceptance.get('required_fields', []):
            print('FAIL: recipe acceptance contract missing field: ' + field)
            return 1
    for item in ['write product code','install dependencies','connect live messenger/email/calendar/notes','gateway setup/autostart/pairing','Cloudflare mutation','Hetzner mutation','n8n mutation','MCP/runtime mutation','provider/model/billing mutation','database mutation','production deploy','public git push','secret readback or storage']:
        if item not in recipe.get('blocked_without_gate', []):
            print('FAIL: recipe missing blocked action: ' + item)
            return 1
    print('validate_first_slice_planning: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
