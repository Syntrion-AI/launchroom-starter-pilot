# LaunchRoom Skillpacks

> Public LaunchRoom test package / not AIRMIDA authority.

This generated guide summarizes `source/skillpacks/launchroom-skillpacks.v0_1.yaml`. It keeps the beginner default small and exposes valuable skills through staged, gated skillpacks.

## Policy

- Default bundled skills stay limited to the three LaunchRoom-specific skills.
- Runtime-enabled skills are recommendations, not automatic installs or toolset activation.
- Hidden/platform/environment candidates are valuable but not ready by default.
- Lab-restricted skills never appear in public beginner flows.
- Sanitized abstraction skills are new `launchroom-*` skills derived from internal patterns; they are not edits or public exports of AIRMIDA internal skills.
- Source-lineage AIRMIDA internal skills are not public runtime skills in LaunchRoom packs.
- No skill install, skill enablement, dependency install, runtime mutation, secret handling, or git publication is performed by this registry.

## Sanitized abstraction boundary

See `source/skillpacks/SANITIZED_ABSTRACTION_BOUNDARY.md`.

```yaml
source_airmida_skill_mutation_allowed: false
airmida_internal_skills_are_public_launchroom_skills: false
sanitized_skills_require_new_launchroom_names: true
sanitized_abstraction_skills_count: 3
sanitized_skill_paths:
  - source/skills/launchroom-sanitized-abstractions/launchroom-memory-governance/SKILL.md
  - source/skills/launchroom-sanitized-abstractions/launchroom-positive-result-capture/SKILL.md
  - source/skills/launchroom-sanitized-abstractions/launchroom-tool-readiness-smoke/SKILL.md
```

## Sanitized abstractions product positioning

- User-facing name: **Safe Practice Pack**
- Summary: Three optional skills that help a LaunchRoom user decide what to remember, how to turn a win into reusable practice, and how to check tools safely before using them.
- Current product decision: `keep_optional_only`
- Recommended sequence: `launchroom-memory-governance`, `launchroom-positive-result-capture`, `launchroom-tool-readiness-smoke`
- Offer when:
  - the user starts doing repeated LaunchRoom work
  - the workspace has enough evidence artifacts that memory/skill/result routing matters
  - the user asks why the agent will not immediately install, login, publish, or remember everything
- Do not offer when:
  - first-run beginner setup only needs the minimal bundle
  - the user has not accepted optional skillpack review
  - the task needs a concrete implementation toolpack instead of governance habits
- Promotion requires:
  - owner approval
  - beginner comprehension check
  - no private/internal naming in customer-facing skill bodies
  - validator pass and leak scan

## Visibility classes

- `runtime_enabled_now` — Skill is visible in the current runtime-enabled profile/platform inventory and can be recommended or loaded after normal LaunchRoom choice gates.
- `environment_or_platform_candidate` — Skill exists and is valuable, but is hidden by OS, environment, tool, dependency, or runtime condition; offer only when that condition is true and the relevant gate is accepted.
- `excluded_or_lab_only` — Skill is valuable only in explicitly gated internal/lab contexts and must not appear in public beginner flows.
- `sanitized_launchroom_abstraction` — New customer-safe LaunchRoom skill created from sanitized AIRMIDA operating patterns; source internal skills are lineage only and must not be patched, renamed, or exposed as public defaults by this registry.

## Curated packs

| Pack | Offer model | Default install | Runtime skills | Sanitized skills | Hidden candidates | Gate summary |
|---|---|---:|---:|---:|---:|---|
| `launchroom_minimal_bundle` | `bundled_profile_payload` | `true` | 3 | 0 | 0 | profile/workspace setup choice; no secret copy; no runtime mutation |
| `foundation_operator_pack` | `recommended_after_choice` | `false` | 11 | 0 | 0 | read-only first; workspace write gate; memory/skill promotion gate |
| `developer_builder_pack` | `project_type_optional` | `false` | 10 | 0 | 1 | implementation gate; git gate for add/commit/push; Windows port gate for python-debugpy |
| `creative_product_pack` | `project_type_optional` | `false` | 11 | 0 | 1 | project-type choice; media rights/disclosure gate; install/runtime gate for heavy media tools |
| `research_knowledge_pack` | `project_type_optional` | `false` | 8 | 0 | 1 | source verification required; citation verification required; research-paper-writing refactor gate |
| `productivity_documents_pack` | `user_choice_optional` | `false` | 9 | 0 | 2 | OAuth/user-run auth gate; document write gate; macOS Apple app permission gate |
| `messaging_social_pack` | `communication_surface_optional` | `false` | 5 | 0 | 2 | gateway setup gate; OAuth/user-run auth gate; explicit send/post approval; read-only first |
| `apple_personal_operator_pack` | `platform_conditional_macos_only` | `false` | 0 | 0 | 5 | host_os == macos; local app permissions; privacy explanation; explicit write/send/location confirmation |
| `agentops_executor_pack` | `advanced_gated` | `false` | 9 | 0 | 2 | external agent tool readiness; workspace isolation; board/profile/dispatcher readiness for Kanban; owner implementation gate |
| `cloudroom_modelops_pack` | `advanced_gated` | `false` | 10 | 0 | 2 | read-only first; runtime mutation gate; GPU/dependency/cost gate; model/license policy |
| `launchroom_sanitized_abstractions_pack` | `advanced_optional_sanitized` | `false` | 0 | 3 | 0 | sanitization review gate; no AIRMIDA internal skill mutation; no private path/profile assumption leakage; owner approval before promotion into bundled profile |
| `airmida_internal_operator_pack` | `workspace_conditional_internal_only` | `false` | 10 | 0 | 0 | AIRMIDA workspace detected; owner/Architect gate for authority/runtime; read-only first for external surfaces |
| `lab_restricted_pack` | `not_public_beginner_flow` | `false` | 1 | 0 | 1 | owner lab gate; legal/ethics/model-license gate; no public beginner offer |

### LaunchRoom Minimal Bundle

- Pack id: `launchroom_minimal_bundle`
- Room/stage: Foundation Room, Capability Room
- Offer model: `bundled_profile_payload`
- Default install: `true`
- Visibility: `runtime_enabled_now`
- Why valuable: The smallest LaunchRoom-specific layer that explains the profile, settings, and SaaS operator flow without flooding beginners with unrelated skills.
- Runtime skills: `launchroom-profile-operator`, `launchroom-hermes-settings-guide`, `launchroom-saas-operator`
- Hidden candidates: none
- Gates: profile/workspace setup choice, no secret copy, no runtime mutation
- Blocked without gate: install unrelated skills, enable network tools, gateway setup, provider/cloud/n8n mutation

### Foundation Operator Pack

- Pack id: `foundation_operator_pack`
- Room/stage: Bootstrap 0, Stage 1, Stage 2, Stage 4
- Offer model: `recommended_after_choice`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Gives LaunchRoom a disciplined operator baseline: Hermes setup knowledge, governed preflight, workspace integration, planning, debugging, and verification habits.
- Product notes: positive-result behavior offered through launchroom_sanitized_abstractions_pack after optional review gate
- Runtime skills: `hermes-agent`, `windows-desktop-agent-setup`, `experience-grounded-work-preflight`, `governed-agent-engineering-standards`, `governed-workspace-integration`, `governed-desktop-project-integration`, `plan`, `systematic-debugging`, `test-driven-development`, `requesting-code-review`, `hermes-agent-skill-authoring`
- Hidden candidates: none
- Gates: read-only first, workspace write gate, memory/skill promotion gate
- Blocked without gate: persistent memory write, skill patch/promotion, git publication, runtime/provider/cloud/gateway/n8n mutation

### Developer Builder Pack

- Pack id: `developer_builder_pack`
- Room/stage: Stage 7, Stage 8, Stage 9, Stage 10
- Offer model: `project_type_optional`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Supports real local implementation work after the implementation gate: codebase inspection, GitHub workflow, TDD, debugging, and review.
- Runtime skills: `codebase-inspection`, `github-auth`, `github-repo-management`, `github-issues`, `github-pr-workflow`, `github-code-review`, `node-inspect-debugger`, `systematic-debugging`, `test-driven-development`, `requesting-code-review`
- Hidden candidates: `python-debugpy`
- Gates: implementation gate, git gate for add/commit/push, Windows port gate for python-debugpy
- Blocked without gate: git add/commit/push, dependency install, interactive debugger in CI/non-TTY, committed breakpoints

### Creative Product Pack

- Pack id: `creative_product_pack`
- Room/stage: Stage 6, Product Starter Room
- Offer model: `project_type_optional`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Helps users turn vague product ideas into visual prototypes, diagrams, design artifacts, and creative media concepts.
- Runtime skills: `architecture-diagram`, `excalidraw`, `sketch`, `claude-design`, `design-md`, `popular-web-designs`, `humanizer`, `p5js`, `baoyu-infographic`, `pretext`, `powerpoint`
- Hidden candidates: `audiocraft-audio-generation`
- Gates: project-type choice, media rights/disclosure gate, install/runtime gate for heavy media tools
- Blocked without gate: audio/video generation runtime install, publication of generated media, provider/runtime mutation

### Research and Knowledge Pack

- Pack id: `research_knowledge_pack`
- Room/stage: Capability Room, Product Starter Room, Control & Evidence Room
- Offer model: `project_type_optional`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Supports evidence-first research, document extraction, literature review, knowledge extraction, and citation-safe publication workflows.
- Runtime skills: `arxiv`, `youtube-content`, `ocr-and-documents`, `llm-wiki`, `blogwatcher`, `governed-agent-knowledge-extraction`, `governed-readonly-corpus-study`, `maps`
- Hidden candidates: `research-paper-writing`
- Gates: source verification required, citation verification required, research-paper-writing refactor gate
- Blocked without gate: claiming unverified citations, promoting oversized skill into runtime prompt, publishing research output

### Productivity and Documents Pack

- Pack id: `productivity_documents_pack`
- Room/stage: Stage 5, Capability Room, Product Starter Room
- Offer model: `user_choice_optional`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Connects LaunchRoom to practical work artifacts: email, docs, sheets, presentations, notes, PDFs, OCR, and structured records.
- Runtime skills: `himalaya`, `google-workspace`, `notion`, `airtable`, `obsidian`, `powerpoint`, `nano-pdf`, `ocr-and-documents`, `teams-meeting-pipeline`
- Hidden candidates: `apple-notes`, `apple-reminders`
- Gates: OAuth/user-run auth gate, document write gate, macOS Apple app permission gate
- Blocked without gate: send email, edit cloud document, create reminder, read private notes without consent, secret readback

### Messaging and Social Publishing Pack

- Pack id: `messaging_social_pack`
- Room/stage: Stage 5, Capability Room
- Offer model: `communication_surface_optional`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Maps communication and social channels as user-facing control surfaces while keeping public messages and OAuth gated.
- Runtime skills: `governed-messaging-gateway-setup`, `himalaya`, `google-workspace`, `teams-meeting-pipeline`, `blogwatcher`
- Hidden candidates: `imessage`, `xurl`
- Gates: gateway setup gate, OAuth/user-run auth gate, explicit send/post approval, read-only first
- Blocked without gate: send message, send DM, post to social network, set home channel, approve gateway pairing, secret readback

### Apple Personal Operator Pack

- Pack id: `apple_personal_operator_pack`
- Room/stage: Foundation Room, Capability Room, Stage 5
- Offer model: `platform_conditional_macos_only`
- Default install: `false`
- Visibility: `environment_or_platform_candidate`
- Why valuable: High-value personal operator features for macOS users: Notes, Reminders, Find My, iMessage/SMS, and macOS background computer-use rules.
- Runtime skills: none
- Hidden candidates: `apple-notes`, `apple-reminders`, `findmy`, `imessage`, `macos-computer-use`
- Gates: host_os == macos, local app permissions, privacy explanation, explicit write/send/location confirmation
- Blocked without gate: location lookup, send iMessage/SMS, create reminders, read private notes, UI automation permission prompts

### AgentOps Executor Pack

- Pack id: `agentops_executor_pack`
- Room/stage: Stage 10, Readiness & Drift Room, AgentOps later
- Offer model: `advanced_gated`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Prepares durable multi-agent execution through external coding agents, workspaces, packets, verification arbiters, and later Kanban boards.
- Runtime skills: `claude-code`, `codex`, `opencode`, `autonomous-ai-agents`, `governed-agent-team-configuration`, `governed-agent-team-operator-setup`, `governed-agent-executor-loop`, `governed-executor-workspace`, `governed-packet-workflow-pilots`
- Hidden candidates: `kanban-orchestrator`, `kanban-worker`
- Gates: external agent tool readiness, workspace isolation, board/profile/dispatcher readiness for Kanban, owner implementation gate
- Blocked without gate: spawn autonomous agents, create Kanban tasks for real work, mutate external agent credentials/config, git publication

### CloudRoom and ModelOps Pack

- Pack id: `cloudroom_modelops_pack`
- Room/stage: CloudRoom later, Stage 10 advanced readiness
- Offer model: `advanced_gated`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Supports future model/runtime operations: read-only cloud inventory, n8n productization, observability, model evaluation, and local/server LLM serving planning.
- Runtime skills: `airmida-cloudflare-readonly-inventory`, `airmida-hetzner-readonly-inventory`, `airmida-n8n-full-mcp-connection`, `airmida-n8n-governed-workflow-ops`, `airmida-n8n-productization-package`, `airmida-n8n-runtime-maintenance`, `langfuse`, `huggingface-hub`, `llama-cpp`, `weights-and-biases`
- Hidden candidates: `evaluating-llms-harness`, `serving-llms-vllm`
- Gates: read-only first, runtime mutation gate, GPU/dependency/cost gate, model/license policy
- Blocked without gate: start public server, open network ports, download large models, run paid benchmarks, Cloudflare/Hetzner/n8n mutation

### LaunchRoom Sanitized Abstractions Pack

- Pack id: `launchroom_sanitized_abstractions_pack`
- Room/stage: Control & Evidence Room, AgentOps later
- Offer model: `advanced_optional_sanitized`
- Default install: `false`
- Visibility: `sanitized_launchroom_abstraction`
- Why valuable: Creates customer-safe LaunchRoom skills from proven internal operating patterns without mutating or exposing AIRMIDA internal operator skills.
- User-facing name: Safe Practice Pack
- Product decision: `keep_optional_only`
- Recommended sequence: `launchroom-memory-governance`, `launchroom-positive-result-capture`, `launchroom-tool-readiness-smoke`
- Runtime skills: none
- Sanitized abstraction skills: `launchroom-memory-governance`, `launchroom-positive-result-capture`, `launchroom-tool-readiness-smoke`
- Source lineage skills: `airmida-memory-stack-operator`, `governed-agent-memory-substrate`, `airmida-positive-result-capture`, `governed-agent-engineering-standards`, `airmida-external-agent-tool-readiness`
- Hidden candidates: none
- Gates: sanitization review gate, no AIRMIDA internal skill mutation, no private path/profile assumption leakage, owner approval before promotion into bundled profile
- Blocked without gate: patch airmida-* internal skills for public LaunchRoom use, copy AIRMIDA paths/profile/runtime assumptions into LaunchRoom public skills, install sanitized abstraction skills into beginner default, treat AIRMIDA internal skill as customer-facing authority

### AIRMIDA Internal Operator Pack

- Pack id: `airmida_internal_operator_pack`
- Room/stage: AIRMIDA workspace only, Control & Evidence Room
- Offer model: `workspace_conditional_internal_only`
- Default install: `false`
- Visibility: `runtime_enabled_now`
- Why valuable: Keeps AIRMIDA-specific governance, memory-stack, equipment catalog, n8n, Cloudflare/Hetzner, and positive-result workflows available to the AIRMIDA operator profile without exposing them as generic public defaults.
- Runtime skills: `airmida-governed-toolchain-onboarding`, `airmida-external-agent-tool-readiness`, `airmida-positive-result-capture`, `airmida-equipment-catalog-evidence`, `airmida-equipment-site-local-dev-drift-gate`, `airmida-n8n-lineage-surface-mapping`, `airmida-n8n-governed-workflow-ops`, `airmida-cloudflare-readonly-inventory`, `airmida-hetzner-readonly-inventory`, `airmida-memory-stack-operator`
- Hidden candidates: none
- Gates: AIRMIDA workspace detected, owner/Architect gate for authority/runtime, read-only first for external surfaces
- Blocked without gate: edit authority/canon/registry, mutate production runtime, git add/commit/push, read secrets

### Lab Restricted Pack

- Pack id: `lab_restricted_pack`
- Room/stage: internal lab only
- Offer model: `not_public_beginner_flow`
- Default install: `false`
- Visibility: `excluded_or_lab_only`
- Why valuable: Preserves powerful but high-risk capabilities for explicitly governed internal red-team or model-research sessions without advertising them to beginners.
- Runtime skills: `godmode`
- Hidden candidates: `obliteratus`
- Gates: owner lab gate, legal/ethics/model-license gate, no public beginner offer
- Blocked without gate: jailbreak/red-team execution, model refusal-removal workflow, model upload/publish, unsafe public guidance

## Hidden or advanced candidates

| Skill | Pack | Visibility | Condition | Public default | Gate |
|---|---|---|---|---:|---|
| `apple-notes` | `apple_personal_operator_pack` | `environment_or_platform_candidate` | macos | `false` | host_os == macos and user chooses Apple Notes integration |
| `apple-reminders` | `apple_personal_operator_pack` | `environment_or_platform_candidate` | macos | `false` | host_os == macos and user confirms reminder writes |
| `findmy` | `apple_personal_operator_pack` | `environment_or_platform_candidate` | macos | `false` | host_os == macos and user explicitly requests device/item location |
| `imessage` | `messaging_social_pack` | `environment_or_platform_candidate` | macos | `false` | host_os == macos and user confirms recipient/message |
| `macos-computer-use` | `apple_personal_operator_pack` | `environment_or_platform_candidate` | macos | `false` | host_os == macos and computer-use permissions are ready |
| `kanban-orchestrator` | `agentops_executor_pack` | `environment_or_platform_candidate` | kanban environment | `false` | Kanban board/profile/dispatcher/workspace readiness accepted |
| `kanban-worker` | `agentops_executor_pack` | `environment_or_platform_candidate` | kanban environment | `false` | Kanban dispatched worker context only |
| `evaluating-llms-harness` | `cloudroom_modelops_pack` | `environment_or_platform_candidate` | linux/macos + ML deps/GPU/API budget | `false` | ModelOps evaluation gate with cost controls |
| `serving-llms-vllm` | `cloudroom_modelops_pack` | `environment_or_platform_candidate` | linux/macos + GPU/server deps | `false` | Model serving runtime gate with local/server boundary |
| `audiocraft-audio-generation` | `creative_product_pack` | `environment_or_platform_candidate` | linux/macos + audio deps/GPU | `false` | creative media project choice + rights/runtime gate |
| `research-paper-writing` | `research_knowledge_pack` | `environment_or_platform_candidate` | linux/macos + refactor needed | `false` | slim skill refactor + citation verification gate |
| `xurl` | `messaging_social_pack` | `environment_or_platform_candidate` | linux/macos + X OAuth/CLI | `false` | user-run OAuth outside chat + read-only first + post approval |
| `python-debugpy` | `developer_builder_pack` | `environment_or_platform_candidate` | linux/macos now; Windows port needed | `false` | Windows port/verification + implementation gate |
| `obliteratus` | `lab_restricted_pack` | `excluded_or_lab_only` | linux/macos + internal lab only | `false` | owner legal/ethics/model-license lab gate only |

## Action boundary

- `skills_installed: false`
- `skills_enabled: false`
- `skills_promoted: false`
- `dependencies_installed: false`
- `toolsets_enabled_without_gate: false`
- `memory_written: false`
- `agents_spawned: false`
- `implementation_executed: false`
- `runtime_mutation: false`
- `cloud_mutation: false`
- `gateway_mutation: false`
- `n8n_mutation: false`
- `git_publication_executed: false`
- `secrets_read_or_written: false`

## Validation

```bash
python scripts/validate_skillpack_registry.py
```
