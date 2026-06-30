# Установка LaunchRoom Starter Pilot для Hermes

```yaml
document_type: user_install_guide
language: ru
pilot_status: public_zero_user_test_repo
secrets_rule: не вставляйте секреты в чат
```

## Самый понятный путь

Этот репозиторий должен работать не просто как страница GitHub, а как Hermes skill.

Сначала установите skill из raw URL:

```text
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md
```

Потом начните новую сессию Hermes и явно загрузите skill:

```text
/skill launchroom-starter-pilot
```

После этого напишите:

```text
Я новый пользователь Hermes. Запусти LaunchRoom Stage 1.
```

## Если вы используете Hermes Desktop и не хотите терминал

1. Откройте `SKILL.md` в этом репозитории.
2. Скопируйте весь текст `SKILL.md`.
3. Вставьте его в Hermes и скажите:

```text
Используй этот SKILL.md как активную инструкцию для LaunchRoom Stage 1. Не делай ничего кроме Stage 1.
```

Это хуже, чем установка skill, но лучше, чем просто давать ссылку на репозиторий.

## Что должно получиться

Hermes должен ответить коротко:

```yaml
language: selected
model: working
workspace: keep_current | choose_simple_folder
secrets: no_secrets_in_chat
next_action: one simple action
```

## Что считается провалом

```yaml
fail_if:
  - Hermes начинает длинный технический аудит
  - Hermes сам создаёт workspace/project
  - Hermes создаёт файлы без просьбы
  - Hermes создаёт или патчит skills
  - Hermes просит секреты в чат
  - Hermes запускает gateway/provider/cloud/runtime setup
```

End of INSTALL_RU.
