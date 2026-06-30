# Start here

```yaml
document_type: user_facing_entrypoint
language: en
pilot_status: public_zero_user_test_repo
secrets_rule: do not paste secrets into chat
```

## Copy this into Hermes

```text
I am a new Hermes user testing LaunchRoom Starter Pilot.
Repository: https://github.com/Syntrion-AI/launchroom-starter-pilot
Please stay in Stage 1 only.
Give me a simple beginner guide, not a technical audit.
Do not change my profile, settings, workspace, files, skills, gateway, provider, cloud, runtime, or GitHub repository.
Do not ask me to paste secrets into chat.
First: explain in 3 short steps what I should do next.
Then: give a tiny readiness check with only: language, model, workspace, secrets, next action.
If you cannot read the repository URL, ask me to paste this START_HERE.md text and do not guess.
```

## What should happen

Hermes should answer like a calm beginner guide:

```text
1. Confirm language.
2. Confirm that a model is already working.
3. Choose or keep a simple workspace.
```

Then Hermes should give a small result:

```yaml
language: selected | needs_choice
model: working | needs_setup | unknown
workspace: keep_current | choose_simple_folder | unknown
secrets: no_secrets_in_chat
next_action: one simple action
```

## Stop if Hermes does this

Stop the test if Hermes tries to:

```yaml
stop_if:
  - change settings automatically
  - create or switch projects automatically
  - create files automatically
  - create or patch skills
  - start gateway/cloud/runtime/provider setup
  - ask for secrets in chat
  - give a long technical audit instead of a beginner guide
```

End of START_HERE.
