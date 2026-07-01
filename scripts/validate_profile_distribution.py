#!/usr/bin/env python3
from __future__ import annotations
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / 'profile-distribution' / 'launchroom-saas'
SELECTED_EXAMPLE = ROOT / 'source' / 'stages' / 'output' / 'stage-1-selected-settings.example.yaml'

REQUIRED_DIST_FILES = [
    'README.md',
    'distribution.yaml',
    'config.yaml.template',
    'SOUL.md',
    'PROFILE_INSTRUCTIONS.md',
    'LAUNCHROOM_PROFILE_CONTRACT.yaml',
    '.env.EXAMPLE',
    'reports/profile-foundation-report.template.yaml',
    'reports/profile-apply-plan.template.yaml',
    'skills/launchroom-profile-operator/SKILL.md',
    'skills/launchroom-hermes-settings-guide/SKILL.md',
    'skills/launchroom-saas-operator/SKILL.md',
]

YAML_FILES = [
    'distribution.yaml',
    'LAUNCHROOM_PROFILE_CONTRACT.yaml',
    'config.yaml.template',
    'reports/profile-foundation-report.template.yaml',
    'reports/profile-apply-plan.template.yaml',
]

SECRET_PATTERNS = {
    'openai_key': re.compile(r'sk-[A-Za-z0-9_-]{20,}'),
    'github_token': re.compile(r'gh[pousr]_[A-Za-z0-9_]{20,}'),
    'jwt': re.compile(r'eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}'),
    'private_key': re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'telegram_token': re.compile(r'\b\d{6,}:[A-Za-z0-9_-]{20,}\b'),
}


def fail(message: str) -> int:
    print('FAIL: ' + message)
    return 1


def main() -> int:
    missing = [p for p in REQUIRED_DIST_FILES if not (DIST / p).exists()]
    if missing:
        return fail('missing distribution files: ' + ', '.join(missing))
    if not SELECTED_EXAMPLE.exists():
        return fail('missing selected settings example')

    parsed = {}
    for rel in YAML_FILES:
        path = DIST / rel
        try:
            parsed[rel] = yaml.safe_load(path.read_text(encoding='utf-8'))
        except Exception as exc:  # pragma: no cover - diagnostic path
            return fail(f'YAML parse failed for {rel}: {exc}')
    try:
        yaml.safe_load(SELECTED_EXAMPLE.read_text(encoding='utf-8'))
    except Exception as exc:
        return fail(f'YAML parse failed for selected settings example: {exc}')

    manifest = parsed['distribution.yaml']
    if manifest.get('name') != 'launchroom-saas':
        return fail('distribution.yaml name is not launchroom-saas')
    if manifest.get('status') != 'draft_for_owner_review':
        return fail('distribution.yaml status must remain draft_for_owner_review until release gate')

    includes = manifest.get('includes', {})
    include_paths: list[str] = []
    for key in ['soul', 'config_template', 'profile_instructions', 'profile_contract', 'env_example', 'selected_settings_example']:
        if key in includes:
            include_paths.append(includes[key])
    for key in ['skills', 'report_templates']:
        include_paths.extend(includes.get(key, []))
    missing_includes = []
    for rel in include_paths:
        candidate = (DIST / rel).resolve()
        if str(rel).startswith('../../'):
            candidate = (DIST / rel).resolve()
        if not candidate.exists():
            missing_includes.append(rel)
    if missing_includes:
        return fail('manifest includes missing files: ' + ', '.join(missing_includes))

    contract = parsed['LAUNCHROOM_PROFILE_CONTRACT.yaml']
    missing_contract_files = [p for p in contract.get('required_distribution_files', []) if not (DIST / p).exists()]
    if missing_contract_files:
        return fail('contract required files missing: ' + ', '.join(missing_contract_files))

    for skill_path in sorted((DIST / 'skills').glob('*/SKILL.md')):
        text = skill_path.read_text(encoding='utf-8')
        if not text.startswith('---') or '\nname:' not in text or '\ndescription:' not in text:
            return fail(f'bad skill frontmatter: {skill_path.relative_to(ROOT)}')

    config_template_text = (DIST / 'config.yaml.template').read_text(encoding='utf-8')
    placeholders = sorted(set(re.findall(r'__LAUNCHROOM_RESOLVE__[A-Z0-9_]+', config_template_text)))
    expected = {
        '__LAUNCHROOM_RESOLVE__MODEL_PROVIDER',
        '__LAUNCHROOM_RESOLVE__MODEL_DEFAULT',
        '__LAUNCHROOM_RESOLVE__USER_LANGUAGE',
        '__LAUNCHROOM_RESOLVE__PROJECT_PATH',
    }
    if set(placeholders) != expected:
        return fail('unexpected config template placeholders: ' + ', '.join(placeholders))
    if (DIST / 'config.yaml').exists():
        return fail('distribution must not contain live config.yaml; use config.yaml.template')

    all_text = []
    for path in list(DIST.rglob('*')) + [SELECTED_EXAMPLE]:
        if path.is_file():
            all_text.append(path.read_text(encoding='utf-8', errors='ignore'))
    text_blob = '\n'.join(all_text)
    for name, pattern in SECRET_PATTERNS.items():
        if pattern.search(text_blob):
            return fail(f'secret-like value detected: {name}')

    print('validate_profile_distribution: ok')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
