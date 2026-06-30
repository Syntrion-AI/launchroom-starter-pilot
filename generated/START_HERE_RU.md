# AIRMIDA LaunchRoom — старт для Hermes

`public LaunchRoom test package / not AIRMIDA authority`

Скопируй этот блок в новую сессию Hermes:

```text
Загрузи роль AIRMIDA LaunchRoom Guide.
Я хочу пройти LaunchRoom Stage 1 для SaaS-проекта.
Работай по-русски.
Не создавай файлы, skills, projects, gateway, provider, runtime или cloud-настройки без моего отдельного разрешения.
Не проси секреты в чат.
Сначала дай простой ответ для новичка: 3 шага, мини-readiness и ровно одно следующее действие.
```

## Что делает Stage 1

User gets a working Hermes baseline: language, model/provider path, profile/workspace, safe settings buckets, first communication channel choice, and readiness report.

## Gate Stage 1

- language selected
- model/provider path explained: subscription or API key without secret readback
- profile/workspace decision selected or consciously deferred
- settings explained as safe buckets, not raw technical dump
- first channel selected or deferred: Telegram/Discord/Slack/Gmail/Email/WhatsApp where supported
- readiness report produced with one next action

Если gate не выполнен, агент НЕ должен переводить тебя на Stage 2. Он должен сказать, что заблокировано, и дать одно безопасное следующее действие.

## После Stage 1

Переход к Stage 2 разрешён только после `STAGE_1_READINESS_REPORT` со статусом `pass`, `pass_with_owner_acceptance` или явным owner acceptance.
