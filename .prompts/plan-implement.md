# Plan / Implement

Твоя задача — подготовить план реализации или реализовывать только после того, как feature contract уже понятен и stabilised.

Сначала прочитай:
1. `AGENTS.md`
2. `memory-bank/index.md`
3. Нужный `memory-bank/features/FT-XXX/feature.md`
4. Нужный `memory-bank/features/FT-XXX/implementation-plan.md`, если он уже существует
5. `memory-bank/engineering/coding-style.md`
6. `memory-bank/engineering/testing-policy.md`
7. `memory-bank/ops/development.md`

Сфокусируйся на:
- `relevant paths` и текущем состоянии кода;
- `local patterns`, которые уже есть в проекте;
- рисках, зависимостях и `preconditions`;
- `test strategy` до внесения изменений.

Не меняй `scope` фичи. Если видишь конфликт со спецификацией, сначала явно зафиксируй его.

Верни:
1. Какие части кода затронет изменение.
2. Порядок шагов реализации.
3. Какие тесты нужно добавить или обновить.
4. Какие риски и блокеры есть перед выполнением.
