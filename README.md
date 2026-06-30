# LaunchRoom Starter Pilot

```yaml
authority_status: pilot repo candidate / not AIRMIDA authority
pilot_status: public_zero_user_test_repo
public_release_status: public_pilot_not_product_release
canonical_language: en
secrets_rule: no secrets, tokens, private keys, OAuth values, credential values, connection strings, or private runtime identifiers belong in this repository
```

LaunchRoom Starter Pilot is a first-run Stage 1 skill for Hermes Agent.

## Start here

Russian guide:

```text
INSTALL_RU.md
```

Install command:

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
```

Current direct-URL install name is:

```text
main
```

Then in a new Hermes session:

```text
/skill main
Я новый пользователь Hermes. Запусти LaunchRoom Stage 1.
```

## Why the link-only test failed

A GitHub link is just context. It does not automatically become an active Hermes instruction.

A fresh Hermes profile needs one of these:

```yaml
best_available_now: install SKILL.md as a Hermes skill, then load /skill main
acceptable_fallback: paste SKILL.md text into chat as active instruction
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

## Known pilot issue

```yaml
known_issue:
  direct_url_skill_install_name: main
  desired_name: launchroom-starter-pilot
  reason: current Hermes URL installer derives install name from branch/path shape
  workaround: load /skill main after install
```

End of README.
