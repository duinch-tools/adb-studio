# Presentation Layer Guardrails (`mvi`)

1. Keep UI frameworks and platform APIs outside domain modules.
2. Choose state/message/update patterns that fit the UI framework; use enums and exhaustive matching where they clarify valid states. Do not force a sealed UI-state abstraction onto simple applications.
3. Keep platform-specific code behind target configuration or adapter boundaries, and verify each declared target in CI.
