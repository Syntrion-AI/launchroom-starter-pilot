# AIRMIDA LaunchRoom — установка и полный тест

`public LaunchRoom test package / not AIRMIDA authority`

## Самый правильный тест

1. Открой `FULL_SETUP_TEST_RU.md`.
2. Скопируй главный prompt в новую Hermes-сессию.
3. Проверь, что агент начинает Stage 1 и дальше спрашивает переход на Stage 2, Stage 3, Stage 4, Stage 5, Stage 6.

## Установка как Hermes skill

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
hermes skills list
```

В новой сессии:

```text
/skill launchroom-starter-pilot
Проведи меня по полному LaunchRoom setup нового Hermes agent от Stage 1 до Stage 6.
```

Если skill установился под другим именем, используй имя из `hermes skills list`.

## Проверка репозитория

```bash
python scripts/build_agentpack.py --check
python scripts/doctor.py
```
