#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','STAGE_SKILL_MATRIX.md','REQUIRED_SKILLS.md','OPTIONAL_SKILLS.md','MISSING_SKILLS.md','SKILL_CAPTURE_GUIDE.md','SKILL_CANDIDATE_TEMPLATE.md','SKILL_PROMOTION_GATE.md','SKILL_INTEGRATION_REPORT.yaml','../skills-candidates/README.md']
REQUIRED_FLAGS = ['skill_integration_status: partial','skills_installed: false','skills_patched: false','skills_promoted: false','persistent_memory_written: false','skill_candidates_created: false','implementation_executed: false','commands_executed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','stage_skill_matrix_present: true','required_skills_present: true','optional_skills_present: true','missing_skills_present: true','skill_capture_guide_present: true','skill_candidate_template_present: true','skill_promotion_gate_present: true','skills_candidates_root_present: true']
REQUIRED_CONSUMES = ['.hermes/hygiene/HYGIENE_REPORT.yaml','.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml','.hermes/reports/starter-capability-pack.yaml','.hermes/reports/capability-graph.yaml','.hermes/project-audit/AUDIT_REPORT.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'skill-capture.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-skill-capture-v0_12':
        print('FAIL: unexpected skill capture recipe_id')
        return 1
    if recipe.get('skills_root') != '.hermes/skills':
        print('FAIL: unexpected skills root')
        return 1
    if recipe.get('skill_candidates_root') != '.hermes/skills-candidates':
        print('FAIL: unexpected skill candidates root')
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
        if flag not in recipe.get('required_skill_flags', []):
            print('FAIL: recipe missing skill flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_12_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 12 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_12_SKILL_CAPTURE_v0_1',
        'Skill Capture and Stage Skill Integration Pack',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/skills/',
        '.hermes/skills-candidates/',
        'STAGE_SKILL_MATRIX.md',
        'REQUIRED_SKILLS.md',
        'OPTIONAL_SKILLS.md',
        'MISSING_SKILLS.md',
        'SKILL_CAPTURE_GUIDE.md',
        'SKILL_CANDIDATE_TEMPLATE.md',
        'SKILL_PROMOTION_GATE.md',
        'SKILL_INTEGRATION_REPORT.yaml',
        'hygiene -> stage skill matrix -> required/optional/missing skills -> capture guide -> candidate template -> promotion gate -> owner skill decision',
        'skills_installed: false',
        'skills_patched: false',
        'skills_promoted: false',
        'persistent_memory_written: false',
    ]:
        if marker not in contract:
            print('FAIL: Stage 12 contract marker missing: ' + marker)
            return 1
    print('validate_skill_capture: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
