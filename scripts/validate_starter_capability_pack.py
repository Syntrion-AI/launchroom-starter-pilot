#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

REQUIRED_TASK_CLASSES = [
    'profile_and_workspace_setup', 'code_change_delivery', 'research_and_evidence',
    'external_agent_handoff', 'web_browser_qa', 'cloud_runtime_readiness',
    'communication_gateway_readiness', 'observability_and_reports', 'security_and_secret_safety',
]

REQUIRED_FIELDS = ['starter_toolsets', 'starter_skills', 'memory_policy', 'workflow_playbook', 'gates', 'verification']


def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'starter-skillpack.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-starter-capability-pack-v0_6':
        print('FAIL: unexpected starter capability pack recipe_id')
        return 1
    contract_path = ROOT / recipe.get('stage_4_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 4 contract missing')
        return 1
    contract_text = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_4_STARTER_CAPABILITY_PACK_v0_1',
        'starter-capability-pack.yaml',
        'starter_toolsets',
        'starter_skills',
        'memory_policy',
        'workflow_playbook',
        'toolsets_enabled_without_gate',
        'memory_written_without_gate',
        'network_skills_installed_without_gate',
    ]:
        if marker not in contract_text:
            print('FAIL: Stage 4 contract marker missing: ' + marker)
            return 1
    for item in ['starter-capability-pack.yaml', 'task_class_to_toolsets', 'task_class_to_skills', 'memory_policy', 'workflow_playbooks', 'gates_and_verification', 'enablement_recommendations', 'actions_executed']:
        if item not in recipe.get('output', []):
            print('FAIL: starter capability recipe output missing: ' + item)
            return 1
    for task_class in REQUIRED_TASK_CLASSES:
        if task_class not in recipe.get('required_task_classes', []):
            print('FAIL: starter capability recipe task class missing: ' + task_class)
            return 1
        if task_class not in contract_text:
            print('FAIL: Stage 4 contract task class missing: ' + task_class)
            return 1
    for field in REQUIRED_FIELDS:
        if field not in recipe.get('required_fields_per_task_class', []):
            print('FAIL: starter capability required field missing: ' + field)
            return 1
    rules_text = '\n'.join(recipe.get('rules', []))
    for phrase in [
        'does not enable Hermes toolsets without explicit owner gate',
        'writes no persistent memory without explicit user approval',
        'does not install network skills without a separate gate',
        'runtime/provider/gateway/cloud/n8n mutation gates',
        'toolsets, skills, memory policy, workflow, gates, and verification',
    ]:
        if phrase not in rules_text:
            print('FAIL: starter capability rule missing: ' + phrase)
            return 1
    for forbidden in ['unauthorized toolset enablement', 'persistent memory write without user approval', 'network skill install without gate', 'provider/runtime/gateway/cloud/n8n mutation']:
        if forbidden not in recipe.get('hard_fail', []):
            print('FAIL: starter capability hard fail missing: ' + forbidden)
            return 1
    print('validate_starter_capability_pack: ok')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
