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

## Requires separate gate

- Installing software.
- Configuring gateway credentials.
- Mutating provider/cloud/runtime/n8n/billing/production surfaces.
- Public git publication.

## Secrets

Never ask for or write secret values in chat or workspace files.
