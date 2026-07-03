---
name: launchroom-tool-readiness-smoke
description: Use when a LaunchRoom user or agent needs to check whether a local tool is ready enough for a task using no-secret command, version, auth-presence, and read-only smoke checks without installing or mutating runtime surfaces.
version: 0.1.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, tool-readiness, smoke-test, no-secrets, validation, gates]
    related_skills: [launchroom-memory-governance, launchroom-positive-result-capture, launchroom-profile-operator]
---

# LaunchRoom Tool Readiness Smoke

## Overview

Use this skill before claiming that a tool is ready for real LaunchRoom work. A command existing on disk is not enough. A tool becomes usable only after a bounded, non-secret, low-risk readiness smoke check proves what is actually available.

Core rule:

```text
present command -> version -> safe auth/status presence -> read-only smoke or clear blocker -> task fit decision
```

This is a sanitized LaunchRoom abstraction derived from proven internal operating patterns. It does not assume any private workspace path, profile, organization, cloud account, runtime provider, or credential store.

## When to Use

Use this skill when:

- a user asks whether a local tool is ready;
- a LaunchRoom stage maps software into capability workflows;
- an agent wants to hand work to a CLI, IDE helper, API wrapper, browser tool, or external agent;
- a tool appears installed but has not been smoke-tested;
- a task depends on a tool that may require auth, local permissions, network access, or runtime configuration;
- the safe result should be `ready`, `partial`, `blocked`, or `not needed` instead of vague "installed".

## Do Not Use For

Do not use this skill to:

- install tools or dependencies;
- start login/OAuth flows;
- read, print, copy, hash, or store secret values;
- create real issues, PRs, messages, deployments, workflows, cloud resources, or billing changes;
- mutate provider, runtime, gateway, cloud, database, n8n, or production surfaces;
- treat a failed smoke check as permission to use another credential source;
- claim readiness from config folders alone.

Those actions need separate gates and usually a tool-specific setup skill or runbook.

## Beginner Example

If the user asks, "Can we use this tool for the next step?", do not jump straight into the real task. First run the smallest safe checks:

```yaml
tool: example-cli
command_present: true
version_present: true
auth_presence_checked_without_secret_readback: true
read_only_smoke: passed
status: ready_read_only
blocked_actions:
  - write action
  - deploy
  - publish
  - credential changes
```

If the auth check says the user is not logged in, the correct result is a blocker, not an attempt to find or print tokens:

```yaml
status: blocked_needs_user_auth_flow
secret_readback: false
next_action: ask user to run the official login flow or choose a no-auth path
```

## Boundary

This skill is customer-safe and LaunchRoom-specific:

```yaml
source_lineage: internal tool-readiness patterns, sanitized
source_internal_skill_mutation_allowed: false
public_beginner_default: false
install_allowed_by_this_skill: false
auth_flow_allowed_by_this_skill: false
secret_readback_allowed: false
runtime_provider_change_allowed: false
external_write_action_allowed: false
authority_promotion_allowed: false
```

If an internal project skill inspired this workflow, treat it as source lineage only. Do not patch, rename, or publish internal skills as LaunchRoom public skills.

## Readiness State Model

| State | Meaning | Safe next action |
|---|---|---|
| `not_needed` | Task does not require this tool | Do not force setup |
| `missing` | Command or app is not found | Offer gated install/setup path |
| `present_unverified` | Command exists but version/smoke not checked | Run safe checks before use |
| `partial` | Some checks pass but auth/network/feature is missing | Use only proven subset or ask for gate |
| `blocked` | Required safe check failed | Record blocker and stop tool-dependent work |
| `ready_read_only` | Read-only smoke passed | Use for read-only task only |
| `ready_after_gate` | Tool can act, but write/publish/deploy needs gate | Ask before side effects |

## Smoke Workflow

1. **Classify the task need.** State why the tool is needed. Done when the required capability is explicit.
2. **Check command/app presence.** Use safe discovery such as command lookup or documented status command. Done when presence is true/false, not assumed.
3. **Check version.** Run a version/help command that does not read secrets. Done when version or missing-version blocker is recorded.
4. **Check auth presence safely.** Use official status commands when available, but never print credential values. Done when auth state is `present`, `missing`, `unknown`, or `not_required`.
5. **Run read-only smoke.** Prefer a harmless local or read-only remote command. Done when output proves the minimum capability or records a blocker.
6. **Map status to task scope.** Decide whether the tool is ready for read-only, ready after a gate, partial, blocked, or not needed. Done when the task assignment does not exceed verified capability.
7. **Record evidence.** Save only sanitized outputs and blockers. Done when no sensitive values or private assumptions are stored.

## Safe Check Patterns

Use tool-specific official commands when available. Keep the generic shape:

```text
command lookup -> version/help -> status without secret values -> read-only or dry-run command -> result classification
```

Examples of safe intent, not mandatory commands:

```yaml
local_cli:
  command_present: check whether executable is on PATH
  version_check: run version/help output
  smoke: dry-run or local no-write command

api_cli:
  command_present: check executable
  version_check: run version/help output
  auth_presence: official status command without token values
  smoke: read-only endpoint that returns non-sensitive metadata

external_agent_cli:
  command_present: check executable
  version_check: run version/help output
  smoke: ephemeral prompt that does not read files, write files, run shell commands, or access private data

browser_or_desktop_tool:
  command_present: check configured tool capability
  permission_presence: user-approved permission status only
  smoke: harmless capture or read-only page check
```

## Result Packet

Use this compact result packet:

```yaml
tool_name:
task_need:
checks:
  command_present:
  version_present:
  auth_presence_without_secret_readback:
  read_only_smoke:
status: not_needed | missing | present_unverified | partial | blocked | ready_read_only | ready_after_gate
verified_scope:
blocked_actions:
evidence:
  sanitized_output_summary:
  files_or_reports:
secrets_read_or_written: false
runtime_mutation: false
next_action:
```

Completion criterion: another agent can decide whether the tool may be used and exactly what remains gated.

## Capability Map Hook

When this skill is used inside LaunchRoom setup, do not report a flat tool list. Map the readiness result into a capability workflow:

```text
task class -> capability workflow -> tool bundle -> skill bundle -> gates -> verification
```

Example:

```yaml
code_review_workflow:
  required_capability: inspect repository and run tests
  tool_bundle: local shell, git, test runner, optional GitHub CLI
  skill_bundle: systematic debugging, test-driven development, code review
  readiness_status: ready_read_only or ready_after_gate
  gates: git write gate, PR/publish gate
  verification: tests passed, diff reviewed, no secret leakage
```

## Gates

Requires explicit user gate before:

- installing or updating software;
- starting OAuth/login/pairing flows;
- enabling Hermes toolsets or network skills;
- writing persistent memory;
- executing write commands in external tools;
- creating issues, PRs, messages, posts, workflows, databases, cloud resources, deployments, or releases;
- changing provider, runtime, gateway, cloud, billing, or production configuration.

## Common Pitfalls

1. **Installed equals ready.** A binary on PATH does not prove auth, permission, or task capability.
2. **Status leaks.** Some status commands can reveal account identifiers or sensitive paths. Summarize safely.
3. **Fixing while checking.** Readiness smoke is not an install or repair step unless a separate gate grants it.
4. **Write-action smoke.** A smoke check should not create real resources just to prove capability.
5. **Credential scavenging.** If auth is missing, stop and request the official user-run auth path; do not search for tokens.
6. **Overbroad readiness.** Passing a read-only smoke does not authorize write, deploy, publish, billing, or production actions.
7. **Internal-pattern leakage.** Do not copy private paths, profile assumptions, runtime state, hostnames, or account-specific details into customer-facing reports.

## Verification Checklist

- [ ] The task need for the tool is explicit.
- [ ] Presence and version were checked without reading secrets.
- [ ] Auth or permission status was checked without credential value readback.
- [ ] A read-only/dry-run/harmless smoke was used, or a blocker was recorded.
- [ ] Status is one of the defined readiness states.
- [ ] Verified scope and blocked actions are explicit.
- [ ] No token, key, password, private key, OAuth value, connection string, or sensitive account detail was stored.
- [ ] No install, login, external write, runtime mutation, or publication happened without a separate gate.
- [ ] Evidence is sanitized and enough for a future agent to avoid repeating the same probe.
