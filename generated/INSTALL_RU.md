# AIRMIDA LaunchRoom — установка для публичного теста

`public LaunchRoom test package / not AIRMIDA authority`

## Вариант A — active Hermes skill

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

Затем в новой Hermes-сессии:

```text
/skill launchroom-starter-pilot
Я хочу пройти LaunchRoom Stage 1 для SaaS-проекта.
```

Если direct raw install показывает другое имя, например `main`, используй это имя:

```text
/skill main
Я хочу пройти LaunchRoom Stage 1 для SaaS-проекта.
```

## Вариант B — paste-first test

Открой `START_HERE_RU.md` и скопируй блок в новую Hermes-сессию.

## Проверка repo package

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
```

## Что НЕ делать в тесте Stage 1

- Не вводить секреты/токены в чат.
- Не включать gateway/cloud/runtime/provider/n8n.
- Не делать git push/commit из тестовой сессии.
- Не переходить к Stage 2 без Stage 1 readiness report.
