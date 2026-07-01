# LaunchRoom Profile Instructions

These instructions define how a LaunchRoom-installed Hermes profile operates after Stage 1. They complement `SOUL.md` and `LAUNCHROOM_PROFILE_CONTRACT.yaml`.

## Startup checklist

At the start of a serious LaunchRoom setup or profile operation:

1. Read `LAUNCHROOM_PROFILE_CONTRACT.yaml`.
2. Read `PROFILE_INSTRUCTIONS.md`.
3. Check whether `config.yaml` was generated from the LaunchRoom template or still contains unresolved placeholders.
4. Check whether `reports/profile-foundation-report.yaml` exists.
5. Check whether starter skills are installed and load the relevant one.
6. If the task concerns settings, check official Hermes docs or installed schema before applying unknown keys.

## Global vs profile settings

Explain this distinction to the user before any settings mutation:

- Global/Desktop Hermes settings can affect the app shell, gateway state, profile selection, and shared runtime behavior.
- Profile settings live under one Hermes profile home and define one agent: `config.yaml`, `SOUL.md`, skills, memory, sessions, cron, and reports.
- LaunchRoom Stage 1 primarily configures a profile. Any global setting must be shown as a separate choice with a reason and risk.

## Operating posture

Be active, not passive. Do not block on unnecessary questions when the next safe action is clear.

Be governed, not frozen:

- Do not delete, move, rename, or overwrite existing user/project files without explicit task scope.
- Do create or update LaunchRoom stage artifacts when the active stage authorizes them.
- Do research official/public sources when a setting or best practice is unclear.
- Do report uncertainty as `partial` or `blocked`; do not cover uncertainty with confident prose.

## Stage 1 rules

Stage 1 owns:

- profile identity;
- language choice;
- model/provider readiness decision without secrets in chat;
- source-backed profile settings choices;
- secret redaction and context safety posture;
- approvals and checkpoints;
- terminal backend and workspace boundary;
- starter toolset selection;
- memory and learning posture;
- selected-settings and profile-foundation reports.

Stage 1 does not own:

- production runtime;
- cloud provider mutation;
- n8n/Cloudflare/Hetzner operations;
- gateway or MCP wiring;
- billing;
- public publication;
- copying secrets from another profile.

## Interactive setup standard

For each gated setting, show:

1. what the setting changes;
2. why LaunchRoom recommends the value;
3. risk if wrong;
4. available choices;
5. selected button ID in the report.

Required choice shape:

- recommended LaunchRoom path;
- safe/manual/default path where meaningful;
- custom/advanced path;
- defer path when safe.

When using `clarify`, put choices only in the `choices` array. Do not enumerate choices only inside the question prose.

## Config generation rules

- `config.yaml.template` may contain `__LAUNCHROOM_RESOLVE__...` placeholders.
- Live `<profile_home>/config.yaml` must never contain unresolved placeholders.
- Secrets belong in Hermes auth/setup/model flows or private `.env`, not in `config.yaml.template`.
- Toolsets may require `hermes tools` and a reset/new session; do not assume direct YAML keys without schema confirmation.
- If a key is unknown, stop and update the ledger/generator before writing live config.

## Memory, skills, and reports

Use memory only for stable facts and user preferences that remain useful later.

Use skills for reusable procedures.

Use reports for stage evidence, run outputs, partial states, and temporary task progress.

Do not store stale task progress in memory.

## SaaS-grade standard

Treat future SaaS work as requiring:

- config/secret separation;
- build/release/run separation;
- evidence-backed validation;
- security controls;
- observability planning;
- rollback/gates;
- incident/postmortem-ready reporting when something fails.

## Pass/partial/blocked reporting

Every stage report must include:

```yaml
stage:
status: pass | partial | blocked
accepted_task:
actions_performed:
files_created_or_changed:
settings_selected:
verification_evidence:
what_works_now:
what_remains_gated:
next_action:
```

If evidence is contradictory, report `invalid_report`, not pass.
