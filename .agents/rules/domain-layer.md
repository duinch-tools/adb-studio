# Domain Layer Guardrails (`clean`)

1. **Zero Framework Leakage**: Domain modules must not depend on UI/runtime crates such as `eframe::`, `egui::`, `sdl2::`, `winit::`, `iced::`, `tauri::`.
2. **Rust Types**: Prefer value types, enums, and explicit `Result<T, E>`; keep repository/port traits narrow and consumer-owned. Introduce separate wire/database models only where serialization or persistence boundaries require them.
3. **Ownership & Safety**: Keep ownership simple and avoid unnecessary shared mutability. Do not use `unsafe` in domain code; if unavoidable, isolate it and document its safety invariants.
4. **Pure Tests**: Keep domain tests independent from UI, network, database, and platform SDKs.
