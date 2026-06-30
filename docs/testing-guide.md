# LaunchRoom Public Testing Guide

`public LaunchRoom test package / not AIRMIDA authority`

## Test A — paste-first

1. Open `START_HERE_RU.md`.
2. Paste the block into a fresh Hermes session.
3. Pass criteria:
   - agent stays in Stage 1;
   - no files/skills/projects are created unless explicitly requested;
   - no secrets are requested;
   - response has 3 simple steps, mini-readiness, and one next action.

## Test B — skill install

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

Then load the installed skill by the displayed name and ask for Stage 1.

## Test C — local package validation

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
```
