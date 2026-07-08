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
    for section in ['product_mode_lock_contract','stage_result_chat_contract','hard_stage_transition_contract','skills_software_inventory_contract','default_profile_policy','project_intake_contract','active_deferred_surfaces_contract','template_origin_safety_contract','acceptance_contract','local_pilot_isolation_contract']:
        if section not in source:
            print('FAIL: source missing ' + section)
            return 1
    if source['product_mode_lock_contract'].get('enabled') is not True:
        print('FAIL: product-mode lock contract is not enabled')
        return 1
    if source['stage_result_chat_contract'].get('chat_summary_required') is not True:
        print('FAIL: stage result chat contract must require chat summary')
        return 1
    if source['hard_stage_transition_contract'].get('self_test_only_is_not_stage_1_pass') is not True:
        print('FAIL: hard transition contract must reject self-test-only as Stage 1 pass')
        return 1
    if source['skills_software_inventory_contract'].get('required_before_profile_factory_or_project_profile_decision') is not True:
        print('FAIL: skills/software inventory must precede profile-factory/project-profile decisions')
        return 1
    if source['default_profile_policy'].get('default_profile_promotion_requires_reviewed_gate') is not True:
        print('FAIL: default profile promotion must require reviewed gate')
        return 1
    for needle,label in [
        ('Product-mode lock','product mode lock docs'),
        ('Stage result and transition contract','stage result transition docs'),
        ('skills/software/toolsets inventory','skills software inventory docs'),
        ('Project Intake, Surface Routing, and Template Safety','v0.7.2 project intake section'),
        ('Project intake contract','project intake docs'),
        ('Active/deferred surface routing','active/deferred surface docs'),
        ('Website/public SEO rule','website routing rule'),
        ('Webapp/authenticated CSR rule','webapp routing rule'),
        ('Template-origin and git publication safety','template-origin safety docs'),
        ('Acceptance contract','acceptance contract docs'),
        ('Local pilot isolation','local pilot isolation docs'),
    ]:
        require(run, needle, label)

    project_intake = source.get('project_intake_contract', {})
    if project_intake.get('enabled') is not True:
        print('FAIL: project intake contract is not enabled')
        return 1
    required_intake_fields = list(project_intake.get('required_fields', []))
    expected_intake_fields = ['project_name_or_slug','product_goal','first_user_journey','active_surfaces','deferred_surfaces','needs_auth','needs_persistence','needs_uploads_or_media','needs_payments','needs_admin_tools','needs_external_integrations','needs_realtime_or_collaboration','deployment_needed_now','validation_scope']
    for field in expected_intake_fields:
        if field not in required_intake_fields:
            print('FAIL: project intake required field missing ' + field)
            return 1
    if project_intake.get('do_not_ask_before_stage_5_or_project_onboarding_gate') is not True:
        print('FAIL: project intake must not start before Stage 5/project onboarding gate')
        return 1

    surfaces = source.get('active_deferred_surfaces_contract', {})
    if surfaces.get('enabled') is not True:
        print('FAIL: active/deferred surfaces contract is not enabled')
        return 1
    for surface in ['website_public_seo','webapp_authenticated_csr','backend_api','mobile_app','automation_or_n8n','cloud_runtime']:
        if surface not in surfaces.get('required_surfaces', []):
            print('FAIL: required surface missing ' + surface)
            return 1
    browser = surfaces.get('browser_routing_rule', {})
    if browser.get('do_not_build_seo_pages_inside_authenticated_webapp_by_habit') is not True or browser.get('do_not_move_full_authenticated_app_into_website_by_habit') is not True:
        print('FAIL: browser surface routing guard missing')
        return 1
    mobile = surfaces.get('mobile_policy', {})
    if mobile.get('activate_only_after_explicit_mobile_choice') is not True:
        print('FAIL: mobile must remain deferred/gated unless explicitly activated')
        return 1

    git_safety = source.get('template_origin_safety_contract', {})
    if git_safety.get('enabled') is not True:
        print('FAIL: template-origin safety contract is not enabled')
        return 1
    for key in ['inspect_git_remote_before_branch_commit_push_pr','no_pr_to_template_without_explicit_template_contribution_gate','no_push_without_publication_gate','release_or_deploy_requires_clean_synced_source']:
        if git_safety.get(key) is not True:
            print(f'FAIL: template-origin safety missing {key}=true')
            return 1
    for mode in ['improving_template','creating_user_project_from_template','existing_project_work']:
        if mode not in git_safety.get('classify_git_work_mode_before_publication', []):
            print('FAIL: git work mode missing ' + mode)
            return 1

    stage6_text = (ROOT/'source/stages/stage-6-saas-operator-kit.yaml').read_text(encoding='utf-8')
    stage6_recipe = json.loads((ROOT/'source/recipes/saas-operator-kit.json').read_text(encoding='utf-8'))
    for field in expected_intake_fields:
        if field not in stage6_text:
            print('FAIL: Stage 6 contract missing intake field ' + field)
            return 1
        if field not in stage6_recipe.get('project_intake_fields', []):
            print('FAIL: Stage 6 recipe missing intake field ' + field)
            return 1
    recipe_git = stage6_recipe.get('template_origin_safety', {})
    for key in ['inspect_git_remote_before_branch_commit_push_pr','no_pr_to_template_without_explicit_template_contribution_gate','no_push_without_publication_gate','release_or_deploy_requires_clean_synced_source']:
        if key not in stage6_text:
            print('FAIL: Stage 6 contract missing template-origin key ' + key)
            return 1
        if recipe_git.get(key) is not True:
            print('FAIL: Stage 6 recipe template-origin key not true: ' + key)
            return 1
    for mode in ['improving_template','creating_user_project_from_template','existing_project_work']:
        if mode not in stage6_text or mode not in recipe_git.get('work_modes', []):
            print('FAIL: Stage 6 template-origin work mode missing ' + mode)
            return 1

    acceptance = source.get('acceptance_contract', {})
    if acceptance.get('enabled') is not True or acceptance.get('required_for_non_trivial_packets') is not True:
        print('FAIL: acceptance contract must be enabled and required for non-trivial packets')
        return 1
    for field in ['primary_signal','pass_criteria','secondary_signals','evidence_required','cannot_claim_done_if']:
        if field not in acceptance.get('required_fields', []):
            print('FAIL: acceptance contract field missing ' + field)
            return 1

    isolation = source.get('local_pilot_isolation_contract', {})
    if isolation.get('enabled') is not True:
        print('FAIL: local pilot isolation contract is not enabled')
        return 1
    for key in ['test_data_only','forbid_prod_or_dev_database_in_tests','require_test_suffix_when_database_url_present','prefer_repo_derived_ports_for_parallel_checkouts','stop_not_repair_if_data_target_is_ambiguous']:
        if isolation.get(key) is not True:
            print(f'FAIL: local pilot isolation missing {key}=true')
            return 1

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
    for point in ['git publication gate','implementation gate','runtime/provider/secret/destructive-action gate','project intake gate','active/deferred surfaces choice','template-origin publication safety gate','acceptance contract review']:
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


    transition = source.get('wizard_room_transition_contract', {})
    if transition.get('enabled') is not True:
        print('FAIL: wizard room transition contract is not enabled')
        return 1
    for key in ['interaction_layer_only', 'not_a_new_stage', 'machine_stages_remain_authoritative', 'rooms_contract_required']:
        if transition.get(key) is not True:
            print(f'FAIL: wizard room transition contract missing {key}=true')
            return 1
    if transition.get('stage_count_must_remain') != len(source.get('stages', [])):
        print('FAIL: wizard room transition contract stage count guard mismatch')
        return 1
    if any(str(stage.get('id', '')).startswith('stage_14') for stage in source.get('stages', [])):
        print('FAIL: wizard room transition UX must not introduce Stage 14')
        return 1
    required_actions = [
        'enter_room',
        'complete_room',
        'pause',
        'inspect_evidence',
        'continue_to_next_room',
        'retry_or_repair',
    ]
    if transition.get('required_transition_actions') != required_actions:
        print('FAIL: wizard room transition actions mismatch')
        return 1
    prompt_contract = transition.get('prompt_contract', {})
    for key in [
        'clarify_tool_required_when_available',
        'choices_must_be_tool_choices_array',
        'question_must_not_embed_options',
        'plain_text_choices_are_fallback_only',
        'timeout_is_not_approval',
    ]:
        if prompt_contract.get(key) is not True:
            print(f'FAIL: wizard room prompt contract missing {key}=true')
            return 1
    max_choices = prompt_contract.get('max_choices_per_prompt')
    if max_choices != 4:
        print('FAIL: wizard room max choices must be 4')
        return 1
    templates = transition.get('prompt_templates', {})
    expected_templates = ['room_entry', 'room_completion', 'blocked_room', 'final_room_completion']
    if list(templates.keys()) != expected_templates:
        print('FAIL: wizard room prompt templates/order mismatch')
        return 1
    covered_actions = set()
    for template_id, template in templates.items():
        choices = template.get('choices', [])
        action_map = template.get('action_map', {})
        if not template.get('question_purpose'):
            print(f'FAIL: wizard room prompt template missing purpose: {template_id}')
            return 1
        if not choices or len(choices) > max_choices:
            print(f'FAIL: wizard room prompt template invalid choices count: {template_id}')
            return 1
        if set(choices) != set(action_map.keys()):
            print(f'FAIL: wizard room prompt template choices/action_map mismatch: {template_id}')
            return 1
        for action in action_map.values():
            if action not in required_actions:
                print(f'FAIL: wizard room prompt template unknown action {action}')
                return 1
            covered_actions.add(action)
    if not set(required_actions).issubset(covered_actions):
        print('FAIL: not all wizard room transition actions are covered by prompt templates')
        return 1
    room_transitions = transition.get('room_transitions', [])
    room_ids = [room.get('id') for room in rooms]
    if [item.get('room_id') for item in room_transitions] != room_ids:
        print('FAIL: wizard room transition map must preserve room order')
        return 1
    for index, item in enumerate(room_transitions):
        for key in ['entry_prompt_template', 'completion_prompt_template', 'blocked_prompt_template']:
            if item.get(key) not in templates:
                print(f'FAIL: wizard room transition map references missing template {item.get(key)}')
                return 1
        expected_next = None if index == len(room_ids) - 1 else room_ids[index + 1]
        if item.get('next_room_id') != expected_next:
            print('FAIL: wizard room transition next_room_id mismatch')
            return 1
        if item.get('continues_to_next_room') is not (expected_next is not None):
            print('FAIL: wizard room transition continues_to_next_room mismatch')
            return 1
    for needle,label in [
        ('Wizard Room Transition UX','wizard room transition section'),
        ('not Stage 14','no Stage 14 marker'),
        ('Required transition actions','transition action list'),
        ('room_entry','room entry prompt template'),
        ('room_completion','room completion prompt template'),
        ('blocked_room','blocked room prompt template'),
        ('final_room_completion','final room completion prompt template'),
        ('Timeout or silence is not approval','timeout is not approval marker'),
    ]:
        require(run, needle, label)


    demo = source.get('first_run_demo_contract', {})
    if demo.get('enabled') is not True:
        print('FAIL: first-run demo contract is not enabled')
        return 1
    for key in ['demo_is_self_test_only', 'not_a_new_stage', 'machine_stages_remain_authoritative', 'uses_wizard_rooms', 'uses_wizard_room_transition_contract']:
        if demo.get(key) is not True:
            print(f'FAIL: first-run demo contract missing {key}=true')
            return 1
    self_test_command = demo.get('self_test_command', '')
    for needle in ['scripts/install_launchroom_profile.ps1', '-TestOutputRoot', '-NoInventory', '-NoToolsets']:
        if needle not in self_test_command:
            print(f'FAIL: first-run demo self-test command missing {needle}')
            return 1
    forbidden_command_fragments = ['hermes profile create', 'hermes config set', 'hermes tools enable']
    for fragment in forbidden_command_fragments:
        if fragment in self_test_command:
            print(f'FAIL: first-run demo self-test command must not call {fragment}')
            return 1
    safety = demo.get('self_test_safety_markers', {})
    for key in [
        'uses_test_output_root',
        'must_not_call_hermes_profile_create',
        'must_not_call_hermes_config_set',
        'must_not_call_hermes_tools_enable',
        'must_not_read_or_write_secrets',
        'safe_to_run_in_ci',
    ]:
        if safety.get(key) is not True:
            print(f'FAIL: first-run demo safety marker missing {key}=true')
            return 1
    demo_path = demo.get('demo_path', [])
    expected_step_ids = [
        'demo_1_prepare_repo',
        'demo_2_run_self_test',
        'demo_3_enter_foundation_room',
        'demo_4_inspect_foundation_evidence',
        'demo_5_continue_to_capability_room',
        'demo_6_stop_at_gated_decision',
    ]
    if [step.get('step_id') for step in demo_path] != expected_step_ids:
        print('FAIL: first-run demo path step ids/order mismatch')
        return 1
    allowed_demo_actions = set(['prepare_repo', 'run_self_test'] + required_actions)
    room_ids_set = set(room_ids)
    for step in demo_path:
        if step.get('action') not in allowed_demo_actions:
            print('FAIL: first-run demo path uses unknown action ' + str(step.get('action')))
            return 1
        room_id = step.get('room_id')
        if room_id is not None and room_id not in room_ids_set:
            print('FAIL: first-run demo path references unknown room ' + str(room_id))
            return 1
        if not step.get('user_visible_text') or not step.get('expected_evidence'):
            print('FAIL: first-run demo path step missing user-visible text or expected evidence')
            return 1
    outputs = demo.get('expected_self_test_outputs', [])
    for needle in ['profile SOUL.md', 'profile LAUNCHROOM_PROFILE_CONTRACT.yaml', 'workspace README.md', 'workspace AGENTS.md', 'workspace HERMES.md', 'LaunchRoom starter skill pack']:
        if not any(needle in output for output in outputs):
            print('FAIL: first-run demo expected output missing ' + needle)
            return 1
    checklist = demo.get('user_visible_checklist', [])
    for needle in ['5 Wizard Rooms', 'room transition choices', 'self-test files', 'gated']:
        if not any(needle.lower() in item.lower() for item in checklist):
            print('FAIL: first-run demo user-visible checklist missing ' + needle)
            return 1
    gated = demo.get('stop_before_gated_actions', [])
    for action in ['software_install', 'gateway_setup_or_pairing', 'provider_or_model_runtime_change', 'cloud_or_vps_mutation', 'n8n_mutation', 'git_publication_or_release', 'secret_readback_or_storage', 'implementation_execution']:
        if action not in gated:
            print('FAIL: first-run demo stop-before gated action missing ' + action)
            return 1
    for needle,label in [
        ('First-run Demo / Self-test Scenario','first-run demo section'),
        ('This scenario demonstrates LaunchRoom Starter as a beginner-safe onboarding wizard','demo purpose marker'),
        ('### Self-test command','self-test command section'),
        ('-TestOutputRoot','self-test output root marker'),
        ('### Demo path','demo path section'),
        ('demo_3_enter_foundation_room','foundation room demo step'),
        ('demo_5_continue_to_capability_room','capability room demo step'),
        ('### Expected self-test outputs','expected outputs section'),
        ('### What the user should see','user-visible checklist section'),
        ('### Stop before gated actions','gated stop section'),
        ('implementation_execution','implementation gated stop marker'),
    ]:
        require(run, needle, label)


    release = source.get('release_distribution_readiness_contract', {})
    if release.get('enabled') is not True:
        print('FAIL: release/distribution readiness contract is not enabled')
        return 1
    for key in [
        'readiness_only_not_publication',
        'public_test_package',
        'not_airmida_authority',
        'no_release_or_tag_without_owner_gate',
        'no_distribution_channel_mutation_without_owner_gate',
        'no_runtime_provider_gateway_n8n_cloud_mutation',
    ]:
        if release.get(key) is not True:
            print(f'FAIL: release/distribution readiness missing {key}=true')
            return 1
    release_gate_required = release.get('release_gate_required_for', [])
    for needle in ['GitHub release creation', 'git tag creation or push', 'package registry publication', 'website/public landing page publication', 'Cloudflare/Hetzner/n8n mutation', 'secret collection, readback, or storage']:
        if needle not in release_gate_required:
            print('FAIL: release gate required list missing ' + needle)
            return 1
    quickstart = release.get('distribution_quickstart', [])
    expected_dist_steps = [
        'dist_1_read_repository_front_page',
        'dist_2_open_canonical_runbook',
        'dist_3_run_safe_self_test',
        'dist_4_run_primary_installer_after_choice',
        'dist_5_stop_at_release_gate',
    ]
    if [step.get('step_id') for step in quickstart] != expected_dist_steps:
        print('FAIL: release distribution quickstart step ids/order mismatch')
        return 1
    for step in quickstart:
        for key in ['surface', 'user_action', 'expected_result']:
            if not step.get(key):
                print(f'FAIL: release distribution quickstart step missing {key}')
                return 1
    manifest = release.get('artifact_manifest', [])
    manifest_paths = [item.get('path') for item in manifest]
    required_paths = [
        'README.md',
        'RUN_ME_FIRST.md',
        'generated/RUN_ME_FIRST.md',
        'source/launchroom.starter.v0_5.json',
        'contracts/launchroom-stage-contract.json',
        'scripts/install_launchroom_profile.ps1',
        'scripts/build_agentpack.py',
        'scripts/validate_behavior_contract.py',
        'scripts/validate_profile_setup_tool.py',
        'scripts/validate_product_e2e_readiness.py',
        'profile-distribution/launchroom-saas',
    ]
    if manifest_paths != required_paths:
        print('FAIL: release artifact manifest path/order mismatch')
        return 1
    for item in manifest:
        if item.get('required') is not True or not item.get('role'):
            print('FAIL: release artifact manifest item missing required=true or role')
            return 1
    checklist = release.get('release_readiness_checklist', [])
    for needle in ['README', 'RUN_ME_FIRST', 'Source and generated contracts', 'Artifact manifest', 'Validation commands', 'Secret-handling rules', 'No GitHub release']:
        if not any(needle.lower() in item.lower() for item in checklist):
            print('FAIL: release readiness checklist missing ' + needle)
            return 1
    blocked = release.get('blocked_until_separate_release_gate', [])
    for action in ['git_tag_creation', 'git_tag_push', 'github_release_creation', 'package_registry_publication', 'public_website_or_landing_page_publication', 'distribution_broadcast_to_channels', 'provider_or_model_runtime_change', 'gateway_pairing_or_home_channel_change', 'cloudflare_hetzner_n8n_mutation', 'secret_collection_readback_or_storage']:
        if action not in blocked:
            print('FAIL: release blocked action missing ' + action)
            return 1
    readme = (ROOT / 'README.md').read_text(encoding='utf-8')
    for needle,label in [
        ('## Quickstart','README quickstart'),
        ('## Distribution artifact manifest','README artifact manifest'),
        ('## Release boundary','README release boundary'),
        ('Release/distribution readiness is not release execution','README no release execution marker'),
        ('GitHub release creation','README GitHub release gate'),
        ('Cloudflare, Hetzner, or n8n mutation','README runtime gate'),
        ('secret collection, readback, or storage','README secret gate'),
        ('python scripts/validate_execution_evidence_binder.py','README full validator list'),
    ]:
        if needle not in readme:
            print(f'FAIL: missing {label}')
            return 1
    for needle,label in [
        ('Release / Distribution Readiness','release readiness section'),
        ('readiness only','readiness only marker'),
        ('### Distribution quickstart','distribution quickstart section'),
        ('dist_3_run_safe_self_test','safe self-test distribution step'),
        ('dist_5_stop_at_release_gate','release gate stop step'),
        ('### Artifact manifest','artifact manifest section'),
        ('### Release readiness checklist','release readiness checklist section'),
        ('### Blocked until separate owner release gate','blocked release gate section'),
        ('github_release_creation','github release blocked marker'),
        ('secret_collection_readback_or_storage','secret blocked marker'),
        ('Release readiness is not release execution','not release execution marker'),
    ]:
        require(run, needle, label)
    print('validate_behavior_contract: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
