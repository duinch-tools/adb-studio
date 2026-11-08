# adb-studio — AI Agent Engineering & Security Contract

> Managed by `project-pro` (`.agents/project-profile.json`). Every coding task MUST follow the 6-Gate Execution Harness.

## 1. Architectural Profile
- **Stack**: iOS / Swift (SwiftUI + Swift 6 Concurrency)
- **Architecture**: `clean` | **Flow / State Pattern**: `mvvm-udf`
- **Gold-Standard Reference Repo**: [`nalexn/clean-architecture-swiftui`](https://github.com/nalexn/clean-architecture-swiftui) — **consult & adapt patterns from this repo instead of inventing custom structures.**
- **Enabled Capabilities**: `solid-dry`, `typed-errors`, `di-core`, `network-storage`, `ui-nav`, `arch-lint`, `testing-ci`

## 2. Canonical Commands
- **Build**: `swift build`
- **Run All Tests**: `swift test`
- **Run Single Test**: `swift test --filter <TargetTests>.<TestCase>`
- **Lint & Typecheck**: `swiftlint lint --strict && swift-format lint -r Packages`
- **Security Audit**: `swift package show-dependencies`

## 3. Layer & Module Dependency Rules
- **Dependency Rule**: `Presentation/Entrypoints -> Domain <- Data/Adapters`.
- **Domain Layer**: 100% pure language types. ZERO imports from UI frameworks, HTTP clients, ORMs, or Data/Presentation packages.
- **Data Layer**: Owns wire `*Dto` & DB `*Entity` models, implements Domain repository ports, maps errors to typed `DomainError`.
- **Presentation Layer**: Stateless declarative UI + framework-free State Holder (`Sealed UiState`, `Intent`/`Event`, `Effect`).
- **Boundary Enforcement**: Local Swift Package Manager (Package.swift target dependencies) + SwiftLint

## 4. Mandatory 6-Gate Execution & Behavioral Guardrails
1. **Think & Ground (`karpathy-skills`)**: Read `.agents/CODEBASE_MAP.md`, `.agents/memory/lessons.md`, and `referenceRepo` before coding. Surface hidden assumptions; push back on unsafe anti-patterns; write `.agents/memory/active-plan.md` for > 3-file tasks.
2. **Surgical & Bounded Files**: Touch ONLY lines/files required. **1 File = 1 Primary Responsibility** (`> 300 LOC` = WARN, `> 450 LOC` = FAIL).
3. **Disciplined Coding (`obra/superpowers`)**: Build Inside-Out (`Domain -> Data -> State -> UI`) using the layer-specific models and state holder. For bugs, trace **Root Cause** + **3-Strike Stop** (if 3 fixes fail, STOP & re-evaluate architecture). Zero unfinished stubs, zero dead code.
4. **SOLID & Anti-False-DRY**: Separate `*Dto`, `*Entity`, `Domain`, and `*UiState` models. Sealed states over boolean soup (`isLoading && isError` banned). Guard clauses (`<= 3` indent levels), immutable by default.
5. **Security & Paranoid Review (`gstack`)**: Zero hardcoded secrets, parameterized SQL, redacted logs, check race conditions/N+1/pagination bounds. Never bypass Git hooks with `--no-verify`.
6. **Self-Healing & Terse Delivery (`caveman`)**: Run `Single Test` -> `Lint/Typecheck` -> `audit` until green; log non-obvious pitfalls to `.agents/memory/lessons.md`; report concisely with file links.

## 5. Scoped Rules, Memory & Architecture Docs (Read on Demand)
- Task & Sub-Agent Workflow: [`.agents/rules/task-workflow.md`](./.agents/rules/task-workflow.md)
- Codebase Map & Memory: [`.agents/CODEBASE_MAP.md`](./.agents/CODEBASE_MAP.md) | [`active-plan.md`](./.agents/memory/active-plan.md) | [`lessons.md`](./.agents/memory/lessons.md)
- Execution & Security: [`.agents/rules/execution-harness.md`](./.agents/rules/execution-harness.md) | [`.agents/rules/security-gate.md`](./.agents/rules/security-gate.md)
- Layer Guardrails: [`domain`](./.agents/rules/domain-layer.md) | [`data`](./.agents/rules/data-layer.md) | [`presentation`](./.agents/rules/presentation-layer.md)
- ADR-0001: [`docs/architecture/ADR-0001-architecture.md`](./docs/architecture/ADR-0001-architecture.md)

## 6. GitHub Project Board & Parallel Sub-Agent Execution
- **1 Task = 1 GitHub Issue**: Managed via `scripts/workflow.py`.
- **Kanban Progression**: `Todo` (created) -> `In Progress` (started on branch `feat/issue-<id>`) -> `Done` (verified & closed).
- **Parallel Sub-Agents**: Primary Agent acts as Orchestrator, dispatches independent issues to isolated subagents via `invoke_subagent`, enforces prompt language discipline (English), and immediately terminates completed subagents (`manage_subagents kill`).
