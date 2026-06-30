# AIRMIDA LaunchRoom

`public LaunchRoom test package / not AIRMIDA authority`

AIRMIDA LaunchRoom is a public real-test package for setting up a new Hermes Agent as a governed operator for a SaaS project.

## Use this first

Open:

```text
REAL_HERMES_SETUP_RU.md
```

Direct link:

```text
https://github.com/Syntrion-AI/launchroom-starter-pilot/blob/main/REAL_HERMES_SETUP_RU.md
```

This is not a file to summarize. It is a setup wizard prompt. It should guide Hermes through:

```text
Stage 1 health/model
Stage 2 profile/workspace
Stage 3 tools/skills/memory
Stage 4 gateway/messaging
Stage 5 SaaS operator kit
Stage 6 CloudRoom/AgentOps readiness
```

## Install as Hermes skill

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

Then in a new Hermes session:

```text
/skill launchroom-starter-pilot
Проведи меня через REAL_HERMES_SETUP для нового Hermes agent от Stage 1 до Stage 6.
```

If Hermes installs direct raw URLs under another name, use the name shown by `hermes skills list`.

## Validate repo

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
```

## Safety

No secrets in chat. No provider/cloud/runtime/n8n/git/production mutation without separate explicit gate.
