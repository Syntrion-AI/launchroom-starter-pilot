# AIRMIDA LaunchRoom

`public LaunchRoom test package / not AIRMIDA authority`

AIRMIDA LaunchRoom is a staged Hermes Agent package for turning a fresh AI-agent user into a governed operator for a SaaS project.

This is a **public testing package**, not a production release and not AIRMIDA authority.

## Start here

If you use Hermes Agent, start with:

```text
START_HERE_RU.md
```

Or install the active skill from this repository:

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
```

Then open a new Hermes session and load the installed skill. If Hermes installs direct raw URLs under a branch-derived name, use the name shown by `hermes skills list`.

```text
/skill launchroom-starter-pilot
Я хочу пройти LaunchRoom Stage 1 для SaaS-проекта.
```

Fallback if the skill name differs:

```text
/skill main
Я хочу пройти LaunchRoom Stage 1 для SaaS-проекта.
```

## What this repo contains

- `SKILL.md` — active Hermes skill for the LaunchRoom guide.
- `START_HERE_RU.md` — paste-first Russian beginner entrypoint.
- `INSTALL_RU.md` — install/use instructions.
- `generated/` — generated active entrypoints and stage map.
- `source/airmida_launchroom_agentpack.v0_1.json` — source of truth.
- `scripts/build_agentpack.py` — regenerates active files and supports `--check`.
- `scripts/doctor.py` — validates the public package.
- `.github/workflows/validate.yml` — public CI validation.

## Stage ladder

| Stage | Name | Unlocks | Gate output |
|---|---|---|---|
| STAGE_1 | Starter Basic Safe Operator | I can talk to Hermes safely and understand what to set up next. | `STAGE_1_READINESS_REPORT` |
| STAGE_2 | Creator Communication and Content Room | I can use my agent to create, refine, and communicate useful SaaS content safely. | `STAGE_2_CREATOR_WORKFLOW_REPORT` |
| STAGE_3 | SaaS Project Builder Workspace | I have a bounded SaaS project workspace and can ask the agent to build locally with tests. | `STAGE_3_PROJECT_BUILDER_PACKET` |
| STAGE_4 | Governed Operator and Agent Team | My agent team can work on packets without losing gates, evidence, or boundaries. | `STAGE_4_GOVERNED_OPERATOR_REPORT` |
| STAGE_5 | CloudRoom Runtime Readiness | I know what runtime surfaces are needed and what must be explicitly approved before provisioning. | `STAGE_5_CLOUDROOM_READINESS_PACKET` |
| STAGE_6 | AgentOps SaaS Operations | My SaaS project can move toward real operations with observable, reversible, audited agent assistance. | `STAGE_6_AGENTOPS_OPERATING_PACKET` |

## Safety boundary

LaunchRoom does **not** ask for secrets in chat. It does **not** mutate cloud/runtime/provider/n8n/git/authority surfaces without separate explicit gates. Stage 5 and Stage 6 are readiness and operations design stages until an owner separately authorizes live action.

## Validate locally

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
```

## Publication status

```yaml
repo: Syntrion-AI/launchroom-starter-pilot
visibility: public
status: public_test_package
not_authority: true
not_production_release: true
```
