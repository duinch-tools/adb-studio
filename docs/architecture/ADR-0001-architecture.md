# ADR-0001: Project Base Architecture, Security Gates & Multi-Agent Standards

- **Date**: 2026-11-08 | **Status**: Accepted | **Project**: adb-studio | **Stack**: iOS / Swift (SwiftUI + Swift 6 Concurrency)

## Decision
- **Architecture Style**: `clean` | **Flow Pattern**: `mvvm-udf`
- **Reference Architecture Anchor**: [`nalexn/clean-architecture-swiftui`](https://github.com/nalexn/clean-architecture-swiftui)
- **Boundary Enforcement**: Local Swift Package Manager (Package.swift target dependencies) + SwiftLint
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
