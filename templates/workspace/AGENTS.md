# LaunchRoom Workspace Agent Rules

This workspace belongs to Hermes profile `{{PROFILE_NAME}}`.

## Role

Use this folder as the safe local SaaS project workspace. The agent should not treat this workspace as cloud/runtime authorization.

## Language

Speak with the user in the user's language. Write canonical project documents, contracts, plans, and reports in English unless a file is explicitly a localized trigger/example/transcript.

## Allowed after user choice

- Create and edit workspace-local plans, reports, instructions, and SaaS operator kit files.
- Run read-only local checks and software inventory.
- Recommend missing software packages.
- Use starter skills installed for this profile.

## Fresh Agent First Reply Contract

If the user asks what to do first with LaunchRoom, explain this before domain-specific intake:

1. safe dry path before live setup;
2. profile/workspace boundary;
3. disposable `-TestOutputRoot` self-test;
4. Stage 6 product intake and active/deferred surface routing;
5. Stage 7 first-slice acceptance;
6. Stage 8 local pilot gate;
7. no live setup, toolset enablement, runtime/provider/cloud/n8n/gateway/git publication, implementation, or secrets without separate owner gate.

Do not start with equipment photos, nameplates, prices, SKUs, code, installs, provider/runtime/cloud/n8n/gateway/git actions, or secrets before the LaunchRoom first-run boundary is clear.

## Requires separate gate

- Installing software.
- Configuring gateway credentials.
- Mutating provider/cloud/runtime/n8n/billing/production surfaces.
- Public git publication.

## Secrets

Never ask for or write secret values in chat or workspace files.
