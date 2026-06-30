#!/usr/bin/env python3
from __future__ import annotations
import json, re, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
MARKER = 'public LaunchRoom test package / not AIRMIDA authority'
REQUIRED = ['README.md', 'REAL_HERMES_SETUP_RU.md', 'FULL_SETUP_TEST_RU.md', 'RUN_ME_FIRST_RU.md', 'START_HERE_RU.md', 'INSTALL_RU.md', 'SKILL.md', 'source/airmida_launchroom_agentpack.v0_1.json', 'scripts/build_agentpack.py', 'scripts/doctor.py', 'scripts/validate_behavior_contract.py', 'contracts/agentpack_contract.v0_1.json', 'generated/HERMES_SKILL.md', 'generated/STAGE_MAP_RU.md', '.github/workflows/validate.yml']
SECRET_RE = re.compile(r"(sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{20,}|BEGIN (RSA|OPENSSH|PRIVATE) KEY|AKIA[0-9A-Z]{16})")
REQUIRED_PHRASES = [
    "BOOTSTRAP_0",
    "HERMES_TERMINAL_BACKEND_UNAVAILABLE",
    "stage_1_to_6_status: not_started",
    "Stage 1",
    "Stage 6",
    "LAUNCHROOM_ONE_LINK_SETUP_RU",
    "hermes setup terminal",
    "hermes status",
    "hermes doctor",
    "hermes tools list",
    "hermes gateway status",
    "PowerShell",
    "Никогда не проси секреты",
    "self-memory",
    "manual_only",
    "Cloudflare",
    "Hetzner",
    "n8n",
    "not AIRMIDA authority",
    "RUN_ME_FIRST_RU.md",
]
TEXT_SUFFIXES = {".md", ".json", ".py", ".yml", ".yaml", ".txt"}
def main():
    issues=[]; warnings=[]
    data=json.loads((ROOT/"source/airmida_launchroom_agentpack.v0_1.json").read_text(encoding="utf-8"))
    if "bootstrap_0" not in data: issues.append("missing bootstrap_0 contract")
    if len(data.get("stages", [])) != 6: issues.append("expected 6 stages")
    required_statuses={"pass","blocked","deferred","manual_only","not_started","not_applicable"}
    if not required_statuses.issubset(set(data.get("status_contract", []))):
        issues.append("status_contract missing required honest statuses")
    for rel in REQUIRED:
        p=ROOT/rel
        if not p.exists(): issues.append(f"missing required file: {rel}")
    all_text=[]; scanned=0; secret_hits=[]; marker_missing=[]
    for p in ROOT.rglob("*"):
        if not p.is_file() or p.suffix.lower() not in TEXT_SUFFIXES: continue
        if ".git" in p.parts or "__pycache__" in p.parts: continue
        rel=p.relative_to(ROOT).as_posix()
        if rel.startswith("evidence/"): continue
        text=p.read_text(encoding="utf-8", errors="ignore"); all_text.append(text); scanned+=1
        if SECRET_RE.search(text): secret_hits.append(rel)
        if rel in REQUIRED and MARKER not in text and rel not in ["source/airmida_launchroom_agentpack.v0_1.json", "contracts/agentpack_contract.v0_1.json", ".github/workflows/validate.yml"]:
            marker_missing.append(rel)
    joined="\n".join(all_text)
    for phrase in REQUIRED_PHRASES:
        if phrase not in joined: issues.append(f"missing phrase: {phrase}")
    run=(ROOT/"RUN_ME_FIRST_RU.md").read_text(encoding="utf-8") if (ROOT/"RUN_ME_FIRST_RU.md").exists() else ""
    forbidden_claim_guard=["If Bootstrap 0 is blocked, report Stage 1–6 as `not_started`, not pass", "forbidden_status_pattern"]
    for phrase in forbidden_claim_guard:
        if phrase not in run: issues.append(f"missing fake-pass guard: {phrase}")
    if secret_hits: issues.append(f"secret-like hits: {secret_hits}")
    if marker_missing: issues.append(f"marker missing: {marker_missing}")
    result={"status":"pass" if not issues else "fail", "issues":issues, "warnings":warnings, "files_scanned":scanned}
    print(json.dumps(result, ensure_ascii=False))
    return 0 if not issues else 2
if __name__ == "__main__": raise SystemExit(main())
