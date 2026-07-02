#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','NEXT_DECISION.md','CHECK_IT_WORKS.md','PAIN_TO_WORKFLOW_EXAMPLES.md','product_brief.md','target_user.md','first_workflow.md','backlog.md','local_task_packet.md','gates.md','readiness_report.yaml','guided-session/SESSION_STATE.yaml','guided-session/AGENT_GUIDE.md','guided-session/USER_LESSON.md','guided-session/IDEA_INTAKE.md','guided-session/PROJECT_BLUEPRINT.md','guided-session/FIRST_SLICE_PACKET.md','guided-session/DEFAULT_WORKFLOW_CATALOG.md','guided-session/IMPLEMENTATION_ROADMAP.md','guided-session/COMPLETION_SUMMARY.md']
REQUIRED_FLAGS = ['runtime_mutation: false','cloud_mutation: false','n8n_mutation: false','gateway_mutation: false','git_publication_executed: false','secrets_read_or_written: false','implementation_executed: false','beginner_next_decision_present: true','pain_to_workflow_examples_present: true','guided_session_present: true','no_idea_default_workflow_catalog_present: true','blueprint_to_solution_path_present: true']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'saas-operator-kit.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-saas-operator-kit-v0_6':
        print('FAIL: unexpected saas operator kit recipe_id')
        return 1
    if recipe.get('operator_kit_root') != '.hermes/operator-kit':
        print('FAIL: unexpected operator kit root')
        return 1
    for f in REQUIRED_FILES:
        if f not in recipe.get('required_files', []):
            print('FAIL: recipe missing required file: ' + f)
            return 1
    for flag in REQUIRED_FLAGS:
        if flag not in recipe.get('required_readiness_flags', []):
            print('FAIL: recipe missing readiness flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_6_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 6 contract missing')
        return 1
    contract_text = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_6_SAAS_OPERATOR_KIT_v0_1',
        'SaaS Operator Kit',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/operator-kit/',
        'product_brief.md',
        'target_user.md',
        'first_workflow.md',
        'backlog.md',
        'local_task_packet.md',
        'gates.md',
        'readiness_report.yaml',
        'START_HERE.md',
        'NEXT_DECISION.md',
        'CHECK_IT_WORKS.md',
        'PAIN_TO_WORKFLOW_EXAMPLES.md',
        'beginner can verify',
        'pain-to-workflow examples',
        'guided-session/SESSION_STATE.yaml',
        'DEFAULT_WORKFLOW_CATALOG.md',
        'IMPLEMENTATION_ROADMAP.md',
        'messenger setup',
        'blueprint -> first slice packet -> implementation plan -> local pilot -> verification -> next gate',
        'intent -> scope -> evidence -> structure -> delivery packet -> execution -> verification -> handoff -> next decision',
    ]:
        if marker not in contract_text:
            print('FAIL: Stage 6 contract marker missing: ' + marker)
            return 1
    for flag in REQUIRED_FLAGS:
        if flag not in contract_text:
            print('FAIL: Stage 6 contract missing readiness flag: ' + flag)
            return 1
    if recipe.get('guided_session_required') is not True:
        print('FAIL: guided_session_required is not true')
        return 1
    for state in ['orientation','structure_created','idea_or_default_workflow_intake','first_slice_packet_created','implementation_roadmap_created','next_gate_pending']:
        if state not in recipe.get('guided_session_states', []):
            print('FAIL: recipe missing guided state: ' + state)
            return 1
    for wf in ['messenger_setup_and_control','telegram_or_discord_channel_management','email_calendar_notes_assistant','personal_daily_briefing','idea_to_project_blueprint']:
        if wf not in recipe.get('no_idea_default_workflows', []):
            print('FAIL: recipe missing default workflow: ' + wf)
            return 1
    if recipe.get('blueprint_to_solution_path_required') is not True:
        print('FAIL: blueprint_to_solution_path_required is not true')
        return 1
    blocked = recipe.get('blocked_without_gate', [])
    for item in ['Cloudflare mutation','Hetzner mutation','n8n mutation','MCP/runtime mutation','provider/model/billing mutation','gateway setup/autostart/pairing','production deploy','public git push','secret readback or storage']:
        if item not in blocked:
            print('FAIL: recipe missing blocked action: ' + item)
            return 1
    print('validate_saas_operator_kit: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
