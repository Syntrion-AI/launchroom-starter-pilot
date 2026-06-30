# AIRMIDA LaunchRoom One-Link Setup

`public LaunchRoom test package / not AIRMIDA authority`

Use **one link** in a new Hermes Agent chat:

```text
https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/RUN_ME_FIRST_RU.md
```

Expected behavior: Hermes must not summarize the file. It must start `Bootstrap 0`, verify whether it can run local checks, and only then proceed through real setup stages.

## What this package tests

```yaml
bootstrap_0: execution surface / terminal backend / model basics
stage_1: Basic Safe Hermes Room
stage_2: profile, workspace, memory, safe file structure
stage_3: system inventory and toolchain baseline
stage_4: tools, skills, memory, sessions readiness
stage_5: communications and gateway readiness
stage_6: SaaS operator kit plus CloudRoom/AgentOps readiness
```

## Important behavior

If Hermes terminal/backend is broken on a clean Windows machine, the correct result is:

```yaml
bootstrap_0: blocked
stage_1_to_6: not_started
```

Not a fake Stage 6 pass.

## Optional skill install

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
```

But the primary test is the one-link paste above.

## Optional clean test profile reset script

For Windows repeatable tests, use the PowerShell helper. It creates the
`launchroom-zero` profile if missing, and only resets an existing test profile
when `-ResetExisting` is explicitly passed. Existing test profiles are exported
to a timestamped backup before deletion.

```powershell
# Create missing test profile and run model picker only
powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1

# Recreate the test profile from scratch, with backup first
powershell -ExecutionPolicy Bypass -File .\scripts\reset_launchroom_test_profile.ps1 -ResetExisting
```

This does not reset the main/default Hermes profile and does not uninstall
Windows tools such as Python, Git, Node, Docker, or ripgrep.

## Safety

No secrets in chat. No file/config/profile/tool/skill/gateway/cloud/runtime/git mutation without separate explicit gate.
