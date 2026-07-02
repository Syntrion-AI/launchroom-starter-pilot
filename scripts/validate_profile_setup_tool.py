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
