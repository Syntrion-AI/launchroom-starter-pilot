# LaunchRoom Starter Pilot

```yaml
authority_status: pilot repo candidate / not AIRMIDA authority
pilot_status: public_zero_user_test_repo
public_release_status: public_pilot_not_product_release
canonical_language: en
secrets_rule: no secrets, tokens, private keys, OAuth values, credential values, connection strings, or private runtime identifiers belong in this repository
```

LaunchRoom Starter Pilot is a small public test for a fresh Hermes user.

It should answer one simple question:

```text
Can a new Hermes user get a safe first working room without learning GitHub, agents, cloud, or advanced automation first?
```

## Start in 30 seconds

If you speak English, open:

```text
START_HERE.md
```

If you speak Russian, open:

```text
START_HERE_RU.md
```

Then copy the single prompt from that file into Hermes.

## Important

Hermes can read this repository only if its web/GitHub access works. This repository is public, so a fresh Hermes profile should be able to open it by URL.

If Hermes still cannot open the URL, paste the text of `START_HERE.md` or `START_HERE_RU.md` directly into chat.

## What the user should experience

```yaml
expected_user_experience:
  - a short welcome
  - language confirmation
  - one simple explanation of Stage 1
  - no secret request in chat
  - no automatic profile/config/workspace changes
  - no gateway/cloud/provider/runtime setup
  - a tiny readiness result
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

## For maintainers only

Under-the-hood contracts and validators are kept in:

```text
UNDER_THE_HOOD.md
contracts/
scripts/validate_pilot_seed.py
DEFAULT_PROFILE_TEST.md
```

A beginner should not need to read those first.

## Repository

```yaml
repository: https://github.com/Syntrion-AI/launchroom-starter-pilot
visibility: public
public_release_status: public_pilot_not_product_release
```

End of README.
