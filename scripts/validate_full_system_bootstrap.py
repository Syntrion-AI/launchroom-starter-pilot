#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source" / "launchroom.starter.v0_5.json"
FULL_SYSTEM_DIR = ROOT / "source" / "full-system-bootstrap"
FULL_SKILLPACK = ROOT / "source" / "skillpacks" / "launchroom-full-system-skillpack.v0_7.yaml"
CONTRACT = ROOT / "contracts" / "launchroom-full-system-bootstrap-contract.yaml"
INSTALLER = ROOT / "scripts" / "install_launchroom_profile.ps1"
README = ROOT / "README.md"
BOOTSTRAP = ROOT / "BOOTSTRAP_WITH_HERMES.md"
RUNBOOK = ROOT / "RUN_ME_FIRST.md"
GENERATED_RUNBOOK = ROOT / "generated" / "RUN_ME_FIRST.md"
PROFILE_DIST = ROOT / "profile-distribution" / "launchroom-saas"

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9_-]{20,}"),
    re.compile(r"gh[pousr]_[A-Za-z0-9_]{20,}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{20,}"),
    re.compile(r"\b\d{6,}:[A-Za-z0-9_-]{20,}\b"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]

REQUIRED_FULL_SYSTEM_FILES = [
    FULL_SYSTEM_DIR / "launchroom-v0.7-stage-map.yaml",
    FULL_SYSTEM_DIR / "full-system-software-and-capability-inventory.yaml",
    FULL_SYSTEM_DIR / "default-engineering-saas-profile-instruction-brief.md",
    FULL_SKILLPACK,
    CONTRACT,
]

REQUIRED_STAGE_IDS = [
    "stage_0",
    "stage_1",
    "stage_2",
    "stage_3",
    "stage_4",
    "stage_5",
]

REQUIRED_SOFTWARE_CATEGORIES = [
    "hermes_runtime",
    "windows_shell_and_path",
    "python_toolchain",
    "node_frontend_toolchain",
    "version_control",
    "file_search_and_dev_utilities",
    "browser_and_computer_use",
    "containers_and_local_services",
    "database_clients",
    "cloud_provider_clients",
    "messaging_gateway",
    "mcp_advanced",
    "memory_context_and_knowledge",
    "media_documents_and_productivity",
    "observability_security_and_quality",
    "agentops_and_external_coding_agents",
]

REQUIRED_NEW_SKILLS = [
    "launchroom-system-diagnostic",
    "launchroom-full-software-inventory",
    "launchroom-default-engineering-saas-profile",
    "launchroom-profile-factory",
    "launchroom-profile-state-resolver",
    "launchroom-profile-boundary-guard",
    "launchroom-profile-smoke-tests",
    "launchroom-memory-stack",
    "launchroom-context-and-session-search",
    "launchroom-messaging-readiness",
    "launchroom-mcp-readiness",
    "launchroom-provider-readonly-inventory",
    "launchroom-cloudroom-readiness",
    "launchroom-saas-operator-kit",
    "launchroom-first-slice-planning",
    "launchroom-local-pilot-execution",
    "launchroom-project-plan-integrity",
    "launchroom-agent-execution-readiness",
    "launchroom-workspace-hygiene",
    "launchroom-execution-evidence-binder",
]

REQUIRED_SELF_TEST_FILES = [
    "reports/LAUNCHROOM_SYSTEM_DIAGNOSTIC_REPORT.yaml",
    "reports/LAUNCHROOM_SYSTEM_SETUP_PLAN.yaml",
    "reports/LAUNCHROOM_SMOKE_TEST_REPORT.yaml",
    "LAUNCHROOM_PROFILE_STATE.yaml",
]


def fail(message: str) -> None:
    print("FAIL: " + message)
    raise SystemExit(1)


def read(path: Path) -> str:
    if not path.exists():
        fail(f"missing required file: {path.relative_to(ROOT).as_posix()}")
    return path.read_text(encoding="utf-8", errors="ignore")


def load_yaml(path: Path) -> dict:
    try:
        data = yaml.safe_load(read(path))
    except Exception as exc:
        fail(f"YAML parse failed for {path.relative_to(ROOT).as_posix()}: {exc}")
    if not isinstance(data, dict):
        fail(f"YAML file must parse as mapping: {path.relative_to(ROOT).as_posix()}")
    return data


def require_contains(path: Path, needle: str, label: str) -> None:
    if needle.lower() not in read(path).lower():
        fail(f"missing {label} in {path.relative_to(ROOT).as_posix()}: {needle}")


def require_no_secrets(path: Path) -> None:
    text = read(path)
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            fail(f"secret-like value in {path.relative_to(ROOT).as_posix()}")


def find_powershell() -> str | None:
    for candidate in ("pwsh", "powershell.exe", "powershell"):
        found = shutil.which(candidate)
        if found:
            return found
    return None


def validate_source_contracts() -> None:
    for path in REQUIRED_FULL_SYSTEM_FILES:
        if not path.exists():
            fail(f"missing v0.7 source artifact: {path.relative_to(ROOT).as_posix()}")
        require_no_secrets(path)

    stage_map = load_yaml(FULL_SYSTEM_DIR / "launchroom-v0.7-stage-map.yaml")
    if stage_map.get("artifact_id") != "LAUNCHROOM_V0_7_STAGE_MAP":
        fail("stage map artifact_id mismatch")
    stages = stage_map.get("stages", [])
    if [stage.get("id") for stage in stages] != REQUIRED_STAGE_IDS:
        fail("v0.7 stage ids/order mismatch")
    stage_1 = stages[1]
    if "record_active_conversation_model_as_current_session_evidence" not in stage_1.get("agent_actions", []):
        fail("stage_1 must record active conversation model instead of early standalone model/provider blocker")
    if "run_smoke_tests_after_setup" not in stage_1.get("agent_actions", []):
        fail("stage_1 must run smoke tests after setup")
    stage_3 = stages[3]
    if "install_or_stage_full_curated_launchroom_skillpack" not in stage_3.get("agent_actions", []):
        fail("stage_3 must install/stage full curated skillpack")
    if "default_profile_role_engineering_saas_profile_factory" not in stage_3.get("pass_requires", []):
        fail("stage_3 must require engineering SaaS profile factory role")

    inventory = load_yaml(FULL_SYSTEM_DIR / "full-system-software-and-capability-inventory.yaml")
    categories = [category.get("id") for category in inventory.get("software_categories", [])]
    for category in REQUIRED_SOFTWARE_CATEGORIES:
        if category not in categories:
            fail(f"full software matrix missing category: {category}")
    if inventory.get("policy", {}).get("not_a_small_checklist") is not True:
        fail("software inventory must explicitly reject tiny checklist mode")
    if inventory.get("policy", {}).get("missing_required_items_create_repair_or_install_plan") is not True:
        fail("software inventory must require repair/install plan for missing required items")

    skillpack = load_yaml(FULL_SKILLPACK)
    if skillpack.get("policy", {}).get("full_curated_skill_package") is not True:
        fail("v0.7 skillpack must be full curated package")
    if skillpack.get("policy", {}).get("skill_bodies_and_machine_instructions_language") != "en":
        fail("skillpack must require English technical skill bodies")
    required_new = skillpack.get("required_new_launchroom_skills_to_author", [])
    for skill_name in REQUIRED_NEW_SKILLS:
        if skill_name not in required_new:
            fail(f"v0.7 skillpack missing required skill name: {skill_name}")
        skill_path = PROFILE_DIST / "skills" / "launchroom-full-system" / skill_name / "SKILL.md"
        if not skill_path.exists():
            fail(f"profile distribution missing full-system skill: {skill_name}")
        skill_text = read(skill_path)
        if f"name: {skill_name}" not in skill_text:
            fail(f"skill frontmatter/name mismatch: {skill_name}")
        for marker in ["## When to Use", "## Procedure", "## Verification", "public LaunchRoom skill"]:
            if marker not in skill_text:
                fail(f"skill {skill_name} missing marker: {marker}")

    contract = load_yaml(CONTRACT)
    if contract.get("artifact_id") != "LAUNCHROOM_FULL_SYSTEM_BOOTSTRAP_CONTRACT_v0_7":
        fail("full-system bootstrap contract artifact_id mismatch")
    if contract.get("default_profile_role") != "engineering_saas_profile_factory":
        fail("contract must require engineering_saas_profile_factory default role")
    if contract.get("model_provider_rule") != "active_conversation_is_current_session_evidence_target_profiles_smoke_later":
        fail("contract must encode corrected model/provider rule")

    source = json.loads(read(SOURCE))
    full = source.get("full_system_bootstrap_contract", {})
    if full.get("enabled") is not True:
        fail("source launchroom.starter must enable full_system_bootstrap_contract")
    if full.get("contract") != "contracts/launchroom-full-system-bootstrap-contract.yaml":
        fail("source full_system_bootstrap_contract must point to contract")
    for recipe in ["source/recipes/full-system-bootstrap.json"]:
        if recipe not in source.get("recipes", []):
            fail(f"source recipes missing {recipe}")


def validate_docs_and_generated() -> None:
    for path in [README, BOOTSTRAP, RUNBOOK, GENERATED_RUNBOOK, ROOT / "SKILL.md", ROOT / "generated" / "HERMES_SKILL.md"]:
        require_no_secrets(path)
    for path in [README, BOOTSTRAP, RUNBOOK, GENERATED_RUNBOOK]:
        require_contains(path, "Full-System Bootstrap", "v0.7 full-system entrypoint")
        require_contains(path, "Engineering SaaS Profile", "engineering default role")
    for path in [RUNBOOK, GENERATED_RUNBOOK]:
        require_contains(path, "active conversation proves the current model path is usable", "corrected model/provider rule")
        require_contains(path, "full software and capability matrix", "full software matrix rule")
        require_contains(path, "Stage 1 pass is impossible without smoke tests", "smoke test pass rule")
    require_contains(BOOTSTRAP, "Do not ask the user for the SaaS/project brief before Stage 5", "no early project onboarding")


def validate_installer_self_test() -> None:
    ps = find_powershell()
    if not ps:
        print("validate_full_system_bootstrap: installer self-test skipped (PowerShell not available)")
        return
    with tempfile.TemporaryDirectory(prefix="launchroom-v07-selftest-") as tmp:
        tmp_path = Path(tmp)
        args = [
            ps,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(INSTALLER),
            "-ProfileName",
            "launchroom-v07-selftest",
            "-ProjectName",
            "LaunchRoom v0.7 Self Test",
            "-UserLanguage",
            "auto",
            "-TestOutputRoot",
            str(tmp_path),
            "-Yes",
            "-NoToolsets",
        ]
        result = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=180)
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            fail("installer v0.7 self-test failed")
        output = result.stdout + result.stderr
        if re.search(r"(?mi)^status:\s*blocked\s*$", output):
            fail("installer v0.7 self-test reported BLOCKED")
        profile_root = tmp_path / "profiles" / "launchroom-v07-selftest"
        workspace_root = tmp_path / "workspace" / "launchroom-v07-selftest"
        for rel in REQUIRED_SELF_TEST_FILES:
            path = profile_root / rel
            if not path.exists():
                fail(f"installer self-test missing profile v0.7 file: {rel}")
            require_no_secrets(path)
        state = load_yaml(profile_root / "LAUNCHROOM_PROFILE_STATE.yaml")
        if state.get("default_profile_role") != "engineering_saas_profile_factory":
            fail("generated profile state must mark engineering SaaS profile factory role")
        diagnostic = load_yaml(profile_root / "reports" / "LAUNCHROOM_SYSTEM_DIAGNOSTIC_REPORT.yaml")
        if diagnostic.get("stage_id") != "stage_1_full_system_diagnostic_repair_setup_smoke":
            fail("system diagnostic report wrong stage_id")
        categories = diagnostic.get("full_system_categories", [])
        for category in REQUIRED_SOFTWARE_CATEGORIES:
            if category not in categories:
                fail(f"system diagnostic report missing category: {category}")
        smoke = load_yaml(profile_root / "reports" / "LAUNCHROOM_SMOKE_TEST_REPORT.yaml")
        if smoke.get("profile_work_allowed") is not True:
            fail("smoke test report must allow profile work after v0.7 setup")
        required_skill = profile_root / "skills" / "launchroom" / "launchroom-full-system" / "launchroom-system-diagnostic" / "SKILL.md"
        if not required_skill.exists():
            fail("installer did not copy full-system skillpack into profile")
        workspace_report = workspace_root / ".hermes" / "reports" / "software-purpose-map.yaml"
        purpose = load_yaml(workspace_report)
        if "full_system_categories" not in purpose:
            fail("workspace software purpose map must record full_system_categories")


def main() -> int:
    validate_source_contracts()
    validate_docs_and_generated()
    validate_installer_self_test()
    print("validate_full_system_bootstrap: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
