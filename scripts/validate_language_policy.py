#!/usr/bin/env python3
from __future__ import annotations
import json, re
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
CYRILLIC_RE = re.compile(r'[\u0400-\u04FF]')
ALLOWED_PREFIXES = ('archive/','source/locales/','generated/locale-examples/')
SCAN_EXTS = {'.md','.json','.py','.ps1','.yaml','.yml'}

def main() -> int:
    policy = json.loads((ROOT/'contracts/launchroom-language-policy.json').read_text(encoding='utf-8'))
    if policy.get('canonical_documentation_language') != 'English':
        print('FAIL: canonical docs must be English')
        return 1
    if policy.get('closed_language_allowlist') is not False:
        print('FAIL: closed language allowlist must be false')
        return 1
    offenders = []
    for path in ROOT.rglob('*'):
        if not path.is_file() or '.git' in path.parts or path.suffix not in SCAN_EXTS:
            continue
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith(ALLOWED_PREFIXES):
            continue
        if CYRILLIC_RE.search(path.read_text(encoding='utf-8', errors='ignore')):
            offenders.append(rel)
    if offenders:
        print('FAIL: localized text outside allowed paths')
        for item in offenders:
            print(f'- {item}')
        return 1
    print('validate_language_policy: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
