#!/usr/bin/env python3
"""Validate LaunchRoom Starter Pilot repo seed.

Local-only validator. It does not contact GitHub, does not read secrets, and does not mutate Hermes profile, provider, gateway, cloud, or runtime surfaces.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

import yaml

TEXT_SUFFIXES = {".md", ".yaml", ".yml", ".json", ".py", ".txt"}
REQUIRED_FILES = [
    "README.md",
    "START_HERE.md",
    "i18n/ru/START_HERE.ru.md",
    "UNDER_THE_HOOD.md",
    "DEFAULT_PROFILE_TEST.md",
    "PUBLICATION_GATE.md",
    "contracts/stage1-machine-contract.yaml",
    "contracts/stage1-language-policy.yaml",
    "contracts/stage1-memory-policy.yaml",
    "contracts/stage1-profile-scope.yaml",
    "scripts/validate_pilot_seed.py",
]
SECRET_PATTERNS = [
    re.compile(r"sk-[A-Za-z0-9]{16,}"),
    re.compile(r"ghp_[A-Za-z0-9]{16,}"),
    re.compile(r"xox[baprs]-[A-Za-z0-9-]{16,}"),
    re.compile(r"AKIA[0-9A-Z]{16}"),
    re.compile(r"BEGIN (RSA|OPENSSH|PRIVATE) KEY"),
    re.compile(r"(?i)(password|token|api[_-]?key)\s*[:=]\s*[^\s`]+"),
]
FORBIDDEN_UNGUARDED = [
    "git push",
    "wrangler deploy",
    "hcloud server create",
    "hcloud server delete",
    "n8n execute",
    "docker compose up",
    "gateway setup",
]
REQUIRED_CONCEPTS = [
    "user_facing_layer",
    "under_the_hood_layer",
    "canonical_project_language",
    "active_language",
    "memory_char_limit: 6000",
    "default Hermes profile",
    "no_secrets_in_chat",
    "readiness report",
]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def guarded(text: str, idx: int) -> bool:
    ctx = text[max(0, idx - 140): idx + 180].lower()
    return any(marker in ctx for marker in ["blocked", "do not", "must not", "not ", "without", "gate", "forbidden"])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=".")
    ap.add_argument("--out", default="evidence/pilot_seed_validation_latest.json")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    out = (root / args.out).resolve() if not Path(args.out).is_absolute() else Path(args.out)

    missing = [p for p in REQUIRED_FILES if not (root / p).exists()]
    yaml_errors = []
    secret_hits = []
    unguarded_hits = []
    hashes = {}
    all_text = []
    scanned = 0

    for path in root.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        rel = path.relative_to(root).as_posix()
        if rel.startswith("evidence/"):
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        all_text.append(text)
        scanned += 1
        hashes[rel] = sha256(path)
        if path.suffix.lower() in {".yaml", ".yml"}:
            try:
                yaml.safe_load(text)
            except Exception as exc:  # noqa: BLE001
                yaml_errors.append({"file": rel, "error": str(exc)})
        for pat in SECRET_PATTERNS:
            for match in pat.finditer(text):
                secret_hits.append({"file": rel, "pattern": pat.pattern, "sample": match.group(0)[:12] + "..."})
        lower = text.lower()
        if rel != "scripts/validate_pilot_seed.py":
            for phrase in FORBIDDEN_UNGUARDED:
                pos = lower.find(phrase)
                while pos != -1:
                    if not guarded(lower, pos):
                        unguarded_hits.append({"file": rel, "phrase": phrase})
                    pos = lower.find(phrase, pos + len(phrase))

    joined = "\n".join(all_text)
    concept_missing = [c for c in REQUIRED_CONCEPTS if c not in joined]

    result = {
        "status": "pass",
        "root": root.as_posix(),
        "files_scanned": scanned,
        "missing": missing,
        "yaml_errors": yaml_errors,
        "secret_hits": secret_hits,
        "unguarded_hits": unguarded_hits,
        "concept_missing": concept_missing,
        "hashes": hashes,
    }
    if missing or yaml_errors or secret_hits or unguarded_hits or concept_missing:
        result["status"] = "review_required"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({k: result[k] for k in ["status", "files_scanned", "missing", "yaml_errors", "secret_hits", "unguarded_hits", "concept_missing"]}, ensure_ascii=False))
    return 0 if result["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
