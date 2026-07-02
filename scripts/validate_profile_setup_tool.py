#!/usr/bin/env python3
from __future__ import annotations
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'scripts' / 'install_launchroom_profile.ps1'
DIST = ROOT / 'profile-distribution' / 'launchroom-saas'

SECRET_PATTERNS = {
    'openai_key': re.compile(r'sk-[A-Za-z0-9_-]{20,}'),
    'github_token': re.compile(r'gh[pousr]_[A-Za-z0-9_]{20,}'),
    'jwt': re.compile(r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'),
    'private_key': re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'telegram_token': re.compile(r'\b\d{6,}:[A-Za-z0-9_-]{20,}\b'),
}


def require(text: str, needle: str, label: str) -> None:
    if needle.lower() not in text.lower():
        print(f'FAIL: missing {label}: {needle}')
        raise SystemExit(1)


def find_powershell() -> str | None:
    for candidate in ('pwsh', 'powershell.exe', 'powershell'):
        found = shutil.which(candidate)
        if found:
            return found
    return None


def run_self_test_if_available() -> None:
    ps = find_powershell()
    if not ps:
        print('validate_profile_setup_tool: self-test skipped (PowerShell not available)')
        return
    with tempfile.TemporaryDirectory(prefix='launchroom-installer-selftest-') as tmp:
        tmp_path = Path(tmp)
        args = [
            ps,
            '-NoProfile',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            str(SCRIPT),
            '-ProfileName',
            'launchroom-selftest',
            '-ProjectName',
            'LaunchRoom Self Test',
            '-UserLanguage',
            'auto',
            '-TestOutputRoot',
            str(tmp_path),
            '-Yes',
            '-NoToolsets',
        ]
        result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=120)
        if result.returncode != 0:
            print('FAIL: installer self-test failed')
            print(result.stdout)
            print(result.stderr)
            raise SystemExit(1)
        output = result.stdout + result.stderr
        for forbidden in ['config set ', 'Creating Hermes profile:', 'toolset enabled:']:
            if forbidden.lower() in output.lower():
                print(f'FAIL: self-test output suggests live mutation: {forbidden}')
                raise SystemExit(1)
        if re.search(r'(?m)^status: BLOCKED$', output):
            print('FAIL: installer self-test reported BLOCKED; expected PARTIAL/PASS for generated self-test output')
            print(output)
            raise SystemExit(1)
        if not re.search(r'(?m)^status: PARTIAL$', output) and not re.search(r'(?m)^status: PASS$', output):
            print('FAIL: installer self-test did not report final PARTIAL or PASS status')
            print(output)
            raise SystemExit(1)
        profile_root = tmp_path / 'profiles' / 'launchroom-selftest'
        workspace_root = tmp_path / 'workspace' / 'launchroom-selftest'
        required = [
            profile_root / 'config.yaml',
            profile_root / 'SOUL.md',
            profile_root / 'PROFILE_INSTRUCTIONS.md',
            profile_root / 'LAUNCHROOM_PROFILE_CONTRACT.yaml',
            profile_root / '.env.EXAMPLE',
            profile_root / 'reports' / 'profile-foundation-report.yaml',
            profile_root / 'reports' / 'profile-apply-plan.yaml',
            profile_root / 'reports' / 'stage-1-selected-settings.yaml',
            profile_root / 'reports' / 'config.yaml.draft',
            profile_root / 'skills' / 'launchroom' / 'launchroom-profile-operator' / 'SKILL.md',
            profile_root / 'skills' / 'launchroom' / 'launchroom-hermes-settings-guide' / 'SKILL.md',
            profile_root / 'skills' / 'launchroom' / 'launchroom-saas-operator' / 'SKILL.md',
            workspace_root / 'AGENTS.md',
            workspace_root / 'HERMES.md',
            workspace_root / '.hermes' / 'reports' / 'workspace-onboarding-report.yaml',
            workspace_root / '.hermes' / 'reports' / 'software-inventory-report.yaml',
            workspace_root / '.hermes' / 'reports' / 'software-purpose-map.yaml',
            workspace_root / '.hermes' / 'reports' / 'software-install-recommendation.yaml',
            workspace_root / '.hermes' / 'reports' / 'capability-graph.yaml',
            workspace_root / '.hermes' / 'reports' / 'starter-capability-pack.yaml',
            workspace_root / '.hermes' / 'reports' / 'communication-channel-map.yaml',
            workspace_root / '.hermes' / 'reports' / 'communication-user-guide.md',
            workspace_root / '.hermes' / 'operator-kit' / 'START_HERE.md',
            workspace_root / '.hermes' / 'operator-kit' / 'NEXT_DECISION.md',
            workspace_root / '.hermes' / 'operator-kit' / 'CHECK_IT_WORKS.md',
            workspace_root / '.hermes' / 'operator-kit' / 'PAIN_TO_WORKFLOW_EXAMPLES.md',
            workspace_root / '.hermes' / 'operator-kit' / 'product_brief.md',
            workspace_root / '.hermes' / 'operator-kit' / 'target_user.md',
            workspace_root / '.hermes' / 'operator-kit' / 'first_workflow.md',
            workspace_root / '.hermes' / 'operator-kit' / 'backlog.md',
            workspace_root / '.hermes' / 'operator-kit' / 'local_task_packet.md',
            workspace_root / '.hermes' / 'operator-kit' / 'gates.md',
            workspace_root / '.hermes' / 'operator-kit' / 'readiness_report.yaml',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'SESSION_STATE.yaml',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'AGENT_GUIDE.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'USER_LESSON.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'IDEA_INTAKE.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'PROJECT_BLUEPRINT.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'FIRST_SLICE_PACKET.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'DEFAULT_WORKFLOW_CATALOG.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'IMPLEMENTATION_ROADMAP.md',
            workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / 'COMPLETION_SUMMARY.md',
            workspace_root / '.hermes' / 'first-slice' / 'START_HERE.md',
            workspace_root / '.hermes' / 'first-slice' / 'IMPLEMENTATION_BRIEF.md',
            workspace_root / '.hermes' / 'first-slice' / 'LOCAL_PILOT_PLAN.md',
            workspace_root / '.hermes' / 'first-slice' / 'ACCEPTANCE_TESTS.md',
            workspace_root / '.hermes' / 'first-slice' / 'USER_DEMO_SCRIPT.md',
            workspace_root / '.hermes' / 'first-slice' / 'RISKS_AND_ROLLBACK.md',
            workspace_root / '.hermes' / 'first-slice' / 'DECISION_GATE.md',
            workspace_root / '.hermes' / 'first-slice' / 'READINESS_REPORT.yaml',
            workspace_root / '.hermes' / 'local-pilot' / 'START_HERE.md',
            workspace_root / '.hermes' / 'local-pilot' / 'EXECUTION_PACKET.md',
            workspace_root / '.hermes' / 'local-pilot' / 'FILE_CHANGE_PLAN.md',
            workspace_root / '.hermes' / 'local-pilot' / 'COMMAND_PLAN.md',
            workspace_root / '.hermes' / 'local-pilot' / 'TEST_PLAN.md',
            workspace_root / '.hermes' / 'local-pilot' / 'EVIDENCE_LOG.md',
            workspace_root / '.hermes' / 'local-pilot' / 'REVIEW_CHECKLIST.md',
            workspace_root / '.hermes' / 'local-pilot' / 'HANDOFF_SUMMARY.md',
            workspace_root / '.hermes' / 'local-pilot' / 'READINESS_REPORT.yaml',
            workspace_root / '.hermes' / 'project-audit' / 'START_HERE.md',
            workspace_root / '.hermes' / 'project-audit' / 'PLAN_INTEGRITY_REPORT.md',
            workspace_root / '.hermes' / 'project-audit' / 'EXPECTED_RESULT_MAP.md',
            workspace_root / '.hermes' / 'project-audit' / 'MISSING_FRAGMENTS.md',
            workspace_root / '.hermes' / 'project-audit' / 'CONTRADICTION_SCAN.md',
            workspace_root / '.hermes' / 'project-audit' / 'STAGE_DRIFT_SCAN.md',
            workspace_root / '.hermes' / 'project-audit' / 'ASSUMPTION_REGISTER.md',
            workspace_root / '.hermes' / 'project-audit' / 'IMPLEMENTATION_BLOCKERS.md',
            workspace_root / '.hermes' / 'project-audit' / 'REPAIR_RECOMMENDATIONS.md',
            workspace_root / '.hermes' / 'project-audit' / 'AUDIT_REPORT.yaml',
            workspace_root / '.hermes' / 'agent-readiness' / 'START_HERE.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'PROJECT_TOOLCHAIN_REQUIREMENTS.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'SOFTWARE_GAP_ANALYSIS.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'HERMES_TOOLSET_PLAN.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'SKILL_LOAD_PLAN.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'AGENT_PIPELINE_PLAN.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'INSTALL_PLAN.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'COMMAND_READINESS.md',
            workspace_root / '.hermes' / 'agent-readiness' / 'EXECUTION_READINESS_REPORT.yaml',
            workspace_root / '.hermes' / 'hygiene' / 'START_HERE.md',
            workspace_root / '.hermes' / 'hygiene' / 'ARTIFACT_INDEX.md',
            workspace_root / '.hermes' / 'hygiene' / 'ACTIVE_FILES.md',
            workspace_root / '.hermes' / 'hygiene' / 'SUPERSEDED_FILES.md',
            workspace_root / '.hermes' / 'hygiene' / 'BROKEN_OR_STALE_FILES.md',
            workspace_root / '.hermes' / 'hygiene' / 'DO_NOT_USE.md',
            workspace_root / '.hermes' / 'hygiene' / 'CLEANUP_PLAN.md',
            workspace_root / '.hermes' / 'hygiene' / 'ARCHIVE_PLAN.md',
            workspace_root / '.hermes' / 'hygiene' / 'DELETION_GATE.md',
            workspace_root / '.hermes' / 'hygiene' / 'HYGIENE_REPORT.yaml',
            workspace_root / '.hermes' / 'skills' / 'START_HERE.md',
            workspace_root / '.hermes' / 'skills' / 'STAGE_SKILL_MATRIX.md',
            workspace_root / '.hermes' / 'skills' / 'REQUIRED_SKILLS.md',
            workspace_root / '.hermes' / 'skills' / 'OPTIONAL_SKILLS.md',
            workspace_root / '.hermes' / 'skills' / 'MISSING_SKILLS.md',
            workspace_root / '.hermes' / 'skills' / 'SKILL_CAPTURE_GUIDE.md',
            workspace_root / '.hermes' / 'skills' / 'SKILL_CANDIDATE_TEMPLATE.md',
            workspace_root / '.hermes' / 'skills' / 'SKILL_PROMOTION_GATE.md',
            workspace_root / '.hermes' / 'skills' / 'SKILL_INTEGRATION_REPORT.yaml',
            workspace_root / '.hermes' / 'skills-candidates' / 'README.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'START_HERE.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'EXECUTED_COMMANDS.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'CHANGED_FILES.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'TEST_RESULTS.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'ACCEPTANCE_EVIDENCE.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'USER_VISIBLE_RESULT.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'RESIDUAL_RISKS.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'ROLLBACK_AND_HANDOFF.md',
            workspace_root / '.hermes' / 'execution-evidence' / 'EXECUTION_EVIDENCE_REPORT.yaml',
        ]
        missing = [str(p.relative_to(tmp_path)) for p in required if not p.exists()]
        if missing:
            print('FAIL: self-test missing generated files: ' + ', '.join(missing))
            raise SystemExit(1)
        yaml.safe_load((profile_root / 'config.yaml').read_text(encoding='utf-8'))
        yaml.safe_load((profile_root / 'LAUNCHROOM_PROFILE_CONTRACT.yaml').read_text(encoding='utf-8'))
        yaml.safe_load((profile_root / 'reports' / 'profile-foundation-report.yaml').read_text(encoding='utf-8'))
        workspace_report = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'workspace-onboarding-report.yaml').read_text(encoding='utf-8'))
        if workspace_report.get('stage_id') != 'stage_2_workspace_project_onboarding':
            print('FAIL: self-test workspace onboarding report has wrong stage_id')
            raise SystemExit(1)
        if workspace_report.get('boundaries', {}).get('secrets_read') is not False:
            print('FAIL: self-test workspace onboarding report does not assert secrets_read=false')
            raise SystemExit(1)
        inventory_report = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'software-inventory-report.yaml').read_text(encoding='utf-8'))
        purpose_map = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'software-purpose-map.yaml').read_text(encoding='utf-8'))
        install_rec = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'software-install-recommendation.yaml').read_text(encoding='utf-8'))
        capability_graph = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'capability-graph.yaml').read_text(encoding='utf-8'))
        starter_pack = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'starter-capability-pack.yaml').read_text(encoding='utf-8'))
        communication_map = yaml.safe_load((workspace_root / '.hermes' / 'reports' / 'communication-channel-map.yaml').read_text(encoding='utf-8'))
        communication_guide = (workspace_root / '.hermes' / 'reports' / 'communication-user-guide.md').read_text(encoding='utf-8')
        operator_readiness = yaml.safe_load((workspace_root / '.hermes' / 'operator-kit' / 'readiness_report.yaml').read_text(encoding='utf-8'))
        operator_text = '\n'.join((workspace_root / '.hermes' / 'operator-kit' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','NEXT_DECISION.md','CHECK_IT_WORKS.md','PAIN_TO_WORKFLOW_EXAMPLES.md','product_brief.md','target_user.md','first_workflow.md','backlog.md','local_task_packet.md','gates.md'])
        guided_text = '\n'.join((workspace_root / '.hermes' / 'operator-kit' / 'guided-session' / name).read_text(encoding='utf-8') for name in ['SESSION_STATE.yaml','AGENT_GUIDE.md','USER_LESSON.md','IDEA_INTAKE.md','PROJECT_BLUEPRINT.md','FIRST_SLICE_PACKET.md','DEFAULT_WORKFLOW_CATALOG.md','IMPLEMENTATION_ROADMAP.md','COMPLETION_SUMMARY.md'])
        first_slice_readiness = yaml.safe_load((workspace_root / '.hermes' / 'first-slice' / 'READINESS_REPORT.yaml').read_text(encoding='utf-8'))
        first_slice_text = '\n'.join((workspace_root / '.hermes' / 'first-slice' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','IMPLEMENTATION_BRIEF.md','LOCAL_PILOT_PLAN.md','ACCEPTANCE_TESTS.md','USER_DEMO_SCRIPT.md','RISKS_AND_ROLLBACK.md','DECISION_GATE.md'])
        local_pilot_readiness = yaml.safe_load((workspace_root / '.hermes' / 'local-pilot' / 'READINESS_REPORT.yaml').read_text(encoding='utf-8'))
        local_pilot_text = '\n'.join((workspace_root / '.hermes' / 'local-pilot' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','EXECUTION_PACKET.md','FILE_CHANGE_PLAN.md','COMMAND_PLAN.md','TEST_PLAN.md','EVIDENCE_LOG.md','REVIEW_CHECKLIST.md','HANDOFF_SUMMARY.md'])
        project_audit_report = yaml.safe_load((workspace_root / '.hermes' / 'project-audit' / 'AUDIT_REPORT.yaml').read_text(encoding='utf-8'))
        project_audit_text = '\n'.join((workspace_root / '.hermes' / 'project-audit' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','PLAN_INTEGRITY_REPORT.md','EXPECTED_RESULT_MAP.md','MISSING_FRAGMENTS.md','CONTRADICTION_SCAN.md','STAGE_DRIFT_SCAN.md','ASSUMPTION_REGISTER.md','IMPLEMENTATION_BLOCKERS.md','REPAIR_RECOMMENDATIONS.md'])
        agent_readiness_report = yaml.safe_load((workspace_root / '.hermes' / 'agent-readiness' / 'EXECUTION_READINESS_REPORT.yaml').read_text(encoding='utf-8'))
        agent_readiness_text = '\n'.join((workspace_root / '.hermes' / 'agent-readiness' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','PROJECT_TOOLCHAIN_REQUIREMENTS.md','SOFTWARE_GAP_ANALYSIS.md','HERMES_TOOLSET_PLAN.md','SKILL_LOAD_PLAN.md','AGENT_PIPELINE_PLAN.md','INSTALL_PLAN.md','COMMAND_READINESS.md','EXECUTION_READINESS_REPORT.yaml'])
        hygiene_report = yaml.safe_load((workspace_root / '.hermes' / 'hygiene' / 'HYGIENE_REPORT.yaml').read_text(encoding='utf-8'))
        hygiene_text = '\n'.join((workspace_root / '.hermes' / 'hygiene' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','ARTIFACT_INDEX.md','ACTIVE_FILES.md','SUPERSEDED_FILES.md','BROKEN_OR_STALE_FILES.md','DO_NOT_USE.md','CLEANUP_PLAN.md','ARCHIVE_PLAN.md','DELETION_GATE.md','HYGIENE_REPORT.yaml'])
        skill_integration_report = yaml.safe_load((workspace_root / '.hermes' / 'skills' / 'SKILL_INTEGRATION_REPORT.yaml').read_text(encoding='utf-8'))
        skill_text = '\n'.join((workspace_root / '.hermes' / 'skills' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','STAGE_SKILL_MATRIX.md','REQUIRED_SKILLS.md','OPTIONAL_SKILLS.md','MISSING_SKILLS.md','SKILL_CAPTURE_GUIDE.md','SKILL_CANDIDATE_TEMPLATE.md','SKILL_PROMOTION_GATE.md','SKILL_INTEGRATION_REPORT.yaml']) + '\n' + (workspace_root / '.hermes' / 'skills-candidates' / 'README.md').read_text(encoding='utf-8')
        execution_evidence_report = yaml.safe_load((workspace_root / '.hermes' / 'execution-evidence' / 'EXECUTION_EVIDENCE_REPORT.yaml').read_text(encoding='utf-8'))
        execution_evidence_text = '\n'.join((workspace_root / '.hermes' / 'execution-evidence' / name).read_text(encoding='utf-8') for name in ['START_HERE.md','EXECUTED_COMMANDS.md','CHANGED_FILES.md','TEST_RESULTS.md','ACCEPTANCE_EVIDENCE.md','USER_VISIBLE_RESULT.md','RESIDUAL_RISKS.md','ROLLBACK_AND_HANDOFF.md','EXECUTION_EVIDENCE_REPORT.yaml'])
        if inventory_report.get('stage_id') != 'stage_3_tool_readiness':
            print('FAIL: self-test software inventory has wrong stage_id')
            raise SystemExit(1)
        for tool in ['hermes','python','git','node','npm','ripgrep','uv','winget','docker','wsl']:
            entry = purpose_map.get('tools', {}).get(tool)
            if not entry or not entry.get('purpose') or not entry.get('agent_use'):
                print('FAIL: self-test software purpose map missing purpose/agent_use for ' + tool)
                raise SystemExit(1)
        if install_rec.get('install_gate_required') is not True or install_rec.get('installs_executed') is not False:
            print('FAIL: self-test install recommendation does not enforce gate/no-install')
            raise SystemExit(1)
        required_task_classes = [
            'profile_and_workspace_setup', 'code_change_delivery', 'research_and_evidence',
            'external_agent_handoff', 'web_browser_qa', 'cloud_runtime_readiness',
            'communication_gateway_readiness', 'observability_and_reports', 'security_and_secret_safety',
        ]
        if capability_graph.get('artifact_id') != 'LAUNCHROOM_ENGINEERING_CAPABILITY_GRAPH_v0_1':
            print('FAIL: self-test capability graph has wrong artifact_id')
            raise SystemExit(1)
        task_classes = capability_graph.get('task_classes', {})
        for task_class in required_task_classes:
            entry = task_classes.get(task_class)
            if not entry:
                print('FAIL: self-test capability graph missing task class ' + task_class)
                raise SystemExit(1)
            for field in ['goal', 'required_tools', 'supporting_skills', 'workflow', 'gates', 'verification']:
                if field not in entry:
                    print(f'FAIL: self-test capability graph {task_class} missing {field}')
                    raise SystemExit(1)
        if 'select capability workflow before selecting individual software' not in capability_graph.get('selection_rule', ''):
            print('FAIL: self-test capability graph selection rule missing')
            raise SystemExit(1)
        if capability_graph.get('boundaries', {}).get('secrets_read') is not False:
            print('FAIL: self-test capability graph does not assert secrets_read=false')
            raise SystemExit(1)
        if starter_pack.get('artifact_id') != 'LAUNCHROOM_STARTER_CAPABILITY_PACK_v0_1':
            print('FAIL: self-test starter capability pack has wrong artifact_id')
            raise SystemExit(1)
        if starter_pack.get('stage_id') != 'stage_4_starter_capability_pack':
            print('FAIL: self-test starter capability pack has wrong stage_id')
            raise SystemExit(1)
        for task_class in required_task_classes:
            entry = starter_pack.get('task_classes', {}).get(task_class)
            if not entry:
                print('FAIL: self-test starter capability pack missing task class ' + task_class)
                raise SystemExit(1)
            for field in ['starter_toolsets', 'starter_skills', 'memory_policy', 'workflow_playbook', 'gates', 'verification']:
                if field not in entry:
                    print(f'FAIL: self-test starter capability pack {task_class} missing {field}')
                    raise SystemExit(1)
        actions = starter_pack.get('actions_executed', {})
        if actions.get('toolsets_enabled') is not False or actions.get('persistent_memory_written') is not False or actions.get('network_skills_installed') is not False:
            print('FAIL: self-test starter capability pack records unauthorized activation')
            raise SystemExit(1)
        boundaries = starter_pack.get('boundaries', {})
        for key in ['toolsets_enabled_without_gate', 'memory_written_without_gate', 'network_skills_installed_without_gate', 'runtime_mutation']:
            if boundaries.get(key) is not False:
                print('FAIL: self-test starter capability pack boundary not false: ' + key)
                raise SystemExit(1)
        if communication_map.get('artifact_id') != 'LAUNCHROOM_COMMUNICATION_CHANNEL_MAP_v0_1':
            print('FAIL: self-test communication channel map has wrong artifact_id')
            raise SystemExit(1)
        if communication_map.get('stage_id') != 'stage_5_communications':
            print('FAIL: self-test communication channel map has wrong stage_id')
            raise SystemExit(1)
        required_surfaces = ['desktop','telegram','slack','email','discord','teams_matrix_signal_whatsapp','webhooks_api']
        for surface in required_surfaces:
            entry = communication_map.get('communication_surfaces', {}).get(surface)
            if not entry:
                print('FAIL: self-test communication map missing surface ' + surface)
                raise SystemExit(1)
            for field in ['role','manager','best_for','real_options','official_sources','gates','verification']:
                if field not in entry:
                    print(f'FAIL: self-test communication map {surface} missing {field}')
                    raise SystemExit(1)
        comm_actions = communication_map.get('actions_executed', {})
        for key in ['gateway_setup','pairing_approved','home_channel_set','gateway_autostart_installed','test_message_sent','secrets_read_or_written']:
            if comm_actions.get(key) is not False:
                print('FAIL: self-test communication action not false: ' + key)
                raise SystemExit(1)
        for manager in ['hermes_desktop','hermes_gateway_telegram','hermes_gateway_slack','hermes_gateway_email','hermes_gateway_discord','hermes_gateway_platform_adapter','hermes_webhook_or_api_server']:
            if manager not in communication_map.get('channel_managers', []):
                print('FAIL: self-test communication map missing manager ' + manager)
                raise SystemExit(1)
        for needle in ['Hermes Desktop','Telegram','Slack','Email','Discord','Webhooks / API','Safe secret-entry rule','https://hermes-agent.nousresearch.com/docs/user-guide/messaging/','https://core.telegram.org/bots/api','https://api.slack.com/apis/connections/socket']:
            if needle not in communication_guide:
                print('FAIL: self-test communication guide missing ' + needle)
                raise SystemExit(1)
        if operator_readiness.get('artifact_id') != 'LAUNCHROOM_SAAS_OPERATOR_KIT_READINESS_v0_1':
            print('FAIL: self-test operator readiness has wrong artifact_id')
            raise SystemExit(1)
        if operator_readiness.get('stage_id') != 'stage_6_saas_operator_kit':
            print('FAIL: self-test operator readiness has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in operator_readiness.get('status_marker',''):
            print('FAIL: self-test operator readiness missing non-authority marker')
            raise SystemExit(1)
        action_flags = operator_readiness.get('action_flags', {})
        for key in ['runtime_mutation','cloud_mutation','n8n_mutation','gateway_mutation','git_publication_executed','secrets_read_or_written','implementation_executed']:
            if action_flags.get(key) is not False:
                print('FAIL: self-test operator kit action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['beginner_next_decision_present','pain_to_workflow_examples_present','guided_session_present','no_idea_default_workflow_catalog_present','blueprint_to_solution_path_present']:
            if action_flags.get(key) is not True:
                print('FAIL: self-test operator kit navigation flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Hermes working artifact / not AIRMIDA authority','intent -> scope -> evidence -> structure -> delivery packet -> execution -> verification -> handoff -> next decision','implementation_gate','runtime_provider_gate','secret_readback','Done when','Stage 6','Check It Works','Pain to Workflow Examples','Recommended beginner path','Show me 3 first workflow options','Which one small pain do I want the agent to help solve first']:
            if needle not in operator_text:
                print('FAIL: self-test operator kit text missing ' + needle)
                raise SystemExit(1)
        for needle in ['agent must lead','DEFAULT_WORKFLOW_CATALOG.md','messenger setup','Telegram or Discord channel management','Email, calendar, and notes assistant','PROJECT_BLUEPRINT.md','FIRST_SLICE_PACKET.md','IMPLEMENTATION_ROADMAP.md','blueprint -> first slice packet -> implementation plan -> local pilot -> verification -> next gate','working result']:
            if needle not in guided_text:
                print('FAIL: self-test guided session text missing ' + needle)
                raise SystemExit(1)
        if first_slice_readiness.get('artifact_id') != 'LAUNCHROOM_FIRST_SLICE_READINESS_v0_1':
            print('FAIL: self-test first slice readiness has wrong artifact_id')
            raise SystemExit(1)
        if first_slice_readiness.get('stage_id') != 'stage_7_first_slice_planning':
            print('FAIL: self-test first slice readiness has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in first_slice_readiness.get('status_marker',''):
            print('FAIL: self-test first slice readiness missing non-authority marker')
            raise SystemExit(1)
        first_slice_flags = first_slice_readiness.get('action_flags', {})
        for key in ['implementation_executed','dependencies_installed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if first_slice_flags.get(key) is not False:
                print('FAIL: self-test first slice action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['local_pilot_plan_present','acceptance_tests_present','user_demo_script_present','next_implementation_gate_present']:
            if first_slice_flags.get(key) is not True:
                print('FAIL: self-test first slice readiness flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['First Slice Planning','IMPLEMENTATION_BRIEF.md','LOCAL_PILOT_PLAN.md','ACCEPTANCE_TESTS.md','USER_DEMO_SCRIPT.md','DECISION_GATE.md','implementation_planning_gate','communication_channel_setup_gate','working result','No implementation before implementation_gate']:
            if needle not in first_slice_text:
                print('FAIL: self-test first slice text missing ' + needle)
                raise SystemExit(1)
        if local_pilot_readiness.get('artifact_id') != 'LAUNCHROOM_LOCAL_PILOT_EXECUTION_READINESS_v0_1':
            print('FAIL: self-test local pilot readiness has wrong artifact_id')
            raise SystemExit(1)
        if local_pilot_readiness.get('stage_id') != 'stage_8_local_pilot_execution_packet':
            print('FAIL: self-test local pilot readiness has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in local_pilot_readiness.get('status_marker',''):
            print('FAIL: self-test local pilot readiness missing non-authority marker')
            raise SystemExit(1)
        local_pilot_flags = local_pilot_readiness.get('action_flags', {})
        for key in ['implementation_executed','file_changes_executed','commands_executed','tests_executed','dependencies_installed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if local_pilot_flags.get(key) is not False:
                print('FAIL: self-test local pilot action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['execution_packet_present','file_change_plan_present','command_plan_present','test_plan_present','evidence_log_present','review_checklist_present','handoff_summary_present','next_execution_gate_present']:
            if local_pilot_flags.get(key) is not True:
                print('FAIL: self-test local pilot readiness flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Local Pilot Execution Packet','EXECUTION_PACKET.md','FILE_CHANGE_PLAN.md','COMMAND_PLAN.md','TEST_PLAN.md','EVIDENCE_LOG.md','REVIEW_CHECKLIST.md','HANDOFF_SUMMARY.md','Do not fabricate evidence','approve local implementation execution']:
            if needle not in local_pilot_text:
                print('FAIL: self-test local pilot text missing ' + needle)
                raise SystemExit(1)
        if project_audit_report.get('artifact_id') != 'LAUNCHROOM_PROJECT_PLAN_INTEGRITY_AUDIT_v0_1':
            print('FAIL: self-test project audit report has wrong artifact_id')
            raise SystemExit(1)
        if project_audit_report.get('stage_id') != 'stage_9_project_plan_integrity_audit':
            print('FAIL: self-test project audit report has wrong stage_id')
            raise SystemExit(1)
        if project_audit_report.get('execution_allowed') is not False:
            print('FAIL: self-test project audit execution_allowed is not false')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in project_audit_report.get('status_marker',''):
            print('FAIL: self-test project audit missing non-authority marker')
            raise SystemExit(1)
        project_audit_flags = project_audit_report.get('action_flags', {})
        for key in ['implementation_executed','file_changes_executed','commands_executed','tests_executed','dependencies_installed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if project_audit_flags.get(key) is not False:
                print('FAIL: self-test project audit action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['plan_integrity_report_present','expected_result_map_present','missing_fragments_report_present','contradiction_scan_present','stage_drift_scan_present','assumption_register_present','implementation_blockers_present','repair_recommendations_present']:
            if project_audit_flags.get(key) is not True:
                print('FAIL: self-test project audit readiness flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Project Plan Integrity','PLAN_INTEGRITY_REPORT.md','EXPECTED_RESULT_MAP.md','MISSING_FRAGMENTS.md','CONTRADICTION_SCAN.md','STAGE_DRIFT_SCAN.md','ASSUMPTION_REGISTER.md','IMPLEMENTATION_BLOCKERS.md','REPAIR_RECOMMENDATIONS.md','execution_allowed: false','Stage 10 readiness analysis']:
            if needle not in project_audit_text:
                print('FAIL: self-test project audit text missing ' + needle)
                raise SystemExit(1)
        if agent_readiness_report.get('artifact_id') != 'LAUNCHROOM_AGENT_EXECUTION_READINESS_v0_1':
            print('FAIL: self-test agent readiness report has wrong artifact_id')
            raise SystemExit(1)
        if agent_readiness_report.get('stage_id') != 'stage_10_agent_execution_readiness':
            print('FAIL: self-test agent readiness report has wrong stage_id')
            raise SystemExit(1)
        if agent_readiness_report.get('execution_ready') is not False or agent_readiness_report.get('execution_allowed') is not False:
            print('FAIL: self-test agent readiness does not block execution by default')
            raise SystemExit(1)
        if agent_readiness_report.get('install_gate_required') is not True:
            print('FAIL: self-test agent readiness does not require install gate')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in agent_readiness_report.get('status_marker',''):
            print('FAIL: self-test agent readiness missing non-authority marker')
            raise SystemExit(1)
        readiness_flags = agent_readiness_report.get('action_flags', {})
        for key in ['software_installed','toolsets_enabled_without_gate','skills_installed_without_gate','agents_spawned','implementation_executed','file_changes_executed','commands_executed','tests_executed','dependencies_installed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if readiness_flags.get(key) is not False:
                print('FAIL: self-test agent readiness action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['project_toolchain_requirements_present','software_gap_analysis_present','hermes_toolset_plan_present','skill_load_plan_present','agent_pipeline_plan_present','install_plan_present','command_readiness_present']:
            if readiness_flags.get(key) is not True:
                print('FAIL: self-test agent readiness flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Agent Execution Readiness','PROJECT_TOOLCHAIN_REQUIREMENTS.md','SOFTWARE_GAP_ANALYSIS.md','HERMES_TOOLSET_PLAN.md','SKILL_LOAD_PLAN.md','AGENT_PIPELINE_PLAN.md','INSTALL_PLAN.md','COMMAND_READINESS.md','execution_ready: false','install_gate_required','Toolchain Verifier','Node.js LTS + npm']:
            if needle not in agent_readiness_text:
                print('FAIL: self-test agent readiness text missing ' + needle)
                raise SystemExit(1)
        if hygiene_report.get('artifact_id') != 'LAUNCHROOM_WORKSPACE_HYGIENE_v0_1':
            print('FAIL: self-test hygiene report has wrong artifact_id')
            raise SystemExit(1)
        if hygiene_report.get('stage_id') != 'stage_11_workspace_hygiene':
            print('FAIL: self-test hygiene report has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in hygiene_report.get('status_marker',''):
            print('FAIL: self-test hygiene missing non-authority marker')
            raise SystemExit(1)
        hygiene_flags = hygiene_report.get('action_flags', {})
        for key in ['cleanup_executed','archive_executed','deletion_executed','files_deleted','files_moved','files_renamed','implementation_executed','commands_executed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if hygiene_flags.get(key) is not False:
                print('FAIL: self-test hygiene action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['artifact_index_present','active_files_present','superseded_files_present','broken_or_stale_files_present','do_not_use_present','cleanup_plan_present','archive_plan_present','deletion_gate_present']:
            if hygiene_flags.get(key) is not True:
                print('FAIL: self-test hygiene flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Workspace Hygiene','ARTIFACT_INDEX.md','ACTIVE_FILES.md','SUPERSEDED_FILES.md','BROKEN_OR_STALE_FILES.md','DO_NOT_USE.md','CLEANUP_PLAN.md','ARCHIVE_PLAN.md','DELETION_GATE.md','cleanup_executed: false','files_deleted: false','temporary self-test workspaces','No deletion candidate is approved']:
            if needle not in hygiene_text:
                print('FAIL: self-test hygiene text missing ' + needle)
                raise SystemExit(1)
        if skill_integration_report.get('artifact_id') != 'LAUNCHROOM_SKILL_INTEGRATION_v0_1':
            print('FAIL: self-test skill integration report has wrong artifact_id')
            raise SystemExit(1)
        if skill_integration_report.get('stage_id') != 'stage_12_skill_capture':
            print('FAIL: self-test skill integration report has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in skill_integration_report.get('status_marker',''):
            print('FAIL: self-test skill integration missing non-authority marker')
            raise SystemExit(1)
        skill_flags = skill_integration_report.get('action_flags', {})
        for key in ['skills_installed','skills_patched','skills_promoted','persistent_memory_written','skill_candidates_created','implementation_executed','commands_executed','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if skill_flags.get(key) is not False:
                print('FAIL: self-test skill integration action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['stage_skill_matrix_present','required_skills_present','optional_skills_present','missing_skills_present','skill_capture_guide_present','skill_candidate_template_present','skill_promotion_gate_present','skills_candidates_root_present']:
            if skill_flags.get(key) is not True:
                print('FAIL: self-test skill integration flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Skill Capture','STAGE_SKILL_MATRIX.md','REQUIRED_SKILLS.md','OPTIONAL_SKILLS.md','MISSING_SKILLS.md','SKILL_CAPTURE_GUIDE.md','SKILL_CANDIDATE_TEMPLATE.md','SKILL_PROMOTION_GATE.md','skills_installed: false','skills_promoted: false','persistent_memory_written: false','Do not treat a skill candidate as an active skill']:
            if needle not in skill_text:
                print('FAIL: self-test skill integration text missing ' + needle)
                raise SystemExit(1)
        if execution_evidence_report.get('artifact_id') != 'LAUNCHROOM_EXECUTION_EVIDENCE_BINDER_v0_1':
            print('FAIL: self-test execution evidence report has wrong artifact_id')
            raise SystemExit(1)
        if execution_evidence_report.get('stage_id') != 'stage_13_execution_evidence_binder':
            print('FAIL: self-test execution evidence report has wrong stage_id')
            raise SystemExit(1)
        if 'Hermes working artifact / not AIRMIDA authority' not in execution_evidence_report.get('status_marker',''):
            print('FAIL: self-test execution evidence missing non-authority marker')
            raise SystemExit(1)
        evidence_flags = execution_evidence_report.get('action_flags', {})
        for key in ['real_execution_evidence_present','fabricated_evidence','implementation_executed_by_stage13','commands_executed_by_stage13','file_changes_executed_by_stage13','tests_executed_by_stage13','dependencies_installed_by_stage13','runtime_mutation','cloud_mutation','gateway_mutation','n8n_mutation','secrets_read_or_written','git_publication_executed']:
            if evidence_flags.get(key) is not False:
                print('FAIL: self-test evidence action flag not false: ' + key)
                raise SystemExit(1)
        for key in ['executed_commands_present','changed_files_present','test_results_present','acceptance_evidence_present','user_visible_result_present','residual_risks_present','rollback_and_handoff_present']:
            if evidence_flags.get(key) is not True:
                print('FAIL: self-test evidence flag not true: ' + key)
                raise SystemExit(1)
        for needle in ['Local Execution Evidence Binder','EXECUTED_COMMANDS.md','CHANGED_FILES.md','TEST_RESULTS.md','ACCEPTANCE_EVIDENCE.md','USER_VISIBLE_RESULT.md','RESIDUAL_RISKS.md','ROLLBACK_AND_HANDOFF.md','real_execution_evidence_present: false','fabricated_evidence: false','Do not fabricate evidence','No project tests have been run by Stage 13']:
            if needle not in execution_evidence_text:
                print('FAIL: self-test execution evidence text missing ' + needle)
                raise SystemExit(1)
        all_text = '\n'.join(p.read_text(encoding='utf-8', errors='ignore') for p in profile_root.rglob('*') if p.is_file())
        live_config = (profile_root / 'config.yaml').read_text(encoding='utf-8')
        if re.search(r'__LAUNCHROOM_RESOLVE__[A-Z0-9_]+', live_config):
            print('FAIL: self-test live config contains unresolved LaunchRoom placeholders')
            raise SystemExit(1)
        for name, pattern in SECRET_PATTERNS.items():
            if pattern.search(all_text):
                print(f'FAIL: self-test generated secret-like value: {name}')
                raise SystemExit(1)
        print('validate_profile_setup_tool: self-test generated files ok')


def main() -> int:
    if not SCRIPT.exists():
        print('FAIL: scripts/install_launchroom_profile.ps1 missing')
        return 1
    text = SCRIPT.read_text(encoding='utf-8')
    for needle, label in [
        ('profile-distribution/launchroom-saas','uses profile distribution package'),
        ('LaunchRoom SaaS profile-distribution package','script purpose'),
        ('TestOutputRoot','supports non-mutating self-test mode'),
        ('ProjectType','supports Stage 2 project type selection'),
        ('--no-skills','creates LaunchRoom profile without default bundled skill noise'),
        ('LaunchRoom Stage 1 beginner-safe setup plan','beginner-safe plan title'),
        ('In plain language:','plain-language explanation'),
        ('Selected choices:','selected choices summary'),
        ('Beginner-safe result to expect:','beginner status contract'),
        ('status: $InstallStatus','final beginner-safe status'),
        ('visible_files_to_check','visible files summary'),
        ('what_was_not_touched','safety boundary summary'),
        ('remaining_safe_step','deferred next step summary'),
        ('Self-test mode: generating simulated live config.yaml from template; skipping hermes config set.','self-test skips config set'),
        ('never calls hermes profile/config/tools commands','self-test documentation'),
        ('config','uses hermes config'),
        ('terminal.cwd','sets terminal cwd'),
        ('approvals.mode','sets approvals mode'),
        ('security.redact_secrets','sets secret redaction'),
        ('security.tirith_enabled','sets tirith safety'),
        ('checkpoints.enabled','sets checkpoints'),
        ('memory.memory_enabled','sets memory'),
        ('PROFILE_INSTRUCTIONS.md','writes profile instructions'),
        ('LAUNCHROOM_PROFILE_CONTRACT.yaml','writes profile contract'),
        ('reports/profile-foundation-report.yaml','writes foundation report'),
        ('reports/stage-1-selected-settings.yaml','writes selected settings report'),
        ('reports/config.yaml.draft','writes config draft report'),
        ('.env.EXAMPLE','writes env example only'),
        ('skills/launchroom','installs bundled skills'),
        ('software-inventory-report.yaml','writes inventory report'),
        ('workspace-onboarding-report.yaml','writes Stage 2 workspace onboarding report'),
        ('Refusing unsafe Stage 2 workspace path before profile mutation','blocks unsafe workspace before live mutation'),
        ('terminal_cwd_matches_workspace','records terminal cwd workspace alignment'),
        ('skipped_secret_paths','records skipped secret paths'),
        ('git_mutation: false','records no git mutation boundary'),
        ('runtime_mutation: false','records no runtime mutation boundary'),
        ('stage_3_tool_readiness','hands off to Stage 3 tool readiness'),
        ('stage_4_starter_capability_pack','hands off to Stage 4 capability pack after tool readiness'),
        ('software-purpose-map.yaml','writes software purpose map'),
        ('software-install-recommendation.yaml','writes gated software install recommendation'),
        ('capability-graph.yaml','writes engineering capability graph'),
        ('LAUNCHROOM_ENGINEERING_CAPABILITY_GRAPH_v0_1','capability graph artifact id'),
        ('selection_rule: select capability workflow before selecting individual software','capability workflow selection rule'),
        ('code_change_delivery','maps code delivery task class'),
        ('external_agent_handoff','maps external agent handoff task class'),
        ('cloud_runtime_readiness','maps cloud/runtime readiness task class'),
        ('security_and_secret_safety','maps secret-safety task class'),
        ('supporting_skills','maps skill bundles'),
        ('required_tools','maps tool bundles'),
        ('gates:','maps gates'),
        ('verification:','maps verification'),
        ('capability_graph: task_class -> workflow -> tool_bundle -> skill_bundle -> gates -> verification','final capability graph summary'),
        ('starter-capability-pack.yaml','writes Stage 4 starter capability pack'),
        ('LAUNCHROOM_STARTER_CAPABILITY_PACK_v0_1','starter capability pack artifact id'),
        ('stage_4_starter_capability_pack','Stage 4 starter capability pack stage id'),
        ('starter_toolsets','maps Hermes toolsets'),
        ('starter_skills','maps starter skills'),
        ('memory_policy','maps memory policy'),
        ('workflow_playbook','maps workflow playbooks'),
        ('toolsets_enabled_without_gate: false','records no unauthorized toolset enablement'),
        ('memory_written_without_gate: false','records no unauthorized memory write'),
        ('network_skills_installed_without_gate: false','records no unauthorized network skill install'),
        ('starter_capability_pack: task_class -> Hermes toolsets -> skills -> memory policy -> workflows -> gates','final Stage 4 summary'),
        ('communication-channel-map.yaml','writes Stage 5 communication channel map'),
        ('communication-user-guide.md','writes Stage 5 user guide'),
        ('LAUNCHROOM_COMMUNICATION_CHANNEL_MAP_v0_1','communication channel map artifact id'),
        ('stage_5_communications','Stage 5 communications stage id'),
        ('communication_surfaces','maps communication surfaces'),
        ('channel_managers','maps channel managers'),
        ('hermes_gateway_telegram','maps Telegram manager'),
        ('hermes_gateway_slack','maps Slack manager'),
        ('hermes_gateway_email','maps Email manager'),
        ('hermes_webhook_or_api_server','maps webhook/API manager'),
        ('gateway_setup: false','records no gateway setup'),
        ('pairing_approved: false','records no pairing approval'),
        ('home_channel_set: false','records no home-channel mutation'),
        ('gateway_autostart_installed: false','records no autostart install'),
        ('test_message_sent: false','records no delivery test'),
        ('communication_channel_map: Desktop, Telegram, Slack, Email, Discord, adapters, webhooks/API -> managers -> guides -> gates -> verification','final Stage 5 summary'),
        ('operator-kit/START_HERE.md','writes Stage 6 beginner entrypoint'),
        ('operator-kit/NEXT_DECISION.md','writes Stage 6 next decision guide'),
        ('operator-kit/CHECK_IT_WORKS.md','writes Stage 6 user verification guide'),
        ('operator-kit/PAIN_TO_WORKFLOW_EXAMPLES.md','writes Stage 6 pain-to-workflow examples'),
        ('operator-kit/readiness_report.yaml','writes Stage 6 operator kit readiness report'),
        ('guided-session/DEFAULT_WORKFLOW_CATALOG.md','writes no-idea default workflow catalog'),
        ('guided-session/IMPLEMENTATION_ROADMAP.md','writes blueprint-to-working-result roadmap'),
        ('LAUNCHROOM_SAAS_OPERATOR_KIT_READINESS_v0_1','operator kit readiness artifact id'),
        ('stage_6_saas_operator_kit','Stage 6 SaaS operator kit stage id'),
        ('saas_operator_kit: START_HERE -> examples -> next decision -> product brief -> target user -> first workflow -> backlog -> local task packet -> gates -> readiness report','final Stage 6 summary'),
        ('implementation_executed=false','records no implementation execution'),
        ('beginner_next_decision_present: true','records beginner decision guide'),
        ('pain_to_workflow_examples_present: true','records pain-to-workflow examples'),
        ('guided_session_present=true','prints guided session present'),
        ('no_idea_default_workflow_catalog_present=true','prints no-idea default catalog present'),
        ('blueprint_to_solution_path_present=true','prints blueprint-to-solution path present'),
        ('cloud_mutation=false','records no cloud mutation'),
        ('first-slice/READINESS_REPORT.yaml','writes Stage 7 first-slice readiness report'),
        ('first_slice_planning: implementation brief -> local pilot plan -> acceptance tests -> demo script -> decision gate','prints Stage 7 summary'),
        ('stage7_status: $Stage7Status','prints Stage 7 status'),
        ('local-pilot/READINESS_REPORT.yaml','writes Stage 8 local pilot readiness report'),
        ('local_pilot_execution_packet: execution packet -> file change plan -> command plan -> test plan -> evidence log -> review checklist -> handoff summary','prints Stage 8 summary'),
        ('stage8_status: $Stage8Status','prints Stage 8 status'),
        ('file_changes_executed: false','records no file changes executed'),
        ('commands_executed: false','records no commands executed'),
        ('tests_executed: false','records no tests executed'),
        ('project-audit/AUDIT_REPORT.yaml','writes Stage 9 project audit report'),
        ('project_plan_integrity_audit: expected result map -> missing fragments -> contradiction scan -> stage drift scan -> repair recommendations','prints Stage 9 summary'),
        ('stage9_status: $Stage9Status','prints Stage 9 status'),
        ('execution_allowed=false','blocks execution by default'),
        ('agent-readiness/EXECUTION_READINESS_REPORT.yaml','writes Stage 10 agent readiness report'),
        ('agent_execution_readiness: toolchain requirements -> software gap analysis -> Hermes toolset plan -> skill load plan -> agent pipeline plan -> install plan -> command readiness','prints Stage 10 summary'),
        ('stage10_status: $Stage10Status','prints Stage 10 status'),
        ('execution_ready=false','blocks execution readiness by default'),
        ('toolsets_enabled_without_gate=false','records no unauthorized toolset enablement'),
        ('skills_installed_without_gate=false','records no unauthorized skill install'),
        ('agents_spawned=false','records no agent spawning'),
        ('hygiene/HYGIENE_REPORT.yaml','writes Stage 11 hygiene report'),
        ('workspace_hygiene: artifact index -> active files -> superseded files -> broken/stale files -> do-not-use -> cleanup plan -> archive plan -> deletion gate','prints Stage 11 summary'),
        ('stage11_status: $Stage11Status','prints Stage 11 status'),
        ('cleanup_executed=false','records no cleanup execution'),
        ('archive_executed=false','records no archive execution'),
        ('deletion_executed=false','records no deletion execution'),
        ('files_deleted=false','records no file deletion'),
        ('skills/SKILL_INTEGRATION_REPORT.yaml','writes Stage 12 skill integration report'),
        ('skill_capture: stage skill matrix -> required skills -> optional skills -> missing skills -> capture guide -> candidate template -> promotion gate','prints Stage 12 summary'),
        ('stage12_status: $Stage12Status','prints Stage 12 status'),
        ('skills_installed=false','records no skill install'),
        ('skills_patched=false','records no skill patch'),
        ('skills_promoted=false','records no skill promotion'),
        ('persistent_memory_written=false','records no memory write'),
        ('execution-evidence/EXECUTION_EVIDENCE_REPORT.yaml','writes Stage 13 execution evidence report'),
        ('execution_evidence_binder: executed commands -> changed files -> test results -> acceptance evidence -> user-visible result -> residual risks -> rollback and handoff','prints Stage 13 summary'),
        ('stage13_status: $Stage13Status','prints Stage 13 status'),
        ('real_execution_evidence_present=false','records no real evidence yet'),
        ('fabricated_evidence=false','records no fabricated evidence'),
        ('commands_executed_by_stage13=false','records no commands executed'),
        ('next_stage: grant_implementation_gate_or_review_execution_evidence_scaffold','hands off to implementation gate or evidence review'),
        ('dependencies_installed=false','records no dependency install'),
        ('install_gate_required: true','requires install gate for software changes'),
        ('installs_executed: false','records no install execution'),
        ('purpose','maps software purpose'),
        ('agent_use','maps agent use for each software component'),
        ('Never copies .env, auth.json, state.db','secret boundary'),
        ('live_config_has_launchroom_placeholders','checks live placeholders'),
        ('hermes tools enable','enables toolsets where supported'),
    ]:
        require(text, needle, label)
    required_files = [
        'profile-distribution/launchroom-saas/distribution.yaml',
        'profile-distribution/launchroom-saas/config.yaml.template',
        'profile-distribution/launchroom-saas/SOUL.md',
        'profile-distribution/launchroom-saas/PROFILE_INSTRUCTIONS.md',
        'profile-distribution/launchroom-saas/LAUNCHROOM_PROFILE_CONTRACT.yaml',
        'profile-distribution/launchroom-saas/.env.EXAMPLE',
        'profile-distribution/launchroom-saas/skills/launchroom-profile-operator/SKILL.md',
        'profile-distribution/launchroom-saas/skills/launchroom-hermes-settings-guide/SKILL.md',
        'profile-distribution/launchroom-saas/skills/launchroom-saas-operator/SKILL.md',
        'source/stages/output/stage-1-selected-settings.example.yaml',
    ]
    missing = [p for p in required_files if not (ROOT / p).exists()]
    if missing:
        print('FAIL: missing setup distribution files: ' + ', '.join(missing))
        return 1
    if not DIST.exists():
        print('FAIL: distribution root missing')
        return 1
    run_self_test_if_available()
    print('validate_profile_setup_tool: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
