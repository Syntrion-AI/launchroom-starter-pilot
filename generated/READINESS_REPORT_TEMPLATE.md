# LaunchRoom Stage Readiness Report Template

`public LaunchRoom test package / not AIRMIDA authority`

```yaml
stage: STAGE_N
status: pass | pass_with_owner_acceptance | blocked | not_started
what_is_ready:
  - ...
blocked:
  - item: ...
    reason: ...
evidence:
  - source: chat | file | command | owner_acceptance
    detail: ...
next_action: exactly_one_safe_next_action
forbidden_actions_preserved:
  - secret_readback
  - runtime_provider_mutation_without_gate
  - git_publication_without_gate
```
