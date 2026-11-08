# Data & Infrastructure Layer Guardrails

1. Keep network, persistence, platform SDK, and serialization dependencies in adapters or infrastructure modules.
2. Use DTO/entity types only when they represent a real wire/database boundary; map at that boundary and keep domain types independent.
3. Translate I/O failures into meaningful errors at adapter boundaries. Preserve error sources and propagate cancellation rather than swallowing it.
