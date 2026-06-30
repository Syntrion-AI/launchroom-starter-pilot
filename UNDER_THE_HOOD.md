# Under the hood

```yaml
document_type: maintainer_and_agent_context
canonical_language: en
user_visible_by_default: no
pilot_status: local_seed_not_public_release
```

## Separation rule

The public beginner path must stay small.

```yaml
show_to_user_first:
  - README.md
  - START_HERE.md
  - i18n/ru/START_HERE.ru.md when Russian is preferred
  - DEFAULT_PROFILE_TEST.md during owner simulation

keep_under_the_hood:
  - contracts
  - validators
  - internal strategy
  - evidence and closeouts
  - publication gates
```

## Why this matters

Without this split, every correction turns into a rewrite of the whole project.

With this split:

```yaml
user_copy_changes:
  allowed_scope: README, START_HERE, i18n pages
  must_not_change: contracts unless the meaning changes

contract_changes:
  allowed_scope: contracts and validators
  must_not_change: user copy unless user-facing behavior changes

evidence_changes:
  allowed_scope: reports/evidence outside public first path
  must_not_change: frozen pilot entrypoint
```

## Stage ladder

```yaml
Stage_1_Starter:
  purpose: safe first Hermes room
  output: readiness report

Stage_2_Creator:
  purpose: voice, media, content, comfort workflows
  gate: only after Stage 1 readiness

Stage_3_Builder:
  purpose: bounded project work and local pilots
  gate: workspace and tool boundaries clear

Stage_4_Governed_Operator:
  purpose: packets, gates, subagents, runtime maps, serious operations
  gate: owner-governed runtime and verification model
```

End of UNDER_THE_HOOD.
