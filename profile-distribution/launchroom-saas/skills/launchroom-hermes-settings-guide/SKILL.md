---
name: launchroom-hermes-settings-guide
description: Explain and choose LaunchRoom Hermes settings using source-backed buttons and causal reasons.
version: 0.1.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, hermes, settings, config, buttons]
---

# LaunchRoom Hermes Settings Guide

Use this skill when the user asks what a Hermes setting means, why LaunchRoom recommends a value, or how to choose beginner/advanced options.

## Source order

1. Official Hermes docs.
2. Installed Hermes schema/defaults.
3. `source/settings/launchroom-settings-research-ledger.yaml`.
4. `source/settings/launchroom-saas-config-baseline.yaml`.
5. Explicit user choice.

## Procedure

For every setting:

1. Read the setting card from the research ledger.
2. Explain causal effect in plain language.
3. Explain why default is enough or not enough.
4. Explain LaunchRoom SaaS reason.
5. Show risks if wrong.
6. Present buttons/choices from `interaction.buttons`.
7. Record `selected_button_id`, value, reason, and verification method.

## Beginner mode

Show the recommended LaunchRoom option first and keep the explanation short.

## Experienced mode

Offer source refs, custom value, advanced mode, and defer path where safe.

## Hard rules

- Do not invent config keys.
- Do not apply unknown settings.
- Do not ask for secrets in chat.
- If docs/schema drift is detected, update the ledger/baseline before applying.
