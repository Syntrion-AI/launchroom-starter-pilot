---
name: launchroom-positive-result-capture
description: Use when a LaunchRoom task succeeds and the useful result should become reusable practice, evidence, a skill candidate, or a next decision without saving stale task logs or exposing internal project assumptions.
version: 0.1.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, positive-results, learning-loop, evidence, skills, governance]
    related_skills: [launchroom-memory-governance, launchroom-profile-operator, launchroom-saas-operator]
---

# LaunchRoom Positive Result Capture

## Overview

Use this skill when a LaunchRoom workflow succeeds and the success should improve future work. A solved problem should become a reusable safe pattern, not just a chat summary or another archive file.

Core rule:

```text
capture the safe repeatable move, not only the story of what happened.
```

This is a sanitized LaunchRoom abstraction derived from proven internal operating patterns. It is not an internal operator skill and does not assume any private workspace path, profile, runtime provider, project authority file, or customer deployment surface.

## When to Use

Use this skill after:

- a setup, repair, validation, or packaging task succeeds;
- a confusing blocker is resolved and should not be rediscovered;
- a user-facing workflow becomes clearer or safer;
- a reusable procedure emerges from a one-off task;
- a LaunchRoom stage produces a verified capability or useful pattern;
- the user asks what should be remembered, converted into a skill, or carried into the next project.

## Do Not Use For

Do not use this skill to:

- celebrate trivial one-message answers;
- save temporary task progress as persistent memory;
- store raw transcripts, private data, credentials, or tokens;
- promote a local note into project truth;
- create or patch active skills without a user gate;
- commit, publish, deploy, or mutate runtime/provider/cloud surfaces.

Those actions need separate gates and usually a project-specific workflow.

## Beginner Example

If the agent finally fixes a setup check that was confusing, do not only say "fixed." Capture the reusable pattern:

```yaml
positive_result: setup check now reports partial instead of blocked when useful outputs exist
safe_pattern: validator rejects contradictory blocked-with-outputs states
evidence: command output and changed validator file
reuse_as: future release-readiness checklist item
not_memory: exact timestamp, branch noise, or temporary local path
```

If the user says, "That worked, remember this approach," first decide whether it is a durable preference, a reusable procedure, a local evidence note, or project truth. Procedures usually become skills or checklists, not persistent memory.

## Boundary

This skill is customer-safe and LaunchRoom-specific:

```yaml
source_lineage: internal operating patterns, sanitized
source_internal_skill_mutation_allowed: false
public_beginner_default: false
runtime_provider_change_allowed: false
sensitive_value_storage_allowed: false
authority_promotion_allowed: false
```

If an internal project skill inspired this workflow, treat it as source lineage only. Do not patch, rename, or publish internal skills as LaunchRoom public skills.

## Result Layer Map

| Result type | Best destination | Why |
|---|---|---|
| Observed command/test output | Evidence report or run log | Keeps proof separate from memory |
| Reusable procedure | Skill or checklist candidate | Changes future agent behavior |
| Stable user preference | Persistent memory after approval | Small durable preference for future sessions |
| Temporary task progress | Session history or local evidence | Avoids memory pollution |
| Project truth or policy | Project authority review gate | Requires deliberate promotion |
| Product UX lesson | Product backlog or LaunchRoom stage artifact | Makes user-facing improvements visible |

## Capture Workflow

1. **Name the positive result.** State what now works in one sentence. Done when a user can understand the win without reading logs.
2. **Attach evidence.** Point to observed outputs, changed files, or readback. Done when the claim is verifiable.
3. **Extract the safe pattern.** Convert the win into a repeatable rule or sequence. Done when another agent could reuse it.
4. **Choose the storage layer.** Evidence, skill, memory, backlog, or authority review. Done when the target layer is explicit.
5. **Filter stale details.** Remove one-off timestamps, branch noise, temporary paths, and task diary content. Done when only reusable signal remains.
6. **Record remaining gates.** State what was not done and what needs approval. Done when no publication, runtime, credential, or authority action is implied.
7. **Verify closeout.** Read back any file created or changed and run relevant validators. Done when the report can cite real outputs.

## Positive Result Packet

Use this compact packet when closing a non-trivial task:

```yaml
accepted_task:
positive_result:
what_now_works:
evidence:
  observed_outputs:
  files_changed:
  validators_run:
reusable_pattern:
storage_decision:
  evidence_report:
  skill_candidate:
  memory_candidate:
  backlog_or_next_decision:
not_saved_as_memory:
remaining_gates:
verification:
  sensitive_values_found: 0
  readback_done: true
  validators_passed:
```

Completion criterion: a future agent can see what became reusable and what remains only local evidence.

## Skill Candidate Rule

Create or propose a skill only when the result changes future behavior.

Good skill candidate:

```yaml
trigger: when this situation appears again
procedure: repeatable steps with completion checks
pitfalls: what caused delay or confusion
verification: exact checks to prove success
scope_boundary: where not to apply it
```

Bad skill candidate:

```yaml
content: today we fixed one file and it passed once
problem: task diary, not reusable procedure
```

## Memory Rule

Use memory only for compact durable facts or preferences. Do not store task completion logs.

Good memory candidate:

```text
User prefers successful LaunchRoom workflows to be converted into reusable patterns and skill candidates when procedural.
```

Bad memory candidate:

```text
Created launchroom-positive-result-capture today and validators passed.
```

## Gates

Requires explicit user gate before:

- writing persistent memory;
- creating or promoting an active skill;
- editing project truth, registry, or authority files;
- publishing release notes, tags, releases, packages, or broadcasts;
- changing provider, runtime, gateway, cloud, billing, or deployment surfaces;
- uploading raw logs or transcripts to external services.

## Common Pitfalls

1. **Archive-only closeout.** A report proves what happened; a skill or checklist changes future behavior. Use the right layer.
2. **Task diary memory.** Dates, commit noise, and "we finished X" usually become stale. Keep them out of persistent memory.
3. **No evidence.** Do not claim a positive result without observed output, readback, or validator evidence.
4. **Authority creep.** A local LaunchRoom evidence note is not project truth unless promoted by the project.
5. **Overfitting.** A reusable pattern should survive different files, projects, and sessions.
6. **Hidden side effects.** Capturing a result is not permission to publish, deploy, install, or mutate runtime surfaces.
7. **Internal-pattern leakage.** Do not copy private paths, profile assumptions, runtime state, or internal module structure into customer-facing skills.

## Verification Checklist

- [ ] The positive result is named in plain language.
- [ ] Evidence is attached or explicitly referenced.
- [ ] The reusable pattern is separated from one-off details.
- [ ] Storage layer is explicit: evidence, skill, memory, backlog, or authority review.
- [ ] Stale task progress was not saved as persistent memory.
- [ ] No sensitive values, credentials, private keys, or tokens were stored or printed.
- [ ] Remaining gates are stated.
- [ ] Any created/changed artifact was read back.
- [ ] Relevant validators or checks were run and reported with real outputs.
