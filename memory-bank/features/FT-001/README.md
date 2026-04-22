---
title: "FT-001: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по FT-001. Читать сначала, чтобы перейти к canonical feature contract и implementation plan."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-001: Feature Package

## О разделе

Этот package хранит мигрированную feature-документацию для защиты списка отелей в админке через Staff identity и role-based access.

Сначала читай `feature.md`: там зафиксированы canonical scope, design, acceptance scenarios, checks и evidence. Затем читай `implementation-plan.md`, если нужен порядок исполнения и grounding.

## Аннотированный индекс

- [`feature.md`](feature.md)
  **Что:** Canonical feature contract для замены hardcoded admin Basic Auth на Staff-backed authentication и role-based access к `GET /admin/hotels`.
  **Читать, чтобы:** понять scope, non-scope, design, verification и traceability для FT-001.

- [`implementation-plan.md`](implementation-plan.md)
  **Что:** Derived execution plan, мигрированный из исходного `plan.md`.
  **Читать, чтобы:** реализовать или проверить ordered steps, dependencies, checkpoints и test strategy без переопределения feature scope.
