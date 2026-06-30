# Начните здесь

```yaml
document_type: user_facing_entrypoint
language: ru
canonical_source_language: en
pilot_status: public_zero_user_test_repo
secrets_rule: не вставляйте секреты в чат
```

## Скопируйте это в Hermes

```text
Я новый пользователь Hermes и тестирую LaunchRoom Starter Pilot.
Репозиторий: https://github.com/Syntrion-AI/launchroom-starter-pilot
Оставайся только в Stage 1.
Дай мне простой гид для новичка, не технический аудит.
Не меняй мой профиль, настройки, workspace, файлы, skills, gateway, provider, cloud, runtime или GitHub repository.
Не проси меня вставлять секреты в чат.
Сначала объясни в 3 коротких шага, что мне делать дальше.
Потом дай маленькую readiness-проверку только с полями: язык, модель, workspace, секреты, следующий шаг.
Если ты не можешь прочитать repository URL, попроси меня вставить текст этого START_HERE.ru.md и не угадывай.
```

## Что должно произойти

Hermes должен ответить как простой помощник для новичка:

```text
1. Подтвердить язык.
2. Подтвердить, что модель уже отвечает.
3. Помочь выбрать или оставить простой workspace.
```

Потом Hermes должен дать маленький результат:

```yaml
language: selected | needs_choice
model: working | needs_setup | unknown
workspace: keep_current | choose_simple_folder | unknown
secrets: no_secrets_in_chat
next_action: one simple action
```

## Остановите тест, если Hermes делает это

```yaml
stop_if:
  - сам меняет настройки
  - сам создаёт или переключает projects
  - сам создаёт файлы
  - создаёт или патчит skills
  - запускает gateway/cloud/runtime/provider setup
  - просит секреты в чат
  - выдаёт длинный технический аудит вместо простого гайда
```

End of Russian START_HERE.
