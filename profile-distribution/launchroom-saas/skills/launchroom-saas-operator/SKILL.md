---
name: launchroom-saas-operator
description: Create and operate local SaaS project packets after LaunchRoom profile/workspace readiness.
version: 0.2.0
author: LaunchRoom Starter
license: MIT
metadata:
  hermes:
    tags: [launchroom, saas, product, local-operator, packets]
---

# LaunchRoom SaaS Operator

Use this skill at Stage 6 or when the user asks to start building a SaaS project after profile/workspace setup.

## Gate

Do not run SaaS operator work before Stage 1 profile foundation and Stage 2 workspace are pass or explicitly partial with accepted risk.

Cloud, provider, n8n, billing, production deployment, and public publication require separate gates.

## Fresh Agent First Reply Contract

If a user asks what to do first with LaunchRoom, do not begin with the SaaS/domain questionnaire. First explain:

- safe dry path before live setup;
- profile/workspace boundary;
- disposable `-TestOutputRoot` self-test;
- Stage 6 product intake and active/deferred surface routing;
- Stage 7 first-slice acceptance before implementation;
- Stage 8 local pilot gate before commands, file changes, tests, dependencies, or runtime work;
- separate owner gates for live setup, toolsets, runtime/provider/cloud/n8n/gateway/git publication, implementation, and secrets.

Domain-specific intake such as equipment photos, nameplates, prices, SKUs, or product code starts only after that LaunchRoom boundary is clear.

## Local SaaS packet

After confirmation, create local project artifacts such as:

- `.hermes/operator-kit/product_brief.md`
- `.hermes/operator-kit/target_user.md`
- `.hermes/operator-kit/product_brief.md`
- `.hermes/operator-kit/first_workflow.md`
- `.hermes/operator-kit/backlog.md`
- `.hermes/operator-kit/gates.md`
- `.hermes/operator-kit/readiness_report.yaml`
- `.hermes/operator-kit/readiness_report.yaml`

## SaaS foundation questions

Ask only what is needed for the next local packet:

1. Who is the user/customer?
2. What painful workflow are we improving?
3. What is the first useful local outcome?
4. What data/secrets/runtimes are involved?
5. What must be verified before any cloud or production work?

## Standard

Prefer small verified local artifacts over broad plans. Every output should include next action and remaining gates.
