# LaunchRoom Sanitized Abstraction Boundary

> Public LaunchRoom test package / not AIRMIDA authority.

This file fixes the boundary between **AIRMIDA internal operator skills** and **LaunchRoom sanitized abstraction skills**.

## Rule

LaunchRoom may learn from AIRMIDA operating patterns, but it must not mutate, rename, generalize, or publish AIRMIDA internal skills as customer-facing skills.

```yaml
source_airmida_skill_mutation_allowed: false
airmida_internal_skills_are_public_launchroom_skills: false
sanitized_skills_require_new_launchroom_names: true
sanitized_skills_default_install: false
```

## Source lineage vs product skill

| Layer | Role | Can be edited for LaunchRoom? |
|---|---|---:|
| AIRMIDA internal skills such as `airmida-memory-stack-operator` | Working operator procedures for the AIRMIDA profile/workspace | No |
| AIRMIDA governance/evidence artifacts | Pattern evidence and source lineage | No |
| LaunchRoom sanitized abstraction skills | New customer-safe `launchroom-*` skills derived from proven patterns | Yes, inside LaunchRoom source only |
| Skillpack Registry | Gated recommendation surface | Yes, but it does not install or promote skills by itself |

## Required creation path

New sanitized skills belong under:

```text
source/skills/launchroom-sanitized-abstractions/<launchroom-skill-name>/SKILL.md
```

They must:

1. use a `launchroom-*` name;
2. describe generic LaunchRoom behavior, not AIRMIDA operations;
3. cite AIRMIDA only as source lineage/pattern evidence;
4. remove private paths, profile names, runtime assumptions, secrets, and authority claims;
5. keep default install disabled until a separate owner promotion gate;
6. pass `scripts/validate_skillpack_registry.py`.

## Forbidden agent behavior

Agents must not:

- patch `airmida-*` skills to make them more public;
- copy AIRMIDA paths such as project roots, profile-specific runtime state, or operator packet paths into LaunchRoom public skills;
- treat `.hermes` working artifacts as AIRMIDA authority;
- treat source-lineage skills as installed customer skills;
- install, enable, promote, or publish sanitized abstraction skills without a separate gate.

## Sanctioned abstractions

The currently sanctioned LaunchRoom sanitized abstraction skills are:

```yaml
- launchroom_sanitized_skill: launchroom-memory-governance
  source_internal_pattern: airmida-memory-stack-operator
  supporting_pattern: governed-agent-memory-substrate
  registry_pack: launchroom_sanitized_abstractions_pack
  default_install: false

- launchroom_sanitized_skill: launchroom-positive-result-capture
  source_internal_pattern: airmida-positive-result-capture
  supporting_pattern: governed-agent-engineering-standards
  registry_pack: launchroom_sanitized_abstractions_pack
  default_install: false

- launchroom_sanitized_skill: launchroom-tool-readiness-smoke
  source_internal_pattern: airmida-external-agent-tool-readiness
  supporting_pattern: governed-agent-engineering-standards
  registry_pack: launchroom_sanitized_abstractions_pack
  default_install: false
```

## Verification markers

A valid LaunchRoom sanitized abstraction package must keep these markers true:

```yaml
boundary_doc_present: true
source_airmida_skill_mutation_allowed: false
sanitized_skill_uses_launchroom_name: true
sanitized_skill_contains_private_airmida_paths: false
registry_recommends_not_installs: true
sanitized_abstraction_skills_count: 3
```
