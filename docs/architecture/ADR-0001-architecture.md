# ADR-0001: Project Base Architecture, Security Gates & Multi-Agent Standards

- **Date**: 2026-11-08 | **Status**: Accepted | **Project**: adb-studio | **Stack**: Rust (Cargo Workspace / Cross-Platform GUI & Core)

## Decision
- **Architecture Style**: `clean` | **Flow Pattern**: `mvi`
- **Reference Architecture Anchor**: [`emilk/egui`](https://github.com/emilk/egui)
- **Boundary Enforcement**: Cargo Workspace crate isolation (pure domain crate, framework adapters, app entrypoint) + cargo-deny when dependency policy requires it
- **File Size Policy**: `1 File = 1 Primary Responsibility`, warn at `300 LOC`, hard block at `450 LOC`.
- **Security & Git Gates**: Staged secret scanning, OWASP heuristics, Conventional Commits, and pre-push test/CVE verification via `.githooks/`.

### Selected Base Capabilities
- `solid-dry`
- `typed-errors`
- `di-core`
- `network-storage`
- `ui-nav`
- `arch-lint`
- `testing-ci`
