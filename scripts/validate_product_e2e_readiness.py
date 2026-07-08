#!/usr/bin/env python3
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> int:
    print('FAIL: ' + message)
    return 1


def require_text(text: str, needle: str, label: str) -> None:
    if needle not in text:
        raise AssertionError(f'missing {label}: {needle}')


def main() -> int:
    source = json.loads((ROOT / 'source' / 'launchroom.starter.v0_5.json').read_text(encoding='utf-8'))
    contract = json.loads((ROOT / 'contracts' / 'launchroom-stage-contract.json').read_text(encoding='utf-8'))
    readme = (ROOT / 'README.md').read_text(encoding='utf-8')
    runbook = (ROOT / 'RUN_ME_FIRST.md').read_text(encoding='utf-8')
    generated_runbook = (ROOT / 'generated' / 'RUN_ME_FIRST.md').read_text(encoding='utf-8')

    if runbook != generated_runbook:
        return fail('RUN_ME_FIRST.md and generated/RUN_ME_FIRST.md drifted')

    boundary = source.get('product_boundary_contract', {})
    if boundary.get('enabled') is not True:
        return fail('product_boundary_contract is not enabled')
    if contract.get('product_boundary_contract') != boundary:
        return fail('product_boundary_contract drifted between source and generated contract')
    if boundary.get('artifact_id') != 'LAUNCHROOM_STARTER_PRODUCT_BOUNDARY_v1_0':
        return fail('product boundary artifact_id mismatch')
    if boundary.get('starter_definition_of_done') != 'safe_local_saas_project_operator_to_first_execution_gate':
        return fail('product boundary definition of done mismatch')
    if boundary.get('no_new_setup_stages_without_user_facing_acceptance_failure') is not True:
        return fail('product boundary must freeze new setup stages by default')
    if boundary.get('machine_stage_count_frozen_at') != 14:
        return fail('product boundary must freeze current machine stage count at 14')
    if len(source.get('stages', [])) != boundary.get('machine_stage_count_frozen_at'):
        return fail('actual source stage count does not match product boundary freeze')
    if len(contract.get('stages', [])) != boundary.get('machine_stage_count_frozen_at'):
        return fail('generated contract stage count does not match product boundary freeze')

    required_in_scope = [
        'link_to_operator_bootstrap',
        'fresh_clone_self_test',
        'safe_profile_workspace_setup',
        'software_capability_skill_memory_maps',
        'communication_path_prepared_without_pairing',
        'operator_kit_first_slice_local_pilot_readiness',
        'project_audit_agent_readiness_hygiene_skill_evidence_scaffolds',
        'clear_next_gate_for_implementation_install_release_or_pause',
    ]
    if boundary.get('starter_in_scope') != required_in_scope:
        return fail('starter_in_scope list/order mismatch')

    required_out_of_scope = [
        'automatic_cloud_runtime_deployment',
        'cloudflare_hetzner_n8n_mutation',
        'gateway_pairing_or_home_channel_changes',
        'provider_model_billing_or_secret_setup',
        'autonomous_agent_execution_without_owner_gate',
        'production_database_or_customer_data_mutation',
        'git_tag_or_github_release_without_release_gate',
    ]
    if boundary.get('starter_out_of_scope') != required_out_of_scope:
        return fail('starter_out_of_scope list/order mismatch')

    required_completion_gates = [
        'fresh_clone_acceptance_passed',
        'disposable_self_test_acceptance_passed',
        'isolated_real_profile_setup_acceptance_passed_or_blocked_with_reason',
        'first_product_journey_reaches_execution_gate',
        'release_artifact_walkthrough_passed_before_public_release',
        'no_release_tag_runtime_cloud_gateway_n8n_secret_mutation_without_separate_gate',
    ]
    if boundary.get('v1_completion_gates') != required_completion_gates:
        return fail('v1 completion gates list/order mismatch')

    e2e = source.get('end_to_end_acceptance_contract', {})
    if e2e.get('enabled') is not True:
        return fail('end_to_end_acceptance_contract is not enabled')
    if contract.get('end_to_end_acceptance_contract') != e2e:
        return fail('end_to_end_acceptance_contract drifted between source and generated contract')
    if e2e.get('artifact_id') != 'LAUNCHROOM_END_TO_END_ACCEPTANCE_v1_0':
        return fail('e2e artifact_id mismatch')
    if e2e.get('acceptance_status_before_run') != 'not_passed_until_real_e2e_evidence_exists':
        return fail('e2e acceptance status must not claim pass before evidence')

    expected_scenarios = [
        'fresh_clone_disposable_self_test',
        'isolated_real_profile_setup',
        'first_product_journey_to_execution_gate',
        'published_release_artifact_walkthrough_after_release_gate',
    ]
    scenarios = e2e.get('scenarios', [])
    if [scenario.get('id') for scenario in scenarios] != expected_scenarios:
        return fail('e2e scenario id/order mismatch')
    for scenario in scenarios:
        for field in ['id', 'goal', 'entry_surface', 'commands_or_actions', 'pass_signals', 'blocked_if', 'writes_allowed', 'forbidden_actions']:
            if field not in scenario:
                return fail(f'e2e scenario missing field {field}: ' + str(scenario.get('id')))
        for field in ['id', 'goal', 'entry_surface']:
            if not isinstance(scenario.get(field), str) or not scenario.get(field).strip():
                return fail(f'e2e scenario field must be non-empty string {field}: ' + str(scenario.get('id')))
        for field in ['commands_or_actions', 'pass_signals', 'blocked_if', 'writes_allowed', 'forbidden_actions']:
            if not isinstance(scenario.get(field), list) or not scenario.get(field):
                return fail(f'e2e scenario field must be non-empty list {field}: ' + str(scenario.get('id')))
            if not all(isinstance(item, str) and item.strip() for item in scenario.get(field, [])):
                return fail(f'e2e scenario list items must be non-empty strings {field}: ' + str(scenario.get('id')))
        if len(scenario.get('commands_or_actions', [])) < 3:
            return fail('e2e scenario must have at least 3 commands/actions: ' + scenario['id'])
        if len(scenario.get('pass_signals', [])) < 3:
            return fail('e2e scenario must have at least 3 pass signals: ' + scenario['id'])
        if len(scenario.get('blocked_if', [])) < 3:
            return fail('e2e scenario must have at least 3 blocked_if conditions: ' + scenario['id'])
        forbidden = scenario.get('forbidden_actions', [])
        for action in ['secret_readback_or_storage', 'runtime_provider_cloud_gateway_n8n_mutation']:
            if action not in forbidden:
                return fail('e2e scenario forbidden actions missing ' + action + ': ' + scenario['id'])

    release_walkthrough = next(scenario for scenario in scenarios if scenario.get('id') == 'published_release_artifact_walkthrough_after_release_gate')
    if release_walkthrough.get('writes_allowed') != ['local temporary download or checkout for verification only after separate owner release gate']:
        return fail('release walkthrough writes_allowed must not authorize release artifact mutation')

    blocked = e2e.get('blocked_until_separate_gate', [])
    for action in ['github_release_creation', 'git_tag_creation_or_push', 'runtime_provider_cloud_gateway_n8n_mutation', 'secret_collection_readback_or_storage']:
        if action not in blocked:
            return fail('e2e blocked action missing ' + action)

    required_readme_markers = [
        '## Product boundary and v1.0 definition of done',
        'safe local SaaS/project operator to first execution gate',
        'No new setup stages are added unless a real user-facing acceptance failure proves the need.',
        '## End-to-end acceptance path',
        'fresh_clone_disposable_self_test',
        'isolated_real_profile_setup',
        'first_product_journey_to_execution_gate',
        'published_release_artifact_walkthrough_after_release_gate',
    ]
    for marker in required_readme_markers:
        require_text(readme, marker, 'README product/e2e marker')

    required_runbook_markers = [
        '## Product Boundary / Definition of Done',
        '## End-to-End Acceptance Path',
        'starter_in_scope',
        'starter_out_of_scope',
        'fresh_clone_disposable_self_test',
        'isolated_real_profile_setup',
        'No new setup stages are authorized by this section.',
        'release/tag remains blocked until a separate owner release gate',
    ]
    for marker in required_runbook_markers:
        require_text(runbook, marker, 'RUN_ME_FIRST product/e2e marker')

    print('validate_product_e2e_readiness: ok')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print('FAIL: ' + str(exc))
        raise SystemExit(1)
