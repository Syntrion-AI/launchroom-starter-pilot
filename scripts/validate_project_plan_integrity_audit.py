#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','PLAN_INTEGRITY_REPORT.md','EXPECTED_RESULT_MAP.md','MISSING_FRAGMENTS.md','CONTRADICTION_SCAN.md','STAGE_DRIFT_SCAN.md','ASSUMPTION_REGISTER.md','IMPLEMENTATION_BLOCKERS.md','REPAIR_RECOMMENDATIONS.md','AUDIT_REPORT.yaml']
REQUIRED_FLAGS = ['audit_status: partial','execution_allowed: false','implementation_executed: false','file_changes_executed: false','commands_executed: false','tests_executed: false','dependencies_installed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','plan_integrity_report_present: true','expected_result_map_present: true','missing_fragments_report_present: true','contradiction_scan_present: true','stage_drift_scan_present: true','assumption_register_present: true','implementation_blockers_present: true','repair_recommendations_present: true']
REQUIRED_CONSUMES = ['.hermes/operator-kit/guided-session/PROJECT_BLUEPRINT.md','.hermes/operator-kit/guided-session/FIRST_SLICE_PACKET.md','.hermes/operator-kit/guided-session/IMPLEMENTATION_ROADMAP.md','.hermes/first-slice/IMPLEMENTATION_BRIEF.md','.hermes/first-slice/LOCAL_PILOT_PLAN.md','.hermes/first-slice/ACCEPTANCE_TESTS.md','.hermes/first-slice/USER_DEMO_SCRIPT.md','.hermes/first-slice/RISKS_AND_ROLLBACK.md','.hermes/first-slice/DECISION_GATE.md','.hermes/local-pilot/EXECUTION_PACKET.md','.hermes/local-pilot/FILE_CHANGE_PLAN.md','.hermes/local-pilot/COMMAND_PLAN.md','.hermes/local-pilot/TEST_PLAN.md','.hermes/local-pilot/EXTERNAL_PRACTICE_INPUTS.md','.hermes/local-pilot/READINESS_REPORT.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'project-plan-integrity-audit.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-project-plan-integrity-audit-v0_9':
        print('FAIL: unexpected project audit recipe_id')
        return 1
    if recipe.get('project_audit_root') != '.hermes/project-audit':
        print('FAIL: unexpected project audit root')
        return 1
    for f in REQUIRED_FILES:
        if f not in recipe.get('required_files', []):
            print('FAIL: recipe missing required file: ' + f)
            return 1
    for f in REQUIRED_CONSUMES:
        if f not in recipe.get('consumes', []):
            print('FAIL: recipe missing consumed artifact: ' + f)
            return 1
    for flag in REQUIRED_FLAGS:
        if flag not in recipe.get('required_readiness_flags', []):
            print('FAIL: recipe missing readiness flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_9_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 9 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_9_PROJECT_PLAN_INTEGRITY_AUDIT_v0_1',
        'Project Plan Integrity and Drift Audit',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/project-audit/',
        'PLAN_INTEGRITY_REPORT.md',
        'EXPECTED_RESULT_MAP.md',
        'MISSING_FRAGMENTS.md',
        'CONTRADICTION_SCAN.md',
        'STAGE_DRIFT_SCAN.md',
        'ASSUMPTION_REGISTER.md',
        'IMPLEMENTATION_BLOCKERS.md',
        'REPAIR_RECOMMENDATIONS.md',
        'AUDIT_REPORT.yaml',
        'blueprint -> first slice -> execution packet -> integrity audit -> repair or readiness gate',
        'execution_allowed: false',
        'contradiction_scan_present: true',
        'stage_drift_scan_present: true',
        'repair_recommendations_present: true',
    ]:
        if marker not in contract:
            print('FAIL: Stage 9 contract marker missing: ' + marker)
            return 1
    print('validate_project_plan_integrity_audit: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
