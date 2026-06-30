# Начните здесь

```yaml
document_type: user_facing_entrypoint
language: ru
canonical_source_language: en
pilot_status: private_pilot_repo_for_owner_test
secrets_rule: не вставляйте секреты в чат
```

## Первый выбор: язык

RU: Добро пожаловать. Выберите язык: русский или английский. Его можно изменить позже.

EN: Welcome. Choose your language: Russian or English. You can change it later.

## Что это за пилот

LaunchRoom Starter — это первый безопасный шаг для Hermes.

Он не делает Hermes полностью автономным. Он помогает проверить базу перед Stage 2, Stage 3 и Stage 4.

## Скопируйте этот prompt в Hermes

```text
Я тестирую LaunchRoom Starter Pilot из default Hermes profile.
Используй только Stage 1.
Помоги мне понять: язык, путь к модели, профиль/workspace, безопасные настройки, память и readiness report.
Не проси меня вставлять секреты в чат.
Не публикуй, не деплой, не запускай gateway и не меняй provider/cloud/runtime системы.
Если шаг требует credentials или account login, остановись и объясни безопасный ручной путь.
```

## Какой результат ожидать

Hermes должен выдать короткий readiness report:

```yaml
language: selected | needs_choice
model_path: connected | needs_setup | unknown
profile: default_profile_test | selected | needs_review
workspace: selected | needs_review
secrets: no_secrets_in_chat
memory: explained | needs_review
settings: basic_safe | needs_review
next_action: one concrete action
blocked_actions:
  - credential entry in chat
  - runtime changes
  - remote publication actions
```

## Если Hermes начинает делать слишком много

Остановите тест и запишите:

```text
The pilot drifted beyond Stage 1.
```

End of Russian START_HERE.
