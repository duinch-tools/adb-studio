# adb-studio — AI Agent Engineering & Security Contract

> Managed by `project-pro` (`.agents/project-profile.json`). Every coding task MUST follow the 6-Gate Execution Harness.

## 1. Architectural Profile
- **Stack**: Rust (Cargo Workspace / Cross-Platform GUI & Core)
- **Architecture**: `clean` | **Flow / State Pattern**: `mvi`
- **Gold-Standard Reference Repo**: [`emilk/egui`](https://github.com/emilk/egui) — **consult & adapt patterns from this repo instead of inventing custom structures.**
- **Enabled Capabilities**: `solid-dry`, `typed-errors`, `di-core`, `network-storage`, `ui-nav`, `arch-lint`, `testing-ci`

## 2. Canonical Commands
- **Build**: `cargo build --workspace`
- **Run All Tests**: `cargo test --workspace`
- **Run Single Test**: `cargo test -p <crate> -- <test_name>`
- **Lint & Typecheck**: `cargo fmt --all -- --check && cargo clippy --workspace --all-targets -- -D warnings`
- **Security Audit**: `cargo audit`

## 3. Layer & Module Dependency Rules
- **Dependency Rule**: Keep domain crates/modules independent from UI, transport, database, and runtime frameworks.
- **Rust Modeling**: Prefer ownership-based APIs, enums/newtypes, traits at real boundaries, and `Result<T, E>`; do not impose DTO/Entity or sealed UI-state patterns by default.
- **Platform Contract**: Build/test Linux, macOS, and Windows in CI; add Android, iOS, WebAssembly, or embedded targets only when declared and provisioned with their SDK/linker.
- **Boundary Enforcement**: Cargo Workspace crate isolation (pure domain crate, framework adapters, app entrypoint) + cargo-deny when dependency policy requires it

## 4. Mandatory 6-Gate Execution & Behavioral Guardrails
1. **Think & Ground (`karpathy-skills`)**: Read `.agents/CODEBASE_MAP.md`, `.agents/memory/lessons.md`, and `referenceRepo` before coding. Surface hidden assumptions; push back on unsafe anti-patterns; write `.agents/memory/active-plan.md` for > 3-file tasks.
2. **Surgical & Bounded Files**: Touch ONLY lines/files required. **1 File = 1 Primary Responsibility** (`> 300 LOC` = WARN, `> 450 LOC` = FAIL).
3. **Disciplined Coding (`obra/superpowers`)**: Build from domain types and behavior outward; use Rust-native adapters and UI state only where the project needs them. For bugs, trace **Root Cause** + **3-Strike Stop** (if 3 fixes fail, STOP & re-evaluate architecture). Zero unfinished stubs, zero dead code.
4. **SOLID & Anti-False-DRY**: Use ownership, borrowing, enums, and traits to model invariants; introduce wire/database models only at real boundaries. Keep state types as simple as the UI requires. Guard clauses (`<= 3` indent levels), immutable by default.
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
