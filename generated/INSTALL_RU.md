# AIRMIDA LaunchRoom — установка и реальный тест Hermes setup

`public LaunchRoom test package / not AIRMIDA authority`

## Главный тест

1. Открой `REAL_HERMES_SETUP_RU.md`.
2. Скопируй главный prompt в новую Hermes-сессию.
3. Агент должен провести Stage 1–6 как реальную настройку Hermes, а не как резюме файла.

## Установка как skill

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

В новой сессии:

```text
/skill launchroom-starter-pilot
Проведи меня через REAL_HERMES_SETUP для нового Hermes agent от Stage 1 до Stage 6.
```

## Если terminal в тестовой среде не работает

Используй PowerShell вручную и вставь sanitized output:

```powershell
$ErrorActionPreference = "Continue"
where.exe hermes
hermes --version
hermes status
hermes doctor
hermes config path
hermes profile list
hermes tools list
hermes skills list
hermes memory status
hermes gateway status
```

Не вставляй secrets, `.env`, `auth.json`, tokens, keys, passwords.
