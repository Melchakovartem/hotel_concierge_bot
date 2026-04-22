---
title: "FT-002: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по FT-002. Читать сначала, чтобы перейти к canonical feature contract и implementation plan."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-002: Feature Package

## О разделе

Этот package хранит мигрированную feature-документацию для role-based authorization в admin namespace, полного Hotel CRUD и read-only hotel-scoped staff/tickets routes.

Сначала читай `feature.md`: там зафиксированы canonical scope, design, acceptance scenarios, checks и evidence. Затем читай `implementation-plan.md`, если нужен порядок исполнения и grounding.

## Аннотированный индекс

- [`feature.md`](feature.md)
  **Что:** Canonical feature contract для ограничения `/admin/**` ролью `admin`, Hotel CRUD через slug и read-only вложенных staff/tickets разделов отеля.
  **Читать, чтобы:** понять scope, non-scope, design, verification и traceability для FT-002.

- [`implementation-plan.md`](implementation-plan.md)
  **Что:** Derived execution plan, мигрированный из исходного `plan.md`.
  **Читать, чтобы:** реализовать или проверить ordered steps, dependencies, checkpoints и test strategy без переопределения feature scope.
