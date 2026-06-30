# AIRMIDA LaunchRoom

`public LaunchRoom test package / not AIRMIDA authority`

AIRMIDA LaunchRoom is a public test package for walking a user through a full Hermes Agent setup path for a governed SaaS project.

This repository is not meant to be “read and summarized”. It contains an active setup prompt and skill.

## Use this first

Open:

```text
FULL_SETUP_TEST_RU.md
```

Direct link:

```text
https://github.com/Syntrion-AI/launchroom-starter-pilot/blob/main/FULL_SETUP_TEST_RU.md
```

Paste the block from that file into a new Hermes session. The agent should start the full master flow:

```text
Stage 1 -> Stage 2 -> Stage 3 -> Stage 4 -> Stage 5 -> Stage 6
```

## Install as Hermes skill

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

Then load the installed skill by the name shown in `hermes skills list`:

```text
/skill launchroom-starter-pilot
Проведи меня по полному LaunchRoom setup нового Hermes agent от Stage 1 до Stage 6.
```

If Hermes installs direct raw URLs under another name, use that displayed name.

## Expected behavior

The agent must not answer only “the file is available” or “I can summarize it”. It must run a setup wizard with gated checkpoints after every stage.

## Files

- `FULL_SETUP_TEST_RU.md` — main real-test entrypoint.
- `RUN_ME_FIRST_RU.md` — same as full setup entrypoint.
- `START_HERE_RU.md` — short pointer to full setup.
- `SKILL.md` — active Hermes skill.
- `docs/STAGE_MAP_RU.md` — stage map.
- `scripts/doctor.py` — package validator.
- `.github/workflows/validate.yml` — CI validation.

## Safety

No secrets in chat. No provider/cloud/runtime/n8n/git/production mutation without a separate explicit gate.
