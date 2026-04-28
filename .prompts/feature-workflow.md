# Feature Workflow

Этот документ описывает рабочий процесс для подготовки новой фичи через `memory-bank`:

`бизнес-постановка -> feature.md -> review feature.md -> implementation-plan.md -> review implementation-plan.md`

Инструкция рассчитана на работу через `CLI`-агента и использует промпты из этой папки.

## Общий принцип

Не делай все этапы в одной длинной сессии.

Правильная последовательность:

1. Подготовить и отревьюить `brief` / бизнес-постановку.
2. Сгенерировать `feature.md`.
3. Отревьюить `feature.md` до нуля замечаний.
4. Сгенерировать `implementation-plan.md`.
5. Отревьюить `implementation-plan.md` до нуля замечаний.
6. Только потом переходить к реализации.

## 0. Подготовка

Перейди в проект:

```bash
cd /Users/artemmelcakov/Documents/projects/learning/ai-swe/hotel_concierge_bot
```

Задай идентификатор новой фичи:

```bash
export FT=FT-004
export FT_DIR="memory-bank/features/$FT"
```

Если package еще не создан:

```bash
mkdir -p "$FT_DIR"
```

Посмотреть доступные промпты:

```bash
find .prompts -maxdepth 1 -type f | sort
```

## 1. Если бизнес-постановка сырая: сначала review brief

Если у тебя есть только исходная формулировка вроде:

> нужно реализовать авторизацию для пользователя

то сначала нужно довести ее до нормального `brief`.

Создай черновик:

```bash
mkdir -p tmp/ai
cat > tmp/ai/brief-input.md <<'EOF'
Нужно реализовать авторизацию для пользователя.
EOF
```

Открой prompt:

```bash
cat .prompts/review-brief.md
```

Что передавать агенту:

- содержимое `.prompts/review-brief.md`
- содержимое `tmp/ai/brief-input.md`

Цель этой сессии:

- найти проблемы в постановке;
- исправить их автоматически, если это возможно;
- задать тебе вопросы, если без тебя нельзя принять решение.

Повторяй цикл, пока не получишь вердикт:

`Замечаний нет, Brief готов к работе`.

Итоговый вариант можно сохранить, например, так:

```bash
cat > tmp/ai/brief-final.md
```

## 2. Сгенерировать `feature.md` из brief

Для этого нужна новая отдельная сессия.

Сначала покажи агенту входной routing prompt:

```bash
cat .prompts/orient-triage.md
```

Потом основной prompt для подготовки `feature.md`:

```bash
cat .prompts/spec.md
```

После этого дай агенту явную задачу:

```md
Используй этот flow для подготовки feature package.

Контекст:
- Бизнес-постановка лежит в `tmp/ai/brief-final.md`
- Новый feature package: `memory-bank/features/FT-004/`
- Нужно создать canonical `feature.md` по правилам `memory-bank/flows/feature-flow.md`

Требования:
1. Прочитай `AGENTS.md`, `memory-bank/index.md`, `memory-bank/domain/problem.md`, `memory-bank/features/README.md`
2. Найди релевантные существующие feature packages
3. На основе brief собери draft `memory-bank/features/FT-004/feature.md`
4. Используй format и depth, совместимые с `FT-001`, `FT-002`, `FT-003`
5. В документе должны быть `What`, `How`, `Verify`, stable identifiers и traceability
6. Не переходи к `implementation-plan.md`
```

Для ориентира можно быстро открыть существующие примеры:

```bash
sed -n '1,220p' memory-bank/features/FT-001/feature.md
sed -n '1,220p' memory-bank/features/FT-002/feature.md
sed -n '1,220p' memory-bank/features/FT-003/feature.md
```

## 3. Отревьюить `feature.md` до нуля замечаний

Для этого нужна еще одна новая сессия.

Открой prompt:

```bash
cat .prompts/review-spec.md
```

Передай агенту:

- содержимое `.prompts/review-spec.md`
- путь `memory-bank/features/$FT/feature.md`

Рекомендуемая постановка:

```md
Проверь `memory-bank/features/FT-004/feature.md` по этому prompt.
Если есть замечания — исправь их самостоятельно в документе.
Если чего-то не хватает и ты не можешь принять решение без меня — задай точечные вопросы.
После правок снова проверь документ.
Остановись только когда замечаний больше нет.
```

После каждого прохода полезно смотреть diff:

```bash
git diff -- memory-bank/features/$FT/feature.md
```

Повторяй цикл, пока не получишь:

`Замечаний нет, спека готова к реализации`.

## 4. Сгенерировать `implementation-plan.md` из готового `feature.md`

Это делается только после того, как `feature.md` стабилен.

Открой prompt:

```bash
cat .prompts/plan-implement.md
```

Постановка агенту:

```md
Нужно создать `memory-bank/features/FT-004/implementation-plan.md` как derived document от `memory-bank/features/FT-004/feature.md`.

Требования:
1. Не меняй scope фичи
2. Сделай grounding на реальные пути и модули проекта
3. Заполни:
   - Current State / Reference Points
   - Test Strategy
   - Open Questions / Ambiguities
   - Environment Contract
   - Preconditions
   - Workstreams
   - Approval Gates
   - Work Order
   - Parallelizable Work
   - Checkpoints
   - Execution Risks
   - Stop Conditions / Fallback
   - Ready For Acceptance
4. Используй стиль и глубину, совместимые с `FT-001`, `FT-002`, `FT-003`
5. Не переходи к реализации кода
```

Для ориентира можно открыть примеры:

```bash
sed -n '1,260p' memory-bank/features/FT-001/implementation-plan.md
sed -n '1,260p' memory-bank/features/FT-002/implementation-plan.md
sed -n '1,260p' memory-bank/features/FT-003/implementation-plan.md
```

## 5. Отревьюить `implementation-plan.md` до нуля замечаний

Еще одна отдельная сессия.

Открой prompt:

```bash
cat .prompts/review-plan.md
```

Передай агенту:

- содержимое `.prompts/review-plan.md`
- путь `memory-bank/features/$FT/implementation-plan.md`

Рекомендуемая постановка:

```md
Проверь `memory-bank/features/FT-004/implementation-plan.md`.
Если замечания есть — исправь их самостоятельно в документе.
Если исправить без моего решения нельзя — задай точечные вопросы.
После правок снова проверь план и остановись только когда замечаний не останется.
```

После каждого прохода:

```bash
git diff -- memory-bank/features/$FT/implementation-plan.md
```

Цель:

`Замечаний нет, план готов к реализации`.

## 6. Минимальный полный pipeline

Если кратко, для каждой новой фичи:

```bash
cd /Users/artemmelcakov/Documents/projects/learning/ai-swe/hotel_concierge_bot
export FT=FT-004
export FT_DIR="memory-bank/features/$FT"
mkdir -p "$FT_DIR"
```

Дальше по отдельным сессиям:

1. `review-brief.md`
2. `orient-triage.md` + `spec.md`
3. `review-spec.md`
4. `plan-implement.md`
5. `review-plan.md`

## 7. Простая автоматизация

Чтобы не вспоминать каждый раз пути, можно добавить такие функции в `~/.zshrc`:

```bash
ft() {
  export FT="$1"
  export FT_DIR="memory-bank/features/$FT"
  echo "FT=$FT"
  echo "FT_DIR=$FT_DIR"
}

pp() {
  cat ".prompts/$1.md"
}

ftshow() {
  echo "Feature dir: $FT_DIR"
  find "$FT_DIR" -maxdepth 1 -type f | sort
}
```

Применить:

```bash
source ~/.zshrc
```

Использование:

```bash
cd /Users/artemmelcakov/Documents/projects/learning/ai-swe/hotel_concierge_bot
ft FT-004
pp orient-triage
pp spec
pp review-spec
pp plan-implement
pp review-plan
ftshow
```

## 8. Практический пример

Пример для задачи "реализовать авторизацию пользователя":

```bash
cd /Users/artemmelcakov/Documents/projects/learning/ai-swe/hotel_concierge_bot
ft FT-004
mkdir -p tmp/ai
cat > tmp/ai/brief-input.md <<'EOF'
Нужно реализовать авторизацию для пользователя.
EOF
```

Дальше:

1. Новая сессия: `pp review-brief` + текст из `tmp/ai/brief-input.md`
2. Сохранить улучшенный brief в `tmp/ai/brief-final.md`
3. Новая сессия: `pp orient-triage`, потом `pp spec`, потом попросить создать `memory-bank/features/FT-004/feature.md`
4. Новая сессия: `pp review-spec`, потом довести `feature.md` до нуля замечаний
5. Новая сессия: `pp plan-implement`, потом попросить создать `implementation-plan.md`
6. Новая сессия: `pp review-plan`, потом довести план до нуля замечаний

## 9. Важное правило

Не смешивай этапы.

Плохо:

- в одной сессии писать `feature.md`, тут же его ревьюить, тут же писать `implementation-plan.md`, тут же начинать код.

Хорошо:

- отдельная сессия на authoring;
- отдельная на review;
- отдельная на следующий артефакт.

## 10. Что можно улучшить потом

Сейчас уже есть рабочий набор prompt-ов, но в будущем можно добавить еще два authoring prompt-а:

- `.prompts/write-feature.md`
- `.prompts/write-plan.md`

Сейчас их роль выполняют:

- `.prompts/spec.md` — для подготовки `feature.md`
- `.prompts/plan-implement.md` — для подготовки `implementation-plan.md`
