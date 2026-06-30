# Начните здесь

```yaml
document_type: user_facing_entrypoint
language: ru
pilot_status: public_zero_user_test_repo
secrets_rule: не вставляйте секреты в чат
```

## Главный вывод

Не начинайте с простой ссылки на репозиторий.

Сначала откройте:

```text
INSTALL_RU.md
```

И установите skill.

## Быстрый путь

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
```

Потом в новой сессии Hermes:

```text
/skill main
Я новый пользователь Hermes. Запусти LaunchRoom Stage 1.
```

Да, сейчас skill загружается как `/skill main`. Это известная проблема пилота и будет исправляться упаковкой/registry path позже.

## Что должен ответить Hermes

Коротко, без аудита:

```yaml
language: selected
model: working
workspace: keep_current | choose_simple_folder
secrets: no_secrets_in_chat
next_action: one simple action
```

End of START_HERE_RU.
