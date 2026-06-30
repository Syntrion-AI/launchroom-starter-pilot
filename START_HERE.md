# Start here

```yaml
document_type: user_facing_entrypoint
language: en
pilot_status: private_pilot_repo_for_owner_test
secrets_rule: do not paste secrets into chat
```

## First choice: language

EN: Welcome. Choose your language: English or Russian. You can change it later.

RU: Добро пожаловать. Выберите язык: английский или русский. Его можно изменить позже.

For this pilot:

```yaml
recommended_test_language: user_choice
canonical_repo_language: en
available_localized_pages:
  ru: i18n/ru/START_HERE.ru.md
```

## What this pilot is

LaunchRoom Starter is the first safe room for Hermes.

It does not try to make Hermes fully autonomous. It helps you check the basics before you move to advanced work.

## Copy this prompt into Hermes

```text
I am testing LaunchRoom Starter Pilot from a default Hermes profile.
Use Stage 1 only.
Help me understand: language, model path, profile/workspace, safe settings, memory, and readiness report.
Do not ask me to paste secrets into chat.
Do not publish, deploy, start a gateway, or change provider/cloud/runtime systems.
If a step needs credentials or account login, stop and explain the safe manual path.
```

## Stage 1 output you should expect

Hermes should produce a short readiness report:

```yaml
language: selected | needs_choice
model_path: connected | needs_setup | unknown
profile: default_profile_test | selected | needs_review
workspace: selected | needs_review
secrets: no_secrets_in_chat
memory: explained | needs_review
settings: basic_safe | needs_review
next_action: one concrete action
blocked_actions:
  - credential entry in chat
  - runtime changes
  - remote publication actions
```

## If Hermes tries to do too much

Stop and write this observation:

```text
The pilot drifted beyond Stage 1.
```

Then record which step caused drift in `DEFAULT_PROFILE_TEST.md` or your notes.

End of START_HERE.
