# Under the Hood

`public LaunchRoom test package / not AIRMIDA authority`

AIRMIDA LaunchRoom is packaged as an active agentpack, not as passive documentation only.

## Technical pattern

```text
source/airmida_launchroom_agentpack.v0_1.json
-> scripts/build_agentpack.py
-> generated active entrypoints
-> scripts/doctor.py
-> GitHub Actions validation
```

## Inspired by Squad, adapted for Hermes

Adopted patterns:

- source-of-truth config;
- generated active entrypoints;
- build `--check` drift detection;
- doctor/readiness validation;
- repo-native agent export concept;
- coordinator restraint;
- state/authority/runtime separation.

Not adopted:

- Copilot-specific runtime assumptions;
- large fantasy agent roster as default UX;
- automatic cloud/runtime mutation;
- authority transfer from local agent state.

## Stage transition invariant

The package defines Stage 1-6, but the agent must only operate inside the active stage. The next stage unlocks only after the previous stage gate passes or the owner explicitly accepts the transition.

## Public safety invariant

This public package never needs secret values. Runtime, provider, cloud, n8n, git publication, billing, or production operations require separate explicit gates outside this public test package.
