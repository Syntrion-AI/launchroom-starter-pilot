---
name: launchroom-memory-governance
description: Use when helping a LaunchRoom user decide what belongs in memory, session history, reusable skills, local evidence, or project truth without exposing internal paths, providers, or operator state.
version: 0.1.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, memory, governance, skills, evidence, safety]
    related_skills: [launchroom-profile-operator, launchroom-saas-operator]
---

# LaunchRoom Memory Governance

## Overview

Use this skill to help a LaunchRoom user make safe memory decisions. It is a sanitized LaunchRoom abstraction derived from proven internal operating patterns. It is not an internal operator skill and does not assume any private project path, profile, memory provider, or authority file.

Core rule:

```text
memory helps recall; it is not project truth by itself.
```

## When to Use

Use this skill when the user asks:

- what the agent should remember;
- why the agent remembered or forgot something;
- whether a fact should become memory, a skill, a local evidence note, or a project truth file;
- how to move useful knowledge from one session/profile into another safely;
- how to design a beginner-safe memory policy for a LaunchRoom workspace.

## Do Not Use For

Do not use this skill to:

- change provider config;
- enable external memory services;
- upload raw transcripts;
- edit authority or project-truth files;
- write secrets, credentials, private keys, OAuth tokens, or passwords.

Those actions need separate gates and usually a different setup or governance skill.

## Beginner Example

If the user says, "Remember that I prefer short status updates," this can become a compact persistent memory after approval.

If the user says, "We finished Stage 6 today," do **not** save that as persistent memory. Keep it in session history or a local evidence report because it is task progress and can become stale.

If the user says, "Whenever we publish, run these five validation commands," turn that into a reusable skill or checklist instead of a memory note, because it is a procedure.

## Boundary

This skill is customer-safe and LaunchRoom-specific:

```yaml
source_lineage: internal operating patterns, sanitized
source_internal_skill_mutation_allowed: false
public_beginner_default: false
runtime_provider_change_allowed: false
secret_readback_allowed: false
authority_claim_allowed: false
```

If an internal project skill inspired this workflow, treat it as source lineage only. Do not patch, rename, or publish internal skills as LaunchRoom public skills.

## Memory layer map

| User need | Preferred layer | Why |
|---|---|---|
| Stable preference or environment fact | Persistent memory after user approval | Small, durable, injected in future sessions |
| Exact previous conversation | Session history/search | Preserves raw wording without polluting memory |
| Reusable procedure | Skill | Versioned procedural memory with triggers and verification |
| Local plan, evidence, or report | Workspace-local `.hermes` style evidence | Reviewable working artifact, not authority by default |
| Project truth | Explicit project truth/registry/canon file chosen by the project | Authority must be deliberate and governed |
| External memory provider | Separate gated setup | May involve credentials, cloud retention, cost, or privacy |

## Decision workflow

1. **Classify the fact.** Preference, environment fact, procedure, evidence pointer, project truth, or temporary task progress.
2. **Choose the lowest-risk layer.** Use session history for exact recall, skill for repeatable procedure, memory only for compact durable facts.
3. **Check staleness.** Do not save task progress, temporary decisions, or facts likely to expire soon as persistent memory.
4. **Check privacy.** Never store secrets, private keys, OAuth tokens, passwords, or sensitive personal content.
5. **Ask for the right gate.** External memory providers, transcript upload, provider switches, and authority-file writes require explicit gates.
6. **Verify.** Read back generated artifacts or memory summaries when the surface supports it, and report what changed.

Done when the chosen memory layer is explicit and no temporary or secret material is promoted accidentally.

## Safe distillation packet

When moving useful knowledge from a previous session/profile, use a small distillation packet instead of copying raw transcripts:

```yaml
source:
  session_or_excerpt:
  access_method: session_search | user_excerpt | export
scope:
  allowed_topics:
  excluded_topics:
classification:
  durable_fact:
  user_preference:
  procedure_candidate:
  evidence_pointer:
  project_truth_candidate:
routing:
  persistent_memory:
  skill_candidate:
  local_evidence:
  project_authority_review:
verification:
  secrets_found: 0
  source_lineage_attached: true
  authority_inflation_checked: true
```

## Gates

Requires explicit user gate before:

- writing persistent memory for project facts;
- installing or enabling external memory providers;
- changing profile/provider/runtime config;
- uploading transcripts or raw conversation logs;
- creating or promoting skills;
- editing project authority/truth files.

## Common Pitfalls

1. **Memory as truth.** Memory can be stale or partial. Verify against project truth before acting.
2. **Task diary pollution.** Completed task progress belongs in session history or evidence reports, not persistent memory.
3. **Raw transcript upload.** Distill first; do not upload everything by default.
4. **Skill vs memory confusion.** Procedures belong in skills; compact durable facts belong in memory.
5. **Hidden authority.** Local evidence and notes do not become authority unless the project explicitly promotes them.
6. **Internal-pattern leakage.** Do not copy internal project paths, profile state, or runtime assumptions into LaunchRoom customer skills.

## Verification Checklist

- [ ] The memory layer choice is explicit.
- [ ] No secrets or credential values are stored or printed.
- [ ] Temporary task progress was not saved as persistent memory.
- [ ] Procedures were routed to a skill candidate, not a memory note.
- [ ] Project truth claims were routed to project authority review, not memory.
- [ ] External memory/provider changes stayed gated.
- [ ] Any source lineage is generic and does not leak internal project structure.
