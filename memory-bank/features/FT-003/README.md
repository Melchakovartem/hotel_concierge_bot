---
title: "FT-003: Feature Package"
doc_kind: feature
doc_function: index
purpose: "Bootstrap-safe навигация по FT-003. Читать сначала, чтобы перейти к canonical feature contract и implementation plan."
derived_from:
  - ../../dna/governance.md
  - feature.md
status: active
audience: humans_and_agents
---

# FT-003: Feature Package

## О разделе

Этот package хранит мигрированную feature-документацию для операционного ticket workflow персонала отеля без участия `admin`: namespace `/operations/**`, HTTP Basic Auth с realm `Operations`, manager staff creation, manager ticket assignment/update и staff ticket transitions (start/complete).

Сначала читай `feature.md`: там зафиксированы canonical scope, design, authorization matrix, invariants, service contracts, acceptance scenarios, checks и evidence. Затем читай `implementation-plan.md`, если нужен порядок исполнения и grounding по слоям.

## Аннотированный индекс

- [`feature.md`](feature.md)
  **Что:** Canonical feature contract для создания operations namespace, Staff-backed HTTP Basic Auth с realm `Operations`, manager staff creation, manager ticket assignment/status update и staff ticket transitions без участия `admin`.
  **Читать, чтобы:** понять scope, non-scope, invariants, authorization matrix, service/query contracts, failure modes, verification и traceability для FT-003.

- [`implementation-plan.md`](implementation-plan.md)
  **Что:** Derived execution plan, мигрированный из исходного `plan.md`. Разбит на 8 слоёв: данные/инварианты, namespace/auth shell, services/queries, и вертикальные slices по ролям.
  **Читать, чтобы:** реализовать или проверить ordered steps, layer dependencies, checkpoints, test strategy и risks без переопределения feature scope.
