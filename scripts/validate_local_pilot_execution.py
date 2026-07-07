#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','EXECUTION_PACKET.md','FILE_CHANGE_PLAN.md','COMMAND_PLAN.md','TEST_PLAN.md','EXTERNAL_PRACTICE_INPUTS.md','EVIDENCE_LOG.md','REVIEW_CHECKLIST.md','HANDOFF_SUMMARY.md','READINESS_REPORT.yaml']
REQUIRED_FLAGS = ['implementation_executed: false','file_changes_executed: false','commands_executed: false','tests_executed: false','dependencies_installed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','execution_packet_present: true','file_change_plan_present: true','command_plan_present: true','test_plan_present: true','evidence_log_present: true','review_checklist_present: true','handoff_summary_present: true','next_execution_gate_present: true','local_pilot_isolation_present: true','test_data_only: true','prod_or_dev_database_forbidden: true','test_database_suffix_required_when_database_url_present: true','repo_derived_or_isolated_ports_preferred: true','ambiguous_data_target_blocks_execution: true','external_practice_inputs_present: true','external_practices_mapped_not_copied: true','package_manager_detection_required: true','commands_derived_from_repo_scripts_required: true','test_level_selection_required: true','provider_and_mobile_surfaces_gated: true']
REQUIRED_CONSUMES = ['.hermes/first-slice/IMPLEMENTATION_BRIEF.md','.hermes/first-slice/LOCAL_PILOT_PLAN.md','.hermes/first-slice/ACCEPTANCE_TESTS.md','.hermes/first-slice/USER_DEMO_SCRIPT.md','.hermes/first-slice/RISKS_AND_ROLLBACK.md','.hermes/first-slice/DECISION_GATE.md','.hermes/first-slice/READINESS_REPORT.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'local-pilot-execution.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-local-pilot-execution-v0_8':
        print('FAIL: unexpected local pilot recipe_id')
        return 1
    if recipe.get('local_pilot_root') != '.hermes/local-pilot':
        print('FAIL: unexpected local pilot root')
        return 1
    for f in REQUIRED_FILES:
        if f not in recipe.get('required_files', []):
            print('FAIL: recipe missing required file: ' + f)
            return 1
    for f in REQUIRED_CONSUMES:
        if f not in recipe.get('consumes', []):
            print('FAIL: recipe missing consumed Stage 7 artifact: ' + f)
            return 1
    for flag in REQUIRED_FLAGS:
        if flag not in recipe.get('required_readiness_flags', []):
            print('FAIL: recipe missing readiness flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_8_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 8 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_8_LOCAL_PILOT_EXECUTION_PACKET_v0_1',
        'Local Pilot Execution Packet',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/local-pilot/',
        'EXECUTION_PACKET.md',
        'FILE_CHANGE_PLAN.md',
        'COMMAND_PLAN.md',
        'TEST_PLAN.md',
        'EXTERNAL_PRACTICE_INPUTS.md',
        'EVIDENCE_LOG.md',
        'REVIEW_CHECKLIST.md',
        'HANDOFF_SUMMARY.md',
        'READINESS_REPORT.yaml',
        'first slice plan -> execution packet -> file change plan -> command plan -> test plan -> external practice inputs -> evidence log -> review checklist -> handoff summary',
        'file_changes_executed: false',
        'commands_executed: false',
        'tests_executed: false',
        'execution_packet_present: true',
        'file_change_plan_present: true',
        'command_plan_present: true',
        'test_plan_present: true',
        'external_practice_inputs_present: true',
        'external_practices_mapped_not_copied: true',
        'package_manager_detection_required: true',
        'commands_derived_from_repo_scripts_required: true',
        'test_level_selection_required: true',
        'provider_and_mobile_surfaces_gated: true',
        'evidence_log_present: true',
        'review_checklist_present: true',
        'handoff_summary_present: true',
        'next_execution_gate_present: true',
        'external_practice_inputs:',
        'donor_reference_policy:',
        'external_practices_mapped_not_copied',
        'commands_derived_from_repo_scripts_required',
        'local_pilot_isolation:',
        'test_data_only: true',
        'forbid_prod_or_dev_database_in_tests: true',
        'require_test_suffix_when_database_url_present: true',
        'prefer_repo_derived_ports_for_parallel_checkouts: true',
        'stop_not_repair_if_data_target_is_ambiguous: true',
        'local_pilot_isolation_present: true',
        'test_database_suffix_required_when_database_url_present: true',
        'ambiguous_data_target_blocks_execution: true',
    ]:
        if marker not in contract:
            print('FAIL: Stage 8 contract marker missing: ' + marker)
            return 1
    isolation = recipe.get('local_pilot_isolation', {})
    for key in ['test_data_only','forbid_prod_or_dev_database_in_tests','require_test_suffix_when_database_url_present','prefer_repo_derived_ports_for_parallel_checkouts','stop_not_repair_if_data_target_is_ambiguous']:
        if isolation.get(key) is not True:
            print(f'FAIL: recipe local pilot isolation missing {key}=true')
            return 1
    for item in ['write product code','modify project files','run write/build/deploy commands','install dependencies','connect live messenger/email/calendar/notes','gateway setup/autostart/pairing','Cloudflare mutation','Hetzner mutation','n8n mutation','MCP/runtime mutation','provider/model/billing mutation','database mutation','production deploy','public git push','secret readback or storage']:
        if item not in recipe.get('blocked_without_gate', []):
            print('FAIL: recipe missing blocked action: ' + item)
            return 1
    print('validate_local_pilot_execution: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
