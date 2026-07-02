#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','EXECUTED_COMMANDS.md','CHANGED_FILES.md','TEST_RESULTS.md','ACCEPTANCE_EVIDENCE.md','USER_VISIBLE_RESULT.md','RESIDUAL_RISKS.md','ROLLBACK_AND_HANDOFF.md','EXECUTION_EVIDENCE_REPORT.yaml']
REQUIRED_FLAGS = ['evidence_binder_status: scaffold_only','real_execution_evidence_present: false','fabricated_evidence: false','implementation_executed_by_stage13: false','commands_executed_by_stage13: false','file_changes_executed_by_stage13: false','tests_executed_by_stage13: false','dependencies_installed_by_stage13: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','executed_commands_present: true','changed_files_present: true','test_results_present: true','acceptance_evidence_present: true','user_visible_result_present: true','residual_risks_present: true','rollback_and_handoff_present: true']
REQUIRED_CONSUMES = ['.hermes/skills/SKILL_INTEGRATION_REPORT.yaml','.hermes/hygiene/HYGIENE_REPORT.yaml','.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml','.hermes/local-pilot/EXECUTION_PACKET.md','.hermes/local-pilot/COMMAND_PLAN.md','.hermes/local-pilot/TEST_PLAN.md','.hermes/project-audit/AUDIT_REPORT.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'execution-evidence-binder.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-execution-evidence-binder-v0_13':
        print('FAIL: unexpected evidence binder recipe_id')
        return 1
    if recipe.get('evidence_root') != '.hermes/execution-evidence':
        print('FAIL: unexpected evidence root')
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
        if flag not in recipe.get('required_evidence_flags', []):
            print('FAIL: recipe missing evidence flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_13_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 13 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_13_EXECUTION_EVIDENCE_BINDER_v0_1',
        'Local Execution Evidence Binder',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/execution-evidence/',
        'EXECUTED_COMMANDS.md',
        'CHANGED_FILES.md',
        'TEST_RESULTS.md',
        'ACCEPTANCE_EVIDENCE.md',
        'USER_VISIBLE_RESULT.md',
        'RESIDUAL_RISKS.md',
        'ROLLBACK_AND_HANDOFF.md',
        'EXECUTION_EVIDENCE_REPORT.yaml',
        'no_fabricated_evidence',
        'evidence_binder_status: scaffold_only',
        'real_execution_evidence_present: false',
        'fabricated_evidence: false',
        'commands_executed_by_stage13: false',
    ]:
        if marker not in contract:
            print('FAIL: Stage 13 contract marker missing: ' + marker)
            return 1
    print('validate_execution_evidence_binder: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
