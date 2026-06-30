#!/usr/bin/env python3
from __future__ import annotations
import argparse, json, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "source" / "airmida_launchroom_agentpack.v0_1.json"
MARKER = "public LaunchRoom test package / not AIRMIDA authority"

def load(): return json.loads(SOURCE.read_text(encoding="utf-8"))
def render_stage_map(data):
    parts=[f"# AIRMIDA LaunchRoom Stage Map\n\n`{MARKER}`\n"]
    for s in data["stages"]:
        parts.append(f"## {s['id']} — {s['name']}\n\n**Promise:** {s['promise']}\n\n**User result:** {s['user_result']}\n\n**Allowed by default:** {', '.join(s['allowed_default_actions'])}\n\n**Blocked without gate:** {', '.join(s['blocked_without_gate'])}\n\n**Gate checks:**\n" + "\n".join("- "+c for c in s["gate_checks"]) + f"\n\n**Transition output:** `{s['transition_output']}`\n")
    return "\n".join(parts)
def wanted(data):
    return {
      ROOT/"generated"/"HERMES_SKILL.md": (ROOT/"SKILL.md").read_text(encoding="utf-8"),
      ROOT/"generated"/"INSTALL_RU.md": (ROOT/"INSTALL_RU.md").read_text(encoding="utf-8"),
      ROOT/"generated"/"START_HERE_RU.md": (ROOT/"START_HERE_RU.md").read_text(encoding="utf-8"),
      ROOT/"generated"/"FULL_SETUP_TEST_RU.md": (ROOT/"FULL_SETUP_TEST_RU.md").read_text(encoding="utf-8"),
      ROOT/"generated"/"RUN_ME_FIRST_RU.md": (ROOT/"RUN_ME_FIRST_RU.md").read_text(encoding="utf-8"),
      ROOT/"generated"/"STAGE_MAP_RU.md": render_stage_map(data),
    }
def main(argv=None):
    ap=argparse.ArgumentParser(); ap.add_argument("--check", action="store_true"); args=ap.parse_args(argv)
    data=load(); drift=[]
    for path, content in wanted(data).items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != content: drift.append(path.relative_to(ROOT).as_posix())
        else:
            path.parent.mkdir(parents=True, exist_ok=True); path.write_text(content, encoding="utf-8", newline="\n")
    print(json.dumps({"status":"pass" if not drift else "drift", "drift":drift, "checked_files":len(wanted(data))}, ensure_ascii=False))
    return 0 if not drift else 1
if __name__ == "__main__": raise SystemExit(main())
