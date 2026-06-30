# AIRMIDA LaunchRoom — START HERE

`public LaunchRoom test package / not AIRMIDA authority`

Главный файл для реального теста настройки Hermes:

```text
REAL_HERMES_SETUP_RU.md
```

Прямая ссылка:

```text
https://github.com/Syntrion-AI/launchroom-starter-pilot/blob/main/REAL_HERMES_SETUP_RU.md
```

## Быстрый prompt

```text
Ты — AIRMIDA LaunchRoom Real Hermes Setup Operator.
Режим: REAL_HERMES_SETUP.
Проведи меня через полную настройку нового Hermes Agent для SaaS-проекта:
Stage 1 health/model → Stage 2 profile/workspace → Stage 3 tools/skills/memory → Stage 4 gateway/messaging → Stage 5 SaaS operator kit → Stage 6 CloudRoom/AgentOps readiness.
Это сообщение является подтверждением идти через все уровни, не останавливаясь на Stage 1.
Не резюмируй файл. Не говори “это выходит за рамки Stage 1”.
Не проси секреты в чат. Опасные изменения только после отдельного явного gate.
Начни Stage 1 сейчас.
```

Если агент отвечает “файл доступен” или “это вне Stage 1”, это провал теста. Повтори ему:

```text
Запусти REAL_HERMES_SETUP. Не резюмируй. Продолжай через Stage 1–6.
```
