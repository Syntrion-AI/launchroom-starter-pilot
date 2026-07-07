---
name: launchroom-memory-stack
description: Use when LaunchRoom Full-System Bootstrap v0.7 needs memory stack as a public LaunchRoom skill for a real project-builder setup.
version: 0.7.0
author: Hermes Agent
license: MIT
metadata:
  launchroom:
    public_launchroom_skill: true
    full_system_bootstrap: true
    not_airmida_authority: true
---

# Memory Stack

This is a public LaunchRoom skill for the Full-System Bootstrap v0.7 package. It is written in English as machine-readable operator instruction, while the agent still speaks to the user in the user's language.

## When to Use

Use this skill during LaunchRoom setup when the current stage needs memory stack as part of turning an empty or poorly configured Hermes install into a working engineering SaaS profile factory.

## Procedure

1. Identify the current LaunchRoom stage and required evidence.
2. Inspect the relevant local, non-secret surfaces first.
3. Produce or update the stage artifact required by the v0.7 contract.
4. Repair or configure allowed local, non-secret settings when the setup gate already permits it.
5. Stop before secrets, OAuth, gateway pairing, cloud/runtime, n8n, production, release, or destructive actions unless a separate explicit gate exists.
6. Run or record the relevant smoke test before reporting pass.

## Boundaries

- Do not ask for secret values in chat.
- Do not copy `.env`, `auth.json`, `state.db`, OAuth stores, session stores, or credential files between profiles.
- Do not mutate external providers, gateways, cloud runtimes, n8n, billing, releases, or production surfaces from this skill alone.
- Do not reduce Full-System Bootstrap to a tiny checklist.

## Verification

A pass requires current evidence, not intention:

- required artifact exists and parses when structured;
- blocked or gated items are explicit;
- no secret-like values are present;
- smoke test or equivalent verification is recorded;
- next action is concrete.
