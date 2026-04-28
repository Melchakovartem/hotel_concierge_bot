# Review / Verify

Твоя задача — сделать review и verification текущего изменения относительно feature contract.

Сначала прочитай:
1. `AGENTS.md`
2. `memory-bank/index.md`
3. Релевантный `memory-bank/features/FT-XXX/feature.md`
4. Релевантный `memory-bank/features/FT-XXX/implementation-plan.md`
5. `memory-bank/engineering/testing-policy.md`

Если есть `diff`, review делай только относительно `spec` и `plan`, а не по абстрактным предпочтениям.

Сфокусируйся на:
- behavioral regressions;
- несоответствиях между кодом и `acceptance criteria`;
- missing tests;
- `scope creep`;
- рисках по auth, invariants, data flow и error handling.

Не переписывай спецификацию задним числом под уже существующий код.

Верни:
1. Findings по severity.
2. Какие `acceptance criteria` покрыты.
3. Какие `acceptance criteria` не покрыты или покрыты слабо.
4. Какие тесты или проверки еще нужны.
