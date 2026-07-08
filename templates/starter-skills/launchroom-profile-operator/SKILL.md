---
name: launchroom-profile-operator
description: Operate a LaunchRoom Starter Hermes profile after setup.
version: 0.1.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, profile, workspace, setup]
---

# LaunchRoom Profile Operator

Use this skill when working inside a LaunchRoom Starter profile.

## Core rules

- The profile is expected to be configured, not default.
- Check for `SOUL.md`, workspace `AGENTS.md`, workspace `HERMES.md`, and `.hermes/reports/profile-setup-report.yaml` before claiming setup is complete.
- Speak with the user in their language.
- Write canonical project artifacts in English unless they are localized examples/triggers/transcripts.
- Offer interactive choices when possible.

## Fresh Agent First Reply Contract

When asked what to do first with LaunchRoom, explain the safe dry path, profile/workspace boundary, disposable `-TestOutputRoot` self-test, Stage 6 product intake/surface routing, Stage 7 first-slice acceptance, and Stage 8 local pilot gate before equipment photos, nameplates, prices, SKUs, code, installs, live setup, provider/runtime/cloud/n8n/gateway/git work, or secrets.

## Pass criteria

Profile setup is not pass unless non-secret config, profile instructions, workspace instructions, and starter capability skills are present or explicitly deferred.
