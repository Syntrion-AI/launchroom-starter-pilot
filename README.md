# LaunchRoom Starter Pilot

```yaml
authority_status: pilot repo candidate / not AIRMIDA authority
pilot_status: private_pilot_repo_for_owner_test
canonical_language: en
secrets_rule: no secrets, tokens, private keys, OAuth values, credential values, connection strings, or private runtime identifiers belong in this repository
```

LaunchRoom Starter Pilot is a small first-run test for Hermes Agent.

It helps a new user answer one question:

```text
Can I turn a fresh or default Hermes profile into a safe first working room without mixing secrets, cloud, publishing, and advanced automation?
```

## Start here

Open:

```text
START_HERE.md
```

If you prefer Russian, open:

```text
i18n/ru/START_HERE.ru.md
```

## What the user sees

The user sees a simple Stage 1 path:

```yaml
Stage_1:
  - choose language
  - understand model path
  - understand profile and workspace
  - understand where secrets belong
  - run or simulate a readiness check
  - receive one next action
```

## What stays under the hood

Maintainers and Hermes Agent use:

```yaml
under_the_hood:
  - UNDER_THE_HOOD.md
  - contracts/stage1-machine-contract.yaml
  - contracts/stage1-language-policy.yaml
  - contracts/stage1-memory-policy.yaml
  - contracts/stage1-profile-scope.yaml
  - scripts/validate_pilot_seed.py
```

## What this pilot will not do

```yaml
blocked_in_pilot:
  - ask for secrets in chat
  - change Hermes global settings
  - change Hermes profile settings automatically
  - create or clone profiles automatically
  - start messaging gateway setup
  - connect cloud or runtime services
  - publish or deploy anything
```

## Default-profile simulation

The intended first test is:

```text
1. Publish or open this repo candidate.
2. Open it from a default Hermes profile.
3. Use START_HERE.md as the first user-facing entrypoint.
4. Record what was clear and what failed.
```

See:

```text
DEFAULT_PROFILE_TEST.md
```

## Pilot repository

```yaml
repository: https://github.com/Syntrion-AI/launchroom-starter-pilot
visibility: private
public_release_status: not_public_release
```

End of README.
