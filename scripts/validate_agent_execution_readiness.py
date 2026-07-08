#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = [
    'START_HERE.md',
    'PROJECT_TOOLCHAIN_REQUIREMENTS.md',
    'SOFTWARE_GAP_ANALYSIS.md',
    'HERMES_TOOLSET_PLAN.md',
    'SKILL_LOAD_PLAN.md',
    'AGENT_PIPELINE_PLAN.md',
    'INSTALL_PLAN.md',
    'COMMAND_READINESS.md',
    'TOOLCHAIN_ACTIVATION_PLAN.yaml',
    'EXECUTION_READINESS_REPORT.yaml',
]
REQUIRED_FLAGS = [
    'readiness_status: partial',
    'execution_ready: false',
    'execution_allowed: false',
    'install_gate_required: true',
    'toolset_activation_gate_required: true',
    'skill_load_gate_required: true',
    'agent_pipeline_gate_required: true',
    'software_installed: false',
    'toolsets_enabled_without_gate: false',
    'skills_installed_without_gate: false',
    'persistent_memory_written_without_gate: false',
    'agents_spawned: false',
    'implementation_executed: false',
    'file_changes_executed: false',
    'commands_executed: false',
    'tests_executed: false',
    'dependencies_installed: false',
    'runtime_mutation: false',
    'cloud_mutation: false',
    'gateway_mutation: false',
    'n8n_mutation: false',
    'secrets_read_or_written: false',
    'git_publication_executed: false',
    'project_toolchain_requirements_present: true',
    'software_gap_analysis_present: true',
    'hermes_toolset_plan_present: true',
    'skill_load_plan_present: true',
    'agent_pipeline_plan_present: true',
    'install_plan_present: true',
    'command_readiness_present: true',
    'activation_plan_present: true',
    'toolchain_requirements_structured: true',
    'software_gap_analysis_structured: true',
    'toolset_plan_structured: true',
    'skill_load_plan_structured: true',
    'agent_pipeline_structured: true',
    'install_plan_entries_present: true',
    'command_readiness_matrix_present: true',
    'readiness_blockers_present: true',
    'stage9_audit_findings_consumed: true',
]
REQUIRED_CONSUMES = [
    '.hermes/project-audit/AUDIT_REPORT.yaml',
    '.hermes/project-audit/AUDIT_FINDINGS.yaml',
    '.hermes/project-audit/PLAN_INTEGRITY_REPORT.md',
    '.hermes/project-audit/IMPLEMENTATION_BLOCKERS.md',
    '.hermes/project-audit/REPAIR_RECOMMENDATIONS.md',
    '.hermes/local-pilot/EXECUTION_PACKET.md',
    '.hermes/local-pilot/FILE_CHANGE_PLAN.md',
    '.hermes/local-pilot/COMMAND_PLAN.md',
    '.hermes/local-pilot/TEST_PLAN.md',
    '.hermes/local-pilot/EXTERNAL_PRACTICE_INPUTS.md',
    '.hermes/reports/software-inventory-report.yaml',
    '.hermes/reports/software-purpose-map.yaml',
    '.hermes/reports/software-install-recommendation.yaml',
    '.hermes/reports/capability-graph.yaml',
    '.hermes/reports/starter-capability-pack.yaml',
]


def fail(message: str) -> int:
    print('FAIL: ' + message)
    return 1


def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'agent-execution-readiness.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-agent-execution-readiness-v0_10':
        return fail('unexpected agent readiness recipe_id')
    if recipe.get('agent_readiness_root') != '.hermes/agent-readiness':
        return fail('unexpected agent readiness root')
    for f in REQUIRED_FILES:
        if f not in recipe.get('required_files', []):
            return fail('recipe missing required file: ' + f)
    for f in REQUIRED_CONSUMES:
        if f not in recipe.get('consumes', []):
            return fail('recipe missing consumed artifact: ' + f)
    for flag in REQUIRED_FLAGS:
        if flag not in recipe.get('required_readiness_flags', []):
            return fail('recipe missing readiness flag: ' + flag)

    schema = recipe.get('activation_plan_schema', {})
    if schema.get('artifact_id') != 'LAUNCHROOM_TOOLCHAIN_ACTIVATION_PLAN_v0_1':
        return fail('recipe activation_plan_schema wrong artifact_id')
    for field in ['required_sections', 'install_entry_required_fields', 'command_readiness_required_classes', 'false_action_flags']:
        if not isinstance(schema.get(field), list) or not schema.get(field):
            return fail('recipe activation_plan_schema missing list: ' + field)
    for section in ['toolchain_requirements','software_gap_analysis','toolset_plan','skill_load_plan','agent_pipeline','install_plan_entries','command_readiness','readiness_blockers','action_flags']:
        if section not in schema['required_sections']:
            return fail('recipe activation_plan_schema missing required section: ' + section)
    for field in ['software','why','command_shape','verification_commands','risk','rollback','gate']:
        if field not in schema['install_entry_required_fields']:
            return fail('recipe activation_plan_schema missing install entry field: ' + field)
    for field in ['read_only_allowed','gated_local_commands','install_commands','forbidden_without_gate']:
        if field not in schema['command_readiness_required_classes']:
            return fail('recipe activation_plan_schema missing command readiness class: ' + field)

    contract_path = ROOT / recipe.get('stage_10_contract', '')
    if not contract_path.exists():
        return fail('Stage 10 contract missing')
    contract_text = contract_path.read_text(encoding='utf-8')
    contract_yaml = yaml.safe_load(contract_text)
    if contract_yaml.get('artifact_id') != 'LAUNCHROOM_STAGE_10_AGENT_EXECUTION_READINESS_v0_1':
        return fail('Stage 10 contract wrong artifact_id')
    layout_files = contract_yaml.get('readiness_layout', {}).get('required_files', [])
    output_files = [Path(p).name for p in contract_yaml.get('outputs', {}).get('required', [])]
    for f in REQUIRED_FILES:
        if f not in layout_files:
            return fail('Stage 10 layout missing required file: ' + f)
        if f not in output_files:
            return fail('Stage 10 outputs missing required file: ' + f)
    contract_schema = contract_yaml.get('activation_plan_schema', {})
    if contract_schema.get('artifact_id') != schema.get('artifact_id'):
        return fail('Stage 10 activation_plan_schema drifted from recipe')
    for field in ['required_sections', 'install_entry_required_fields', 'command_readiness_required_classes', 'false_action_flags']:
        if set(contract_schema.get(field, [])) != set(schema.get(field, [])):
            return fail('Stage 10 activation_plan_schema drifted from recipe for ' + field)

    for marker in [
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
        'TOOLCHAIN_ACTIVATION_PLAN.yaml',
        'EXECUTION_READINESS_REPORT.yaml',
        'AUDIT_FINDINGS.yaml',
        'stage9_audit_findings_consumed: true',
        'activation_plan_present: true',
        'install_plan_entries_present: true',
        'command_readiness_matrix_present: true',
        'project audit -> toolchain requirements -> gaps -> install/toolset/skill gates -> agent pipeline -> command readiness -> owner gate',
        'execution_ready: false',
        'install_gate_required: true',
        'toolsets_enabled_without_gate: false',
        'skills_installed_without_gate: false',
        'persistent_memory_written_without_gate: false',
        'agents_spawned: false',
    ]:
        if marker not in contract_text:
            return fail('Stage 10 contract marker missing: ' + marker)

    installer = (ROOT / 'scripts' / 'install_launchroom_profile.ps1').read_text(encoding='utf-8')
    for marker in [
        "TOOLCHAIN_ACTIVATION_PLAN.yaml",
        "artifact_id: LAUNCHROOM_TOOLCHAIN_ACTIVATION_PLAN_v0_1",
        "toolchain_requirements:",
        "software_gap_analysis:",
        "toolset_plan:",
        "skill_load_plan:",
        "agent_pipeline:",
        "install_plan_entries:",
        "command_readiness:",
        "readiness_blockers:",
        "activation_plan_present: true",
        "toolchain_requirements_structured: true",
        "install_plan_entries_present: true",
        "command_readiness_matrix_present: true",
        "readiness_blockers_present: true",
    ]:
        if marker not in installer:
            return fail('installer missing Stage 10 structured activation marker: ' + marker)

    print('validate_agent_execution_readiness: ok')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
