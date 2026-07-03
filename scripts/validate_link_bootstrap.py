#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9]{20,}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{20,}"),
    re.compile(r"xapp-[A-Za-z0-9-]{20,}"),
    re.compile(r"ghp_[A-Za-z0-9]{20,}"),
    re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
]

REQUIRED_FILES = [
    "BOOTSTRAP_WITH_HERMES.md",
    "RUN_ME_FIRST.md",
    "README.md",
    "START_HERE.md",
    "SKILL.md",
    "generated/RUN_ME_FIRST.md",
    "generated/HERMES_SKILL.md",
    "contracts/launchroom-link-bootstrap-contract.json",
    "source/recipes/link-bootstrap.json",
    "scripts/install_launchroom_profile.ps1",
]

REQUIRED_AGENT_ACTIONS = [
    "identify_setup_package",
    "prefer_release_tag",
    "read_bootstrap_before_runbook",
    "ask_project_state",
    "offer_self_test_first",
    "run_self_test_before_real_setup",
    "request_gate_before_mutation",
    "verify_outputs",
    "report_pass_partial_blocked",
]

FORBIDDEN_ACTIONS = [
    "ask_secret_in_chat",
    "copy_auth_json",
    "copy_env_values",
    "mutate_provider_without_gate",
    "mutate_cloud_runtime_without_gate",
    "enable_gateway_without_gate",
    "create_release_or_tag_without_gate",
]

REQUIRED_BOOTSTRAP_MARKERS = [
    "If a Hermes agent receives this repository or release URL",
    "Treat this as a setup package, not a passive article",
    "Prefer the latest stable GitHub Release",
    "Read `RUN_ME_FIRST.md` before other files",
    "Ask whether the user has an existing project",
    "Run `-TestOutputRoot` self-test before real setup",
    "Request explicit approval before real profile/workspace mutation",
    "Never ask for secrets in chat",
    "Stop before runtime/provider/cloud/n8n/gateway/secret actions unless separately gated",
]

REQUIRED_RUNBOOK_MARKERS = [
    "Link-to-Operator Bootstrap",
    "If a Hermes agent receives only a GitHub repository or release link",
    "prefer the release tag over mutable `main`",
    "Does the user already have a project?",
    "self-test only",
    "new blank SaaS workspace",
    "existing project workspace",
    "advanced/custom",
    "Run the `-TestOutputRoot` self-test before any real setup",
    "Do not ask for secret values in chat",
]

REQUIRED_ENTRYPOINT_MARKERS = {
    "README.md": ["BOOTSTRAP_WITH_HERMES.md", "Link-to-Operator Bootstrap"],
    "START_HERE.md": ["BOOTSTRAP_WITH_HERMES.md", "Link-to-Operator Bootstrap"],
    "SKILL.md": ["BOOTSTRAP_WITH_HERMES.md", "link-to-operator bootstrap"],
}


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read_text(relative: str) -> str:
    path = ROOT / relative
    if not path.exists():
        fail(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8", errors="ignore")


def require_contains(text: str, needle: str, label: str) -> None:
    if needle.lower() not in text.lower():
        fail(f"missing {label}: {needle}")


def require_no_secrets(relative: str, text: str) -> None:
    for pattern in SECRET_PATTERNS:
        if pattern.search(text):
            fail(f"secret-like marker in {relative}")


def load_json(relative: str) -> dict:
    try:
        return json.loads(read_text(relative))
    except json.JSONDecodeError as exc:
        fail(f"invalid JSON in {relative}: {exc}")


def main() -> int:
    for relative in REQUIRED_FILES:
        if not (ROOT / relative).exists():
            fail(f"missing required file: {relative}")

    texts = {relative: read_text(relative) for relative in REQUIRED_FILES if (ROOT / relative).suffix in {".md", ".py", ".ps1"}}
    for relative, text in texts.items():
        require_no_secrets(relative, text)

    bootstrap = texts["BOOTSTRAP_WITH_HERMES.md"]
    for marker in REQUIRED_BOOTSTRAP_MARKERS:
        require_contains(bootstrap, marker, "bootstrap protocol marker")

    runbook = texts["RUN_ME_FIRST.md"]
    generated_runbook = texts["generated/RUN_ME_FIRST.md"]
    for marker in REQUIRED_RUNBOOK_MARKERS:
        require_contains(runbook, marker, "runbook bootstrap marker")
        require_contains(generated_runbook, marker, "generated runbook bootstrap marker")

    if runbook.lower().find("-testoutputroot") > runbook.lower().find("primary setup tool"):
        fail("runbook must introduce -TestOutputRoot self-test before real setup path")

    for relative, markers in REQUIRED_ENTRYPOINT_MARKERS.items():
        text = texts[relative]
        for marker in markers:
            require_contains(text, marker, f"{relative} entrypoint marker")

    contract = load_json("contracts/launchroom-link-bootstrap-contract.json")
    if contract.get("artifact_id") != "launchroom-link-bootstrap-contract-v0-1":
        fail("contract artifact_id mismatch")
    entrypoints = contract.get("required_entrypoints", [])
    for required in ["BOOTSTRAP_WITH_HERMES.md", "RUN_ME_FIRST.md", "scripts/install_launchroom_profile.ps1"]:
        if required not in entrypoints:
            fail(f"contract missing required entrypoint: {required}")
    for action in REQUIRED_AGENT_ACTIONS:
        if action not in contract.get("required_agent_actions", []):
            fail(f"contract missing required agent action: {action}")
    for action in FORBIDDEN_ACTIONS:
        if action not in contract.get("forbidden_actions", []):
            fail(f"contract missing forbidden action: {action}")

    recipe = load_json("source/recipes/link-bootstrap.json")
    if recipe.get("artifact_id") != "launchroom-link-bootstrap-recipe-v0-1":
        fail("recipe artifact_id mismatch")
    if recipe.get("contract") != "contracts/launchroom-link-bootstrap-contract.json":
        fail("recipe must point to link bootstrap contract")
    for mode in ["self_test_only", "new_blank_saas_workspace", "existing_project_workspace", "advanced_custom"]:
        if mode not in recipe.get("setup_modes", []):
            fail(f"recipe missing setup mode: {mode}")
    if recipe.get("self_test_before_real_setup") is not True:
        fail("recipe must require self-test before real setup")
    if recipe.get("release_tag_preferred") is not True:
        fail("recipe must prefer release tag over mutable main")
    if recipe.get("secrets_in_chat_forbidden") is not True:
        fail("recipe must forbid secrets in chat")

    source = load_json("source/launchroom.starter.v0_5.json")
    recipes = source.get("recipes", [])
    if "source/recipes/link-bootstrap.json" not in recipes:
        fail("source contract must include link-bootstrap recipe")
    bootstrap_contract = source.get("link_bootstrap_contract", {})
    if bootstrap_contract.get("enabled") is not True:
        fail("source link_bootstrap_contract must be enabled")
    if bootstrap_contract.get("contract") != "contracts/launchroom-link-bootstrap-contract.json":
        fail("source link_bootstrap_contract must point to contract")
    for mode in ["self_test_only", "new_blank_saas_workspace", "existing_project_workspace", "advanced_custom"]:
        if mode not in bootstrap_contract.get("setup_modes", []):
            fail(f"source link bootstrap missing setup mode: {mode}")

    print("validate_link_bootstrap: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
