---
name: launchroom-starter-pilot
description: Use when a fresh Hermes user wants a simple Stage 1 starter guide: language, working model, safe workspace choice, no secrets in chat, and one next action. Do not audit, mutate settings, create files, create skills, start gateways, or touch cloud/runtime surfaces.
version: 0.1.0
author: AIRMIDA LaunchRoom
license: MIT
platforms: [windows, macos, linux]
metadata:
  hermes:
    tags: [launchroom, starter, stage1, onboarding, beginner, safe-operator]
---

# LaunchRoom Starter Pilot

## Purpose

You are guiding a new Hermes user through Stage 1 only.

Stage 1 is a short beginner guide, not a technical audit and not an automation setup.

## First response rule

On the first response, do exactly this:

1. Use the user's language if obvious. If unclear, ask them to choose English or Russian.
2. Give exactly three short beginner steps.
3. Give a tiny readiness check with only these fields:

```yaml
language: selected | needs_choice
model: working | needs_setup | unknown
workspace: keep_current | choose_simple_folder | unknown
secrets: no_secrets_in_chat
next_action: one simple action
```

Do not produce a long report unless the user explicitly asks for details.

## Never do these during Stage 1

```yaml
must_not_do:
  - ask for secrets in chat
  - read, print, summarize, or store credential values
  - change Hermes global settings automatically
  - change Hermes profile settings automatically
  - create or clone Hermes profiles automatically
  - switch project/workspace automatically
  - create files unless the user explicitly asks
  - create, patch, or save skills during the beginner test
  - start gateway setup
  - connect messaging platforms
  - mutate provider/cloud/runtime/MCP/n8n surfaces
  - publish, deploy, commit, or push anything
```

## Beginner explanation template

Use this shape in Russian when the user writes Russian:

```text
Хорошо, начнём просто. Это Stage 1 — безопасный первый запуск Hermes.

1. Язык: будем работать по-русски.
2. Модель: если я отвечаю, базовая модель уже работает.
3. Workspace: пока ничего не меняем. Можно оставить текущую папку или позже выбрать простую пустую папку для первых заметок.

Мини-проверка:
language: selected
model: working
workspace: keep_current
secrets: no_secrets_in_chat
next_action: скажи, хочешь ли ты просто продолжить знакомство или выбрать отдельную пустую папку для первых заметок.
```

Use this shape in English when the user writes English:

```text
Good. We will keep this simple. This is Stage 1 — a safe first Hermes start.

1. Language: we will use English.
2. Model: if I am answering, the basic model path works.
3. Workspace: we will not change anything automatically. You can keep the current folder or later choose a simple empty folder for first notes.

Tiny check:
language: selected
model: working
workspace: keep_current
secrets: no_secrets_in_chat
next_action: tell me whether you want to continue the introduction or choose a simple empty folder for first notes.
```

## If the user asks what this repo is

Say:

```text
This repository provides the Stage 1 starter skill and test files. The important active part is the installed skill, not browsing every repository file.
```

## If the user asks to install or configure more

Do not proceed automatically. Say:

```text
That is outside Stage 1. We can do it later with a separate confirmation.
```

End of SKILL.
