# LaunchRoom Starter Pilot

```yaml
authority_status: pilot repo candidate / not AIRMIDA authority
pilot_status: public_zero_user_test_repo
public_release_status: public_pilot_not_product_release
canonical_language: en
secrets_rule: no secrets, tokens, private keys, OAuth values, credential values, connection strings, or private runtime identifiers belong in this repository
```

LaunchRoom Starter Pilot is a first-run Stage 1 skill for Hermes Agent.

The important part is not browsing this repository. The important part is loading the skill:

```text
SKILL.md
```

## Start here

Russian:

```text
INSTALL_RU.md
```

English quick path:

```text
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md
```

Then in a new Hermes session:

```text
/skill launchroom-starter-pilot
I am a new Hermes user. Start LaunchRoom Stage 1.
```

## Why the previous link-only test failed

A GitHub link is just context. It does not automatically become an active Hermes instruction.

A fresh Hermes profile needs one of these:

```yaml
best: install SKILL.md as a Hermes skill
acceptable: paste SKILL.md text into chat as active instruction
weak: paste only the repository link and hope the model reads the right files
```

## What Stage 1 should do

```yaml
expected_user_experience:
  - short welcome
  - language confirmation
  - model works because Hermes is answering
  - no automatic settings/profile/workspace changes
  - no file creation unless user asks
  - no skill creation or self-improvement during beginner test
  - no gateway/cloud/provider/runtime setup
  - tiny readiness check
  - one next action
```

## What this pilot must not do

```yaml
must_not_do:
  - ask for secrets in chat
  - change Hermes global settings automatically
  - change Hermes profile settings automatically
  - create or clone Hermes profiles automatically
  - switch workspace/project automatically
  - create local files unless the user explicitly asks
  - create or patch skills during the beginner test
  - start gateway setup
  - connect cloud or runtime services
  - publish or deploy anything
```

## Maintainer files

```text
SKILL.md
START_HERE.md
START_HERE_RU.md
INSTALL_RU.md
DEFAULT_PROFILE_TEST.md
UNDER_THE_HOOD.md
contracts/
scripts/validate_pilot_seed.py
```

End of README.
