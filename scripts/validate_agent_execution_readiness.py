#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','PROJECT_TOOLCHAIN_REQUIREMENTS.md','SOFTWARE_GAP_ANALYSIS.md','HERMES_TOOLSET_PLAN.md','SKILL_LOAD_PLAN.md','AGENT_PIPELINE_PLAN.md','INSTALL_PLAN.md','COMMAND_READINESS.md','EXECUTION_READINESS_REPORT.yaml']
REQUIRED_FLAGS = ['readiness_status: partial','execution_ready: false','execution_allowed: false','install_gate_required: true','toolset_activation_gate_required: true','skill_load_gate_required: true','agent_pipeline_gate_required: true','software_installed: false','toolsets_enabled_without_gate: false','skills_installed_without_gate: false','agents_spawned: false','implementation_executed: false','file_changes_executed: false','commands_executed: false','tests_executed: false','dependencies_installed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','project_toolchain_requirements_present: true','software_gap_analysis_present: true','hermes_toolset_plan_present: true','skill_load_plan_present: true','agent_pipeline_plan_present: true','install_plan_present: true','command_readiness_present: true']
REQUIRED_CONSUMES = ['.hermes/project-audit/AUDIT_REPORT.yaml','.hermes/project-audit/PLAN_INTEGRITY_REPORT.md','.hermes/project-audit/IMPLEMENTATION_BLOCKERS.md','.hermes/project-audit/REPAIR_RECOMMENDATIONS.md','.hermes/local-pilot/EXECUTION_PACKET.md','.hermes/local-pilot/FILE_CHANGE_PLAN.md','.hermes/local-pilot/COMMAND_PLAN.md','.hermes/local-pilot/TEST_PLAN.md','.hermes/reports/software-inventory-report.yaml','.hermes/reports/software-purpose-map.yaml','.hermes/reports/software-install-recommendation.yaml','.hermes/reports/capability-graph.yaml','.hermes/reports/starter-capability-pack.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'agent-execution-readiness.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-agent-execution-readiness-v0_10':
        print('FAIL: unexpected agent readiness recipe_id')
        return 1
    if recipe.get('agent_readiness_root') != '.hermes/agent-readiness':
        print('FAIL: unexpected agent readiness root')
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
    contract_path = ROOT / recipe.get('stage_10_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 10 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_10_AGENT_EXECUTION_READINESS_v0_1',
        'Agent Execution Readiness and Toolchain Activation Plan',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/agent-readiness/',
        'PROJECT_TOOLCHAIN_REQUIREMENTS.md',
        'SOFTWARE_GAP_ANALYSIS.md',
        'HERMES_TOOLSET_PLAN.md',
        'SKILL_LOAD_PLAN.md',
        'AGENT_PIPELINE_PLAN.md',
        'INSTALL_PLAN.md',
        'COMMAND_READINESS.md',
        'EXECUTION_READINESS_REPORT.yaml',
        'project audit -> toolchain requirements -> gaps -> install/toolset/skill gates -> agent pipeline -> command readiness -> owner gate',
        'execution_ready: false',
        'install_gate_required: true',
        'toolsets_enabled_without_gate: false',
        'skills_installed_without_gate: false',
        'agents_spawned: false',
    ]:
        if marker not in contract:
            print('FAIL: Stage 10 contract marker missing: ' + marker)
            return 1
    print('validate_agent_execution_readiness: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
