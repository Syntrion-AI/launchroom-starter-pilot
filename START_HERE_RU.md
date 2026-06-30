# Начните здесь

```yaml
document_type: user_facing_entrypoint
language: ru
pilot_status: public_zero_user_test_repo
secrets_rule: не вставляйте секреты в чат
```

## Важное исправление

Просто дать Hermes ссылку на GitHub репозиторий недостаточно.

Чтобы LaunchRoom реально заработал как сценарий, нужно загрузить `SKILL.md`.

## Лучший тест

Откройте:

```text
INSTALL_RU.md
```

И следуйте установке skill.

## Быстрый fallback без установки

Если вы не хотите устанавливать skill, откройте `SKILL.md`, скопируйте его целиком и вставьте в Hermes с сообщением:

```text
Используй этот SKILL.md как активную инструкцию для LaunchRoom Stage 1.
Я новый пользователь Hermes.
Оставайся только в Stage 1.
```

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
