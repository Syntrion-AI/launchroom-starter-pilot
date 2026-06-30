# AIRMIDA LaunchRoom Stage Map

`public LaunchRoom test package / not AIRMIDA authority`

## STAGE_1 — Basic Safe Hermes Room

**Promise:** Model/provider path, profile/workspace path, settings buckets, first channel path, readiness report.

**User result:** User knows how Hermes is safely grounded before work.

**Allowed by default:** explain, read-only checks, model smoke if available, readiness report

**Blocked without gate:** secret handling in chat, provider credential entry, config mutation

**Gate checks:**
- bootstrap_0 pass or manual_only selected
- model path working/planned/deferred
- active profile identified
- Hermes runtime zone identified without secret values
- project workspace/cwd identified or deferred
- settings buckets explained
- first channel selected or deferred
- evidence ledger present
- next allowed stage is Stage 2 only

**Transition output:** `STAGE_1_BASIC_SAFE_ROOM_REPORT`

## STAGE_2 — Profile Workspace Memory Structure

**Promise:** Clear separation of Hermes runtime profile area and safe project workspace structure.

**User result:** User knows where not to edit and where project files belong.

**Allowed by default:** explain paths, read-only config/profile checks, plan profile/workspace

**Blocked without gate:** create profile, change config, create files

**Gate checks:**
- profile strategy selected/deferred
- workspace strategy selected/deferred
- memory policy known/deferred
- safe file structure explained

**Transition output:** `STAGE_2_PROFILE_WORKSPACE_REPORT`

## STAGE_3 — System Inventory Toolchain Baseline

**Promise:** No-secret inventory of OS and installed toolchain before recommending installs.

**User result:** Required/recommended/optional missing tools are known.

**Allowed by default:** read-only version/path checks, manual sanitized fallback

**Blocked without gate:** install programs, change PATH, update tools

**Gate checks:**
- terminal status classified
- toolchain inventory collected or manual_only
- missing tool decision list created

**Transition output:** `STAGE_3_SYSTEM_INVENTORY_REPORT`

## STAGE_4 — Tools Skills Memory Sessions Readiness

**Promise:** Hermes capabilities, skills, memory, sessions and gaps are known.

**User result:** User knows what Hermes can do now and what must be enabled under gate.

**Allowed by default:** read-only tools list, read-only skills list, memory status, decision list

**Blocked without gate:** enable tools, install skills, memory/profile self-update

**Gate checks:**
- tools inventory known/deferred
- skills inventory known/deferred
- memory status known/deferred
- no self-memory updates without gate

**Transition output:** `STAGE_4_CAPABILITY_REPORT`

## STAGE_5 — Communication Gateway Readiness

**Promise:** First remote communication channel selected or consciously deferred.

**User result:** User knows how Telegram/Discord/Slack/Email path will be configured without leaking secrets.

**Allowed by default:** gateway status read-only, explain channels, plan token entry path

**Blocked without gate:** gateway setup/run/install, channel posting, token readback

**Gate checks:**
- first channel selected/deferred
- gateway status checked/unavailable/deferred
- secret entry path explained

**Transition output:** `STAGE_5_COMMUNICATION_REPORT`

## STAGE_6 — SaaS Operator Kit CloudRoom AgentOps Readiness

**Promise:** Minimal SaaS operator kit plus gated CloudRoom/AgentOps map.

**User result:** User has a next local SaaS task and knows what remains gated.

**Allowed by default:** capture brief in chat, define next local task, map cloud/ops gates

**Blocked without gate:** create project files, git publish, Cloudflare/Hetzner/n8n mutation, production deployment

**Gate checks:**
- brief captured/deferred
- next local task defined
- CloudRoom/AgentOps boundaries explained
- no production mutation

**Transition output:** `STAGE_6_SAAS_OPERATOR_READINESS_REPORT`
