#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REQUIRED_FILES = ['START_HERE.md','ARTIFACT_INDEX.md','ACTIVE_FILES.md','SUPERSEDED_FILES.md','BROKEN_OR_STALE_FILES.md','DO_NOT_USE.md','CLEANUP_PLAN.md','ARCHIVE_PLAN.md','DELETION_GATE.md','HYGIENE_REPORT.yaml']
REQUIRED_FLAGS = ['hygiene_status: partial','cleanup_executed: false','archive_executed: false','deletion_executed: false','files_deleted: false','files_moved: false','files_renamed: false','implementation_executed: false','commands_executed: false','runtime_mutation: false','cloud_mutation: false','gateway_mutation: false','n8n_mutation: false','secrets_read_or_written: false','git_publication_executed: false','artifact_index_present: true','active_files_present: true','superseded_files_present: true','broken_or_stale_files_present: true','do_not_use_present: true','cleanup_plan_present: true','archive_plan_present: true','deletion_gate_present: true']
REQUIRED_CONSUMES = ['.hermes/agent-readiness/EXECUTION_READINESS_REPORT.yaml','.hermes/project-audit/AUDIT_REPORT.yaml','.hermes/local-pilot/READINESS_REPORT.yaml','.hermes/first-slice/READINESS_REPORT.yaml','.hermes/operator-kit/readiness_report.yaml','.hermes/reports/starter-capability-pack.yaml','.hermes/reports/software-inventory-report.yaml','.hermes/reports/workspace-onboarding-report.yaml']

def main() -> int:
    recipe_path = ROOT / 'source' / 'recipes' / 'workspace-hygiene.json'
    recipe = json.loads(recipe_path.read_text(encoding='utf-8'))
    if recipe.get('recipe_id') != 'launchroom-workspace-hygiene-v0_11':
        print('FAIL: unexpected workspace hygiene recipe_id')
        return 1
    if recipe.get('hygiene_root') != '.hermes/hygiene':
        print('FAIL: unexpected hygiene root')
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
        if flag not in recipe.get('required_hygiene_flags', []):
            print('FAIL: recipe missing hygiene flag: ' + flag)
            return 1
    contract_path = ROOT / recipe.get('stage_11_contract', '')
    if not contract_path.exists():
        print('FAIL: Stage 11 contract missing')
        return 1
    contract = contract_path.read_text(encoding='utf-8')
    for marker in [
        'LAUNCHROOM_STAGE_11_WORKSPACE_HYGIENE_v0_1',
        'Workspace Hygiene, Cleanup, and Artifact Lifecycle',
        'Hermes working artifact / not AIRMIDA authority',
        '.hermes/hygiene/',
        'ARTIFACT_INDEX.md',
        'ACTIVE_FILES.md',
        'SUPERSEDED_FILES.md',
        'BROKEN_OR_STALE_FILES.md',
        'DO_NOT_USE.md',
        'CLEANUP_PLAN.md',
        'ARCHIVE_PLAN.md',
        'DELETION_GATE.md',
        'HYGIENE_REPORT.yaml',
        'agent readiness -> artifact lifecycle map -> do-not-use register -> cleanup/archive/deletion gates -> owner hygiene decision',
        'cleanup_executed: false',
        'archive_executed: false',
        'deletion_executed: false',
        'files_deleted: false',
    ]:
        if marker not in contract:
            print('FAIL: Stage 11 contract marker missing: ' + marker)
            return 1
    print('validate_workspace_hygiene: ok')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
