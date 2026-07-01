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

## Pass criteria

Profile setup is not pass unless non-secret config, profile instructions, workspace instructions, and starter capability skills are present or explicitly deferred.
