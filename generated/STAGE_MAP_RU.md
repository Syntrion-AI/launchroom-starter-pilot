# AIRMIDA LaunchRoom Stage Map

`public LaunchRoom test package / not AIRMIDA authority`

## STAGE_1 — Starter Basic Safe Operator

**Promise:** User gets a working Hermes baseline: language, model/provider path, profile/workspace, safe settings buckets, first communication channel choice, and readiness report.

**User result:** I can talk to Hermes safely and understand what to set up next.

**Allowed by default:** explain, ask simple preference, run non-secret local diagnostics when user permits, produce readiness report

**Blocked without gate:** file creation, skill creation, profile credential mutation, gateway activation, provider credential entry, cloud/runtime mutation

**Gate checks:**
- language selected
- model/provider path explained: subscription or API key without secret readback
- profile/workspace decision selected or consciously deferred
- settings explained as safe buckets, not raw technical dump
- first channel selected or deferred: Telegram/Discord/Slack/Gmail/Email/WhatsApp where supported
- readiness report produced with one next action

**Transition output:** `STAGE_1_READINESS_REPORT`

## STAGE_2 — Creator Communication and Content Room

**Promise:** User gets a comfortable creation loop: writing, voice/media options, brand/context capture, communication lane, and one repeatable content workflow.

**User result:** I can use my agent to create, refine, and communicate useful SaaS content safely.

**Allowed by default:** draft content, create local non-secret templates after user asks, explain media/voice options, define brand/context packet

**Blocked without gate:** publishing, paid media generation commitments, channel posting, credential entry, runtime automations

**Gate checks:**
- brand/project context packet exists in chat or local artifact by request
- one content workflow rehearsed
- media/voice/tool choices classified as enabled, optional, or gated
- communication channel plan selected
- no public posting or credential handling performed

**Transition output:** `STAGE_2_CREATOR_WORKFLOW_REPORT`

## STAGE_3 — SaaS Project Builder Workspace

**Promise:** User gets a governed local SaaS project workspace: product brief, repo/workspace policy, feature backlog, local prototype packet, and test/run loop.

**User result:** I have a bounded SaaS project workspace and can ask the agent to build locally with tests.

**Allowed by default:** create local project artifacts under approved workspace, inspect code, write implementation packets, run local tests, build local prototype

**Blocked without gate:** deployment, domain/subdomain creation, production database, billing, external user data, git push

**Gate checks:**
- project root selected and allowed
- SaaS brief and non-goals recorded
- local-only build/test loop identified
- implementation packet exists before executor changes
- rollback and verification specified

**Transition output:** `STAGE_3_PROJECT_BUILDER_PACKET`

## STAGE_4 — Governed Operator and Agent Team

**Promise:** User gets governed multi-agent operations: roles, packet schema, validation, handoffs, run records, and Codex/Claude/Hermes coordination boundaries.

**User result:** My agent team can work on packets without losing gates, evidence, or boundaries.

**Allowed by default:** create packet templates, run local validators, delegate bounded subtasks, write run records, perform read-only MCP/tool inventories

**Blocked without gate:** live autonomous agents, provider/runtime mutation, credential operations, n8n workflow execution, production sync

**Gate checks:**
- role contour defined
- packet templates and validator pass
- handoff/run-record format exists
- tool boundaries documented
- verification arbiter report says pass or blocked

**Transition output:** `STAGE_4_GOVERNED_OPERATOR_REPORT`

## STAGE_5 — CloudRoom Runtime Readiness

**Promise:** User gets a gated cloud/runtime room plan: domains, Cloudflare, Hetzner, n8n, site sandbox, secrets policy, rollback, and read-only inventory before mutation.

**User result:** I know what runtime surfaces are needed and what must be explicitly approved before provisioning.

**Allowed by default:** read official docs, prepare provider-readiness packets, run non-secret read-only inventory when authenticated, draft rollback plans

**Blocked without gate:** Cloudflare DNS/Access/Tunnel/Worker changes, Hetzner server/firewall/network changes, n8n workflow/credential mutation, public deployment, secret readback

**Gate checks:**
- provider surfaces mapped
- secret handling path defined outside chat
- read-only inventory complete or blocker recorded
- provisioning packet includes backup, rollback, observability, owner approval fields
- no runtime mutation occurred without gate

**Transition output:** `STAGE_5_CLOUDROOM_READINESS_PACKET`

## STAGE_6 — AgentOps SaaS Operations

**Promise:** User gets production-grade operational discipline: CI/release gates, monitoring, SLOs, incidents, support loop, cost controls, and supervised autonomy plan.

**User result:** My SaaS project can move toward real operations with observable, reversible, audited agent assistance.

**Allowed by default:** design CI gates, write runbooks, define SLO/incident/cost controls, prepare supervised automation packets

**Blocked without gate:** production release, autonomous production agents, billing/customer data operations, provider mutations, incident automation activation

**Gate checks:**
- release checklist exists
- observability/SLO/runbook packet exists
- security/privacy controls specified
- support and incident flow defined
- supervised autonomy criteria explicit

**Transition output:** `STAGE_6_AGENTOPS_OPERATING_PACKET`
