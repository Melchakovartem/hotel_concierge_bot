# Prompt Library

Папка `.prompts/` хранит готовые праймеринг-промпты для типовых сценариев работы с `Hotel Concierge Bot`.

## Как использовать

1. Выбери промпт под текущую задачу.
2. При необходимости подставь конкретный `FT-XXX` вместо placeholder.
3. Передай промпт агенту в начале новой сессии.
4. Если задача узкая, используй artifact-specific prompt; если нужен общий вход в работу — flow-specific prompt.

Подробный пошаговый процесс смотри в [`feature-workflow.md`](feature-workflow.md).

## Flow Prompts

- [`orient-triage.md`](orient-triage.md)
  Когда использовать: быстрый вход в проект, выбор релевантного `feature package` и следующего flow.

- [`spec.md`](spec.md)
  Когда использовать: подготовка, проверка или уточнение спецификации фичи.

- [`plan-implement.md`](plan-implement.md)
  Когда использовать: переход от feature contract к плану реализации и коду.

- [`review-verify.md`](review-verify.md)
  Когда использовать: review изменений относительно feature contract, acceptance criteria и test strategy.

- [`resume-continue.md`](resume-continue.md)
  Когда использовать: восстановление контекста после паузы и определение следующего шага.

## Artifact-Specific Prompts

- [`review-brief.md`](review-brief.md)
  Когда использовать: ревью `Brief` на полноту, однозначность и отсутствие solution bias.

- [`review-spec.md`](review-spec.md)
  Когда использовать: ревью `Spec` по критериям `TAUS` и дополнительным structural checks.

- [`review-plan.md`](review-plan.md)
  Когда использовать: ревью `Implementation Plan` на выполнимость, порядок шагов и grounding.

## Быстрый выбор

- Не знаешь, с чего начать: используй `orient-triage.md`.
- Работаешь с формулировкой задачи: используй `review-brief.md`.
- Проверяешь готовность спеки: используй `review-spec.md`.
- Проверяешь план перед реализацией: используй `review-plan.md`.
- Переходишь к коду: используй `plan-implement.md`.
- Проверяешь результат: используй `review-verify.md`.
- Возвращаешься к незавершенной фиче: используй `resume-continue.md`.
