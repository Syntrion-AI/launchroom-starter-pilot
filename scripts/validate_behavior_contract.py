#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / "RUN_ME_FIRST_RU.md"
SKILL = ROOT / "SKILL.md"
SOURCE = ROOT / "source" / "airmida_launchroom_agentpack.v0_1.json"
MARKER = "public LaunchRoom test package / not AIRMIDA authority"


def require(text: str, needle: str, issues: list[str], label: str = "") -> None:
    if needle not in text:
        issues.append(f"missing {label or needle}")


def main() -> int:
    issues: list[str] = []
    run = RUN.read_text(encoding="utf-8")
    skill = SKILL.read_text(encoding="utf-8")
    data = json.loads(SOURCE.read_text(encoding="utf-8"))

    # The clean-Windows stress failure: terminal backend broken must stop before stages.
    require(run, "WSL execvpe(/bin/bash) failed", issues, "Windows/WSL failure trigger")
    require(run, "BOOTSTRAP_0_BLOCKED", issues, "explicit Bootstrap blocked marker")
    require(run, "HERMES_TERMINAL_BACKEND_UNAVAILABLE", issues, "terminal blocker id")
    require(run, "stage_1_to_6_status: not_started", issues, "stage not-started rule")
    require(run, "If Bootstrap 0 is blocked, report Stage 1–6 as `not_started`, not pass", issues, "no fake pass rule")
    require(run, "Local — этот компьютер", issues, "beginner Local explanation")
    require(run, "Docker — изолированная коробка", issues, "beginner Docker explanation")
    require(run, "partial_manual_recovery", issues, "partial manual recovery status")
    require(run, "После успешного `hermes setup terminal` НЕ объявляй Bootstrap 0 pass", issues, "no pass after external setup terminal")
    require(run, "Открой новый Hermes chat и вставь эту же ссылку снова", issues, "restart/new chat gate")
    require(run, "agent_direct_terminal_check: pass", issues, "direct terminal pass gate")
    require(run, "examples inside this runbook", issues, "examples-not-evidence rule")
    require(run, "example_errors_are_not_current_facts", issues, "example errors are not current facts")
    require(run, "invalid_bootstrap_report", issues, "contradictory evidence guard")
    require(run, "If Stage 1 is pass, the only forward `one_next_action` is Stage 2", issues, "Stage 1 only-forward rule")
    require(run, "Запрещено после Stage 1 просить: “пришли суть SaaS-проекта”", issues, "no SaaS brief before Stage 6")
    require(run, "Decision UI / Clarify Button Contract", issues, "decision UI contract")
    require(run, "clarify_tool_rule", issues, "clarify tool shape rule")
    require(run, "question: \"Stage 1 завершён. Что делаем дальше?\"", issues, "Stage 1 clarify gate")
    require(run, "Stage flow contract", issues, "stage flow contract")
    require(run, "Короткие описания Stage для пользователя", issues, "beginner stage descriptions")

    # The previous public-package failure: link summarization instead of execution.
    require(run, "не отвечай “ссылка работает”", issues, "no link-summary rule")
    require(run, "Начни `BOOTSTRAP_0`", issues, "start Bootstrap instruction")
    require(skill, "Do not summarize the runbook. Start `BOOTSTRAP_0`.", issues, "skill start instruction")

    # Customer onboarding must not silently mutate memory/profile.
    require(run, "Не обновляй memory/profile/self-improvement", issues, "no self-improvement rule")
    require(skill, "No memory/profile/self-improvement updates during onboarding unless explicitly requested.", issues, "skill no self-improvement rule")

    # Honest status vocabulary must be machine-visible.
    expected = {"pass", "blocked", "deferred", "manual_only", "partial_manual_recovery", "not_started", "not_applicable"}
    actual = set(data.get("status_contract", []))
    missing_statuses = sorted(expected - actual)
    if missing_statuses:
        issues.append(f"missing status contract values: {missing_statuses}")

    if "bootstrap_0" not in data:
        issues.append("missing source bootstrap_0")
    if "decision_ui_contract" not in data:
        issues.append("missing source decision_ui_contract")
    if "evidence_discipline" not in data:
        issues.append("missing source evidence_discipline")
    if "stage_flow_contract" not in data:
        issues.append("missing source stage_flow_contract")
    if len(data.get("stages", [])) != 6:
        issues.append("expected exactly 6 source stages after bootstrap")
    stage_1 = next((s for s in data.get("stages", []) if s.get("id") == "STAGE_1"), {})
    if stage_1.get("next_gate", {}).get("only_forward_stage") != "STAGE_2":
        issues.append("Stage 1 next_gate must only forward to STAGE_2")
    forbidden_after_stage_1 = set(stage_1.get("forbidden_after_pass", []))
    if "ask SaaS project brief" not in forbidden_after_stage_1:
        issues.append("Stage 1 must forbid SaaS project brief before Stage 6")

    result = {"status": "pass" if not issues else "fail", "issues": issues}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not issues else 2


if __name__ == "__main__":
    raise SystemExit(main())
