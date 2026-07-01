# LaunchRoom SaaS Hermes Profile Distribution

This directory is the LaunchRoom Starter profile distribution source. It is a shareable Hermes profile package, not a live user profile and not an AIRMIDA authority artifact.

## Purpose

LaunchRoom gives a new user a working first Hermes SaaS/project operator profile with:

- source-backed settings, not unexplained defaults;
- a concrete `SOUL.md` identity;
- profile instructions for SaaS-grade local work;
- a machine-readable profile contract;
- a safe `config.yaml.template` generated from research/baseline contracts;
- starter skills for profile operation, settings review, and SaaS operator packets;
- report templates for evidence-based setup status.

## Important boundaries

- Do not commit secrets.
- Do not copy `.env`, `auth.json`, `state.db`, memories, sessions, logs, OAuth stores, or raw MCP credential values from another profile.
- `config.yaml.template` is not a live `config.yaml`; live config generation must resolve placeholders through the Stage 1 wizard.
- Toolsets may require `hermes tools` and a reset/new session, not direct YAML writes.

## Source contracts

This distribution is derived from:

- `source/settings/launchroom-settings-research-ledger.yaml`
- `source/settings/launchroom-saas-config-baseline.yaml`
- `source/stages/stage-1-profile-foundation-wizard.yaml`
- `source/generators/profile-config-generator.yaml`

Official Hermes docs remain the source of truth if repo assumptions drift.
