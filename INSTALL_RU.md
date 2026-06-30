# Установка LaunchRoom Starter Pilot для Hermes

```yaml
document_type: user_install_guide
language: ru
pilot_status: public_zero_user_test_repo
secrets_rule: не вставляйте секреты в чат
```

## Важный вывод из реального теста

Просто дать Hermes ссылку на GitHub repository недостаточно.

Так Hermes только читает страницу. Он не получает активный сценарий.

Нужно установить `SKILL.md` как Hermes skill.

## Рабочий путь через терминал

Выполните:

```bash
hermes skills install https://raw.githubusercontent.com/Syntrion-AI/launchroom-starter-pilot/main/SKILL.md --yes
```

Текущий Hermes direct-URL installer устанавливает этот skill под техническим именем:

```text
main
```

Поэтому после установки начните новую сессию Hermes и явно загрузите:

```text
/skill main
```

Потом напишите:

```text
Я новый пользователь Hermes. Запусти LaunchRoom Stage 1.
```

## Что должно получиться

Hermes должен ответить коротко, примерно так:

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

## Если вы используете Hermes Desktop и не хотите терминал

Пока Desktop-first установка из GitHub URL не стабилизирована в этом пилоте, используйте fallback:

1. Откройте `SKILL.md` в этом репозитории.
2. Скопируйте весь текст `SKILL.md`.
3. Вставьте его в Hermes и скажите:

```text
Используй этот SKILL.md как активную инструкцию для LaunchRoom Stage 1.
Я новый пользователь Hermes.
Оставайся только в Stage 1.
```

Это лучше, чем просто давать ссылку на репозиторий.

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

## Известная проблема пилота

```yaml
known_issue:
  direct_url_skill_install_name: main
  desired_name: launchroom-starter-pilot
  status: needs_Hermes_install_UX_fix_or_registry_packaging
```

End of INSTALL_RU.
