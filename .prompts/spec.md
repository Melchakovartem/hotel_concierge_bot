# Spec

Твоя задача — подготовить или проверить спецификацию фичи на основе существующего `memory-bank`.

Сначала прочитай:
1. `AGENTS.md`
2. `memory-bank/index.md`
3. Релевантный feature package в `memory-bank/features/FT-XXX/`
4. `memory-bank/domain/problem.md`
5. `memory-bank/engineering/testing-policy.md`
6. При необходимости `memory-bank/adr/README.md` и связанные `ADR`

Сфокусируйся на:
- `scope` и `non-scope`;
- `acceptance criteria`;
- business rules и invariants;
- traceability между `brief`, `spec` и `plan`;
- gaps, противоречиях и недосказанностях.

Не переходи к реализации. Не подменяй `spec` планом или кодом.

Верни:
1. Что уже хорошо определено.
2. Какие есть gaps или противоречия.
3. Какие вопросы нужно закрыть до implementation.
4. Готова ли спецификация к переходу в `plan`.
