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

## Local SaaS packet

After confirmation, create local project artifacts such as:

- `saas-operator-kit/product-brief.md`
- `saas-operator-kit/target-user.md`
- `saas-operator-kit/problem-solution.md`
- `saas-operator-kit/first-workflow.md`
- `saas-operator-kit/backlog.md`
- `saas-operator-kit/gates.md`
- `saas-operator-kit/verification-plan.md`
- `.hermes/reports/saas-readiness-report.yaml`

## SaaS foundation questions

Ask only what is needed for the next local packet:

1. Who is the user/customer?
2. What painful workflow are we improving?
3. What is the first useful local outcome?
4. What data/secrets/runtimes are involved?
5. What must be verified before any cloud or production work?

## Standard

Prefer small verified local artifacts over broad plans. Every output should include next action and remaining gates.
