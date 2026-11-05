# `vyapaar-docs` — Documentation Roadmap

## Milestone 1: Architecture, DDD Bounded Contexts & Migration Guides (P0)
- [x] Port `docs/architecture/`, `docs/backtesting/`, `docs/ai/`, `docs/tutorials/`, and `docs/reference/` from `honba-docs/docs/` into `vyapaar-docs`.
- [x] Consolidate unique mdBook pages (`crate_hierarchy.md`, `message_flow.md`, `avoiding_backtest_biases.md`, `nl_verification.md`, `contributing/`) into unified `docs/` structure.
- [x] Update all subsystem names, crate references, and diagrams to `vyapaar-*`.

## Milestone 2: Strict Build Gate (`mkdocs build --strict`) (P0)
- [x] Update `mkdocs.yml` navigation tree with 100% doc coverage (74 pages).
- [x] Fix all relative link anomalies between `conformance_matrix.md` and module subdirectories.
- [x] Verify zero warnings and clean exit under `mkdocs build --strict`.
