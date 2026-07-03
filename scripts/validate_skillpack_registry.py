#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

try:
    import yaml
except Exception as exc:  # pragma: no cover - import failure path
    print(f'FAIL: PyYAML is required for skillpack registry validation: {exc}')
    raise SystemExit(1)

ROOT = Path(__file__).resolve().parents[1]
REGISTRY = ROOT / 'source' / 'skillpacks' / 'launchroom-skillpacks.v0_1.yaml'
DOC = ROOT / 'generated' / 'SKILLPACKS.md'
BOUNDARY = ROOT / 'source' / 'skillpacks' / 'SANITIZED_ABSTRACTION_BOUNDARY.md'
SANITIZED_SKILLS = {
    'launchroom-memory-governance': ROOT / 'source' / 'skills' / 'launchroom-sanitized-abstractions' / 'launchroom-memory-governance' / 'SKILL.md',
    'launchroom-positive-result-capture': ROOT / 'source' / 'skills' / 'launchroom-sanitized-abstractions' / 'launchroom-positive-result-capture' / 'SKILL.md',
    'launchroom-tool-readiness-smoke': ROOT / 'source' / 'skills' / 'launchroom-sanitized-abstractions' / 'launchroom-tool-readiness-smoke' / 'SKILL.md',
}
SANITIZED_SOURCE_LINEAGE = {
    'airmida-memory-stack-operator',
    'airmida-positive-result-capture',
    'airmida-external-agent-tool-readiness',
}
README = ROOT / 'README.md'
DOCTOR = ROOT / 'scripts' / 'doctor.py'
INSTALLER = ROOT / 'scripts' / 'install_launchroom_profile.ps1'
CI = ROOT / '.github' / 'workflows' / 'validate.yml'

REQUIRED_VISIBILITY = {'runtime_enabled_now', 'environment_or_platform_candidate', 'excluded_or_lab_only', 'sanitized_launchroom_abstraction'}
REQUIRED_PACKS = {
    'launchroom_minimal_bundle',
    'foundation_operator_pack',
    'developer_builder_pack',
    'creative_product_pack',
    'research_knowledge_pack',
    'productivity_documents_pack',
    'messaging_social_pack',
    'apple_personal_operator_pack',
    'agentops_executor_pack',
    'cloudroom_modelops_pack',
    'launchroom_sanitized_abstractions_pack',
    'airmida_internal_operator_pack',
    'lab_restricted_pack',
}
REQUIRED_HIDDEN = {
    'apple-notes',
    'apple-reminders',
    'findmy',
    'imessage',
    'macos-computer-use',
    'kanban-orchestrator',
    'kanban-worker',
    'evaluating-llms-harness',
    'serving-llms-vllm',
    'audiocraft-audio-generation',
    'research-paper-writing',
    'xurl',
    'python-debugpy',
    'obliteratus',
}
FALSE_ACTIONS = {
    'skills_installed',
    'skills_enabled',
    'skills_promoted',
    'dependencies_installed',
    'toolsets_enabled_without_gate',
    'memory_written',
    'agents_spawned',
    'implementation_executed',
    'runtime_mutation',
    'cloud_mutation',
    'gateway_mutation',
    'n8n_mutation',
    'git_publication_executed',
    'secrets_read_or_written',
}
FORBIDDEN_PRIVATE_MARKERS = ['D:/AIRMIDA_CORE', 'D:\\AIRMIDA_CORE', 'C:/Users/svaro', 'active_profile: airmida', 'latest_operator_packet', 'ssh.airmida.io', 'n8n.airmida.io']
FORBIDDEN_CUSTOMER_FACING_MARKERS = ['AIRMIDA', 'D:/AIRMIDA_CORE', 'C:/Users/svaro', 'active_profile: airmida']
SECRET_PATTERNS = [
    re.compile(r'sk-[A-Za-z0-9_-]{20,}'),
    re.compile(r'gh[pousr]_[A-Za-z0-9_]{20,}'),
    re.compile(r'xox[baprs]-[A-Za-z0-9-]{20,}'),
    re.compile(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
]
INSTALLER_FORBIDDEN_INTERNAL_SKILL_RE = re.compile(r'airmida-[a-z0-9-]+')


def fail(message: str) -> None:
    print('FAIL: ' + message)
    raise SystemExit(1)


def require_file(path: Path) -> str:
    if not path.exists():
        fail(f'missing required file: {path.relative_to(ROOT).as_posix()}')
    return path.read_text(encoding='utf-8')


def validate_sanitized_skill(name: str, path: Path) -> str:
    text = require_file(path)
    if not text.startswith('---'):
        fail(f'{name} frontmatter must start at byte 0')
    frontmatter = yaml.safe_load(text.split('---', 2)[1])
    if frontmatter.get('name') != name:
        fail(f'{name} missing expected frontmatter name')
    description = frontmatter.get('description', '')
    if not description.startswith('Use when '):
        fail(f'{name} description must start with "Use when "')
    if len(description) > 1024:
        fail(f'{name} description exceeds 1024 chars')
    for required_field in ['version', 'author', 'license', 'metadata']:
        if required_field not in frontmatter:
            fail(f'{name} missing frontmatter field: {required_field}')
    for section in ['## Overview', '## When to Use', '## Do Not Use For', '## Boundary', '## Common Pitfalls', '## Verification Checklist']:
        if section not in text:
            fail(f'{name} missing section {section}')
    for marker in ['source_internal_skill_mutation_allowed: false', 'public_beginner_default: false']:
        if marker not in text:
            fail(f'{name} missing boundary marker: {marker}')
    for marker in FORBIDDEN_PRIVATE_MARKERS + FORBIDDEN_CUSTOMER_FACING_MARKERS:
        if marker in text:
            fail(f'{name} leaks private/internal/customer-facing marker: {marker}')
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            fail(f'{name} contains secret-like marker matching {pattern.pattern}')
    if len(text) > 100000:
        fail(f'{name} exceeds SKILL.md size budget')
    return text


def main() -> int:
    registry_text = require_file(REGISTRY)
    doc_text = require_file(DOC)
    boundary_text = require_file(BOUNDARY)
    sanitized_texts = {name: validate_sanitized_skill(name, path) for name, path in SANITIZED_SKILLS.items()}
    readme_text = require_file(README)
    doctor_text = require_file(DOCTOR)
    installer_text = require_file(INSTALLER)
    ci_text = require_file(CI)

    data = yaml.safe_load(registry_text)
    if not isinstance(data, dict):
        fail('registry must parse as a YAML mapping')
    if data.get('artifact_id') != 'LAUNCHROOM_SKILLPACK_REGISTRY_v0_1':
        fail('unexpected artifact_id')
    if data.get('status_marker') != 'public LaunchRoom test package / not AIRMIDA authority':
        fail('missing public/not-authority status marker')
    if data.get('language') != 'en':
        fail('canonical registry language must be English')

    installer_internal_refs = sorted(set(INSTALLER_FORBIDDEN_INTERNAL_SKILL_RE.findall(installer_text)))
    if installer_internal_refs:
        fail(f'installer-generated public stage reports must not reference AIRMIDA internal skills: {installer_internal_refs}')
    for marker in ['launchroom-tool-readiness-smoke', 'launchroom-positive-result-capture', 'hermes-agent', 'experience-grounded-work-preflight']:
        if marker not in installer_text:
            fail(f'installer sanitation marker missing: {marker}')

    counts = data.get('inventory_counts', {})
    expected_counts = {
        'runtime_enabled_skills_input': 98,
        'filesystem_skillmd_seen_input': 112,
        'hidden_or_advanced_candidates_input': 14,
        'existing_launchroom_bundled_skills': 3,
        'sanitized_abstraction_skills_input': len(SANITIZED_SKILLS),
        'public_beginner_default_hidden_candidates': 0,
    }
    for key, expected in expected_counts.items():
        if counts.get(key) != expected:
            fail(f'inventory count mismatch for {key}: expected {expected}, got {counts.get(key)}')

    visibility = data.get('visibility_classes', {})
    if set(visibility.keys()) != REQUIRED_VISIBILITY:
        fail('visibility classes mismatch')

    actions = data.get('actions_executed_by_registry', {})
    for key in FALSE_ACTIONS:
        if actions.get(key) is not False:
            fail(f'action marker must be false: {key}')

    policy = data.get('default_install_policy', {})
    if policy.get('default_bundle_is_small') is not True:
        fail('default bundle must stay small')
    if policy.get('do_not_install_all_runtime_skills') is not True:
        fail('registry must not install all runtime skills')
    if policy.get('do_not_install_hidden_candidates_by_default') is not True:
        fail('registry must not install hidden candidates by default')
    if len(policy.get('bundled_profile_skills', [])) != 3:
        fail('expected exactly three bundled LaunchRoom profile skills')
    if policy.get('sanitized_abstractions_are_separate_from_airmida_internal_skills') is not True:
        fail('sanitized abstractions must be separate from AIRMIDA internal skills')
    if policy.get('do_not_patch_airmida_internal_skills_for_launchroom') is not True:
        fail('registry must forbid patching AIRMIDA internal skills for LaunchRoom productization')
    if policy.get('sanitized_abstraction_boundary_doc_required') is not True:
        fail('sanitized abstraction boundary doc must be required')

    abstraction_policy = data.get('sanitized_abstraction_policy', {})
    if abstraction_policy.get('source_internal_skills_are') != 'reference_lineage_only':
        fail('AIRMIDA internal skills must be reference lineage only')
    if abstraction_policy.get('source_airmida_skill_mutation_allowed_by_registry') is not False:
        fail('registry must not allow AIRMIDA source skill mutation')
    if abstraction_policy.get('first_sanitized_skill') != 'launchroom-memory-governance':
        fail('first sanitized skill marker mismatch')
    if abstraction_policy.get('second_sanitized_skill') != 'launchroom-positive-result-capture':
        fail('second sanitized skill marker mismatch')
    if abstraction_policy.get('third_sanitized_skill') != 'launchroom-tool-readiness-smoke':
        fail('third sanitized skill marker mismatch')
    if abstraction_policy.get('sanitized_abstraction_skills') != list(SANITIZED_SKILLS.keys()):
        fail('sanitized abstraction skill list mismatch')
    markers = abstraction_policy.get('required_markers', {})
    if markers.get('source_airmida_skill_mutation_allowed') is not False:
        fail('source skill mutation marker must be false')
    if markers.get('airmida_internal_skills_are_public_launchroom_skills') is not False:
        fail('AIRMIDA internal skills must not be public LaunchRoom skills')
    if markers.get('sanitized_skills_require_new_launchroom_names') is not True:
        fail('sanitized skills must require new launchroom-* names')
    if markers.get('sanitized_abstraction_skills_count') != len(SANITIZED_SKILLS):
        fail('sanitized abstraction skill count marker mismatch')

    packs = data.get('curated_packs', [])
    if not isinstance(packs, list) or not packs:
        fail('curated_packs must be a non-empty list')
    pack_ids = [p.get('pack_id') for p in packs]
    if len(pack_ids) != len(set(pack_ids)):
        fail('pack ids must be unique')
    if set(pack_ids) != REQUIRED_PACKS:
        fail('curated pack set mismatch')
    by_pack = {p['pack_id']: p for p in packs}
    for pack in packs:
        for field in ['display_name', 'room_or_stage', 'offer_model', 'default_install', 'visibility_class', 'why_valuable', 'runtime_skills', 'hidden_candidates', 'gates', 'blocked_without_gate', 'verification']:
            if field not in pack:
                fail(f"pack {pack.get('pack_id')} missing {field}")
        if pack['visibility_class'] not in REQUIRED_VISIBILITY:
            fail(f"pack {pack['pack_id']} has invalid visibility_class")
        if pack['pack_id'] != 'launchroom_minimal_bundle' and pack['default_install'] is not False:
            fail(f"optional pack must not default-install: {pack['pack_id']}")
    if by_pack['launchroom_minimal_bundle'].get('default_install') is not True:
        fail('minimal LaunchRoom bundle must be the only default install pack')
    if by_pack['lab_restricted_pack'].get('offer_model') != 'not_public_beginner_flow':
        fail('lab restricted pack must not be public beginner flow')
    if 'positive-result behavior offered through launchroom_sanitized_abstractions_pack after optional review gate' not in by_pack['foundation_operator_pack'].get('product_notes', []):
        fail('foundation_operator_pack must point positive-result behavior to sanitized abstraction pack')

    sanitized_pack = by_pack['launchroom_sanitized_abstractions_pack']
    if sanitized_pack.get('visibility_class') != 'sanitized_launchroom_abstraction':
        fail('sanitized abstraction pack must use sanitized visibility class')
    if sanitized_pack.get('runtime_skills') != []:
        fail('sanitized abstraction pack must not expose source/internal skills as runtime skills')
    if sanitized_pack.get('sanitized_abstraction_skills') != list(SANITIZED_SKILLS.keys()):
        fail('sanitized abstraction pack skill list mismatch')
    for source_skill in sorted(SANITIZED_SOURCE_LINEAGE):
        if source_skill not in sanitized_pack.get('source_lineage_skills', []):
            fail(f'sanitized abstraction pack must preserve source lineage: {source_skill}')
        if source_skill in sanitized_pack.get('runtime_skills', []):
            fail(f'source internal skill must not be runtime skill in sanitized pack: {source_skill}')
        if source_skill not in by_pack['airmida_internal_operator_pack'].get('runtime_skills', []):
            fail(f'AIRMIDA source-lineage skill must remain internal-only in AIRMIDA internal pack: {source_skill}')

    # source-lineage internal skills must not appear in public runtime packs; use launchroom-* sanitized skills instead.
    for pack_id, pack in by_pack.items():
        if pack_id in {'airmida_internal_operator_pack', 'launchroom_sanitized_abstractions_pack'}:
            continue
        leaked = sorted(SANITIZED_SOURCE_LINEAGE.intersection(set(pack.get('runtime_skills', []))))
        if leaked:
            fail(f'source-lineage internal skills leaked into public runtime pack {pack_id}: {leaked}')

    product_positioning = sanitized_pack.get('product_positioning', {})
    if product_positioning.get('user_facing_name') != 'Safe Practice Pack':
        fail('sanitized abstraction pack must keep a beginner-safe user-facing name')
    if product_positioning.get('current_product_decision') != 'keep_optional_only':
        fail('sanitized abstraction pack must remain optional-only until promotion gate')
    if product_positioning.get('recommended_sequence') != list(SANITIZED_SKILLS.keys()):
        fail('sanitized abstraction pack recommended sequence mismatch')
    for field in ['plain_language_summary', 'offer_when', 'do_not_offer_when', 'promotion_requires']:
        if not product_positioning.get(field):
            fail(f'sanitized abstraction pack missing product positioning field: {field}')

    hidden = data.get('hidden_or_advanced_candidates', [])
    hidden_names = {item.get('skill') for item in hidden}
    if hidden_names != REQUIRED_HIDDEN:
        fail('hidden/advanced candidate set mismatch')
    for item in hidden:
        for field in ['skill', 'pack_id', 'visibility_class', 'condition', 'risk', 'offer_when', 'priority', 'public_starter_default', 'skill_enabled_by_registry', 'dependency_installed_by_registry', 'runtime_mutation_by_registry']:
            if field not in item:
                fail(f"hidden candidate {item.get('skill')} missing {field}")
        if item['pack_id'] not in REQUIRED_PACKS:
            fail(f"hidden candidate {item['skill']} points to unknown pack")
        if item['public_starter_default'] is not False:
            fail(f"hidden candidate must not be public default: {item['skill']}")
        if item['skill_enabled_by_registry'] is not False:
            fail(f"registry must not enable hidden skill: {item['skill']}")
        if item['dependency_installed_by_registry'] is not False:
            fail(f"registry must not install dependency for hidden skill: {item['skill']}")
        if item['runtime_mutation_by_registry'] is not False:
            fail(f"registry must not mutate runtime for hidden skill: {item['skill']}")
    if next(i for i in hidden if i['skill'] == 'obliteratus')['visibility_class'] != 'excluded_or_lab_only':
        fail('obliteratus must remain excluded_or_lab_only')
    for skill in ['kanban-orchestrator', 'kanban-worker']:
        if next(i for i in hidden if i['skill'] == skill)['pack_id'] != 'agentops_executor_pack':
            fail(f'{skill} must belong to agentops_executor_pack')

    for marker in ['LaunchRoom Skillpacks', 'source/skillpacks/launchroom-skillpacks.v0_1.yaml', 'source/skillpacks/SANITIZED_ABSTRACTION_BOUNDARY.md', 'python scripts/validate_skillpack_registry.py'] + list(SANITIZED_SKILLS.keys()):
        if marker not in doc_text and marker not in readme_text:
            fail(f'missing documentation marker: {marker}')
    for pack_id in REQUIRED_PACKS:
        if pack_id not in doc_text:
            fail(f'generated doc missing pack id: {pack_id}')
    for skill in REQUIRED_HIDDEN:
        if skill not in doc_text:
            fail(f'generated doc missing hidden candidate: {skill}')

    for marker in ['generated/SKILLPACKS.md', 'source/skillpacks/launchroom-skillpacks.v0_1.yaml', 'source/skillpacks/SANITIZED_ABSTRACTION_BOUNDARY.md', 'scripts/validate_skillpack_registry.py']:
        if marker not in readme_text:
            fail(f'README missing marker: {marker}')
        if marker not in doctor_text:
            fail(f'doctor required-file list missing marker: {marker}')
    for name, path in SANITIZED_SKILLS.items():
        rel = path.relative_to(ROOT).as_posix()
        if rel not in readme_text:
            fail(f'README missing sanitized skill path: {rel}')
        if rel not in doctor_text:
            fail(f'doctor required-file list missing sanitized skill path: {rel}')
        if name not in doc_text:
            fail(f'generated doc missing sanitized skill name: {name}')
    for marker in ['source_airmida_skill_mutation_allowed: false', 'sanitized_skills_require_new_launchroom_names: true', 'launchroom-memory-governance', 'launchroom-positive-result-capture', 'launchroom-tool-readiness-smoke', 'sanitized_abstraction_skills_count: 3']:
        if marker not in boundary_text and marker not in registry_text and marker not in doc_text:
            fail(f'sanitized boundary/registry/doc missing marker: {marker}')

    if 'validate_skillpack_registry.py' not in ci_text:
        fail('CI workflow must run validate_skillpack_registry.py')

    print('validate_skillpack_registry: ok')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
