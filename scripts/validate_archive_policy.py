#!/usr/bin/env python3
from __future__ import annotations
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SUPERSEDED_ROOT = ['FULL_SETUP_TEST_RU.md','INSTALL_RU.md','REAL_HERMES_SETUP_RU.md','START_HERE_RU.md']

def main() -> int:
    manifest_path = ROOT/'archive/20260630-rebuild-v0_5/ARCHIVE_MANIFEST.json'
    if not manifest_path.exists():
        print('FAIL: archive manifest missing')
        return 1
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    moved = manifest.get('moved', [])
    if not moved:
        print('FAIL: archive manifest has no moved entries')
        return 1
    for item in SUPERSEDED_ROOT:
        if (ROOT/item).exists():
            print(f'FAIL: superseded root file still active: {item}')
            return 1
    for entry in moved:
        archived = ROOT/entry['new_path']
        if not archived.exists():
            print(f'FAIL: archived file missing: {entry["new_path"]}')
            return 1
    print('validate_archive_policy: ok')
    return 0
if __name__ == '__main__':
    raise SystemExit(main())
