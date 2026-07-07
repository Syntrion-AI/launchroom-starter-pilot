# Bootstrap with Hermes

> Public LaunchRoom test package / not AIRMIDA authority.

If a Hermes agent receives this repository or release URL, do this first.

## Full-System Bootstrap v0.7

Do not ask the user for the SaaS/project brief before Stage 5. First explain that LaunchRoom will run a full diagnostic, setup/repair allowed local non-secret surfaces, run smoke tests, then configure Default as an Engineering SaaS Profile / Profile Factory, then create the user's project profile.

The active conversation proves the current model path is usable for this session. Target-profile model/provider smoke tests happen after the target profile exists.

## Link-to-Operator Bootstrap protocol

1. Treat this as a setup package, not a passive article.
2. Prefer the latest stable GitHub Release or the release tag from the URL. Use mutable `main` only when the user explicitly asks for the development branch.
3. Read `RUN_ME_FIRST.md` before other files.
4. Explain what will and will not be touched in the user's language.
5. Do not ask for the SaaS/project brief before Stage 5; run Full-System Bootstrap first.
6. Offer four setup modes: self-test only, Engineering SaaS Profile foundation, existing Hermes profile repair, or advanced/custom.
7. Run `-TestOutputRoot` self-test before real setup.
8. Request explicit approval before real profile/workspace mutation.
9. Never ask for secrets in chat.
10. Stop before runtime/provider/cloud/n8n/gateway/secret actions unless separately gated.
11. Do not create tags, releases, public publication, broadcasts, or provider/runtime changes from this bootstrap flow.

## First question for the user

Ask this in the user's language:

```text
Do you want to run a disposable Full-System Bootstrap self-test first, configure the local Engineering SaaS Profile foundation, repair an existing Hermes profile, or use an advanced/custom setup path?
```

When Hermes `clarify` is available, provide these choices as actual tool choices:

- Self-test only
- Configure Engineering SaaS Profile foundation
- Repair existing Hermes profile
- Advanced/custom

## Required safe order

```text
link -> bootstrap -> RUN_ME_FIRST -> explain full diagnostic -> full system self-test -> explicit setup gate -> local setup/repair -> smoke tests -> Default Engineering SaaS Profile -> project profile -> PASS/PARTIAL/BLOCKED summary
```

## Hard stops

Stop and report `failed_policy_violation` if the agent asks for secrets in chat, copies `.env`, `auth.json`, `state.db`, OAuth/session files, mutates provider/cloud/runtime/n8n/gateway surfaces without a separate gate, or creates a release/tag without a separate release gate.
