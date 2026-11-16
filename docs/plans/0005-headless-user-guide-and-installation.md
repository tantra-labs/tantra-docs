# 0005 — Headless User Guide & Installation Guide

**Status**: Implemented 2026-11-16.
**Track**: Documentation (pre-UI user enablement).
**Owning repo**: `tantra-docs`.

## Why

The web workstations (`tantra-ui` WASM Studio, `tantra-fe` React terminal) are
not yet the stable daily driver. Everything a user needs to run strategies,
backtest, paper trade, screen, serve data, and drive the AI agent today lives on
four headless surfaces: the `tantra` CLI, the REST/WebSocket API, the Python
SDK wheel, and the MCP/AI gateway. The getting-started pages described a
monolithic single-repo checkout, a `cargo build` (target/debug) flow, and a
`Strategy.backtest(...)` / `result.print_report()` API that no longer exist —
so a newcomer could not get from clone to a running backtest without guessing.

## Deliverables

- `docs/getting-started/installation.md` — rewritten against the actual
  superproject: `git clone --recurse-submodules`, single workspace venv
  (`make prepare`), canonical `prod` profile build (`make prod`), where the
  `tantra` binary and the wheel land, adapter install, config, verification,
  and current common-issue fixes.
- `docs/user-guide/` — a pre-UI daily-driver manual:
  - `index.md` — orientation: the four headless surfaces, when to use which,
    honest web-UI status banner.
  - `cli.md` — the `tantra` command reference organized by job to do.
  - `rest-api.md` — `tantra serve` + curl workflows (full wire reference
    remains `api/rest.md`).
  - `python.md` — Python SDK: strategy authoring, `Tantra.backtest`, wheel
    CLI, data sources.
  - `ai.md` — LLM backends, `tantra ask/chat`, `tantra tools`, `tantra mcp
    config`, autonomous `tantra jobs`.
  - Paper trading is **not duplicated here**: it has its own guide at
    `docs/paper-trading/` (plan 0004, implemented 2026-11-16); the user
    guide cross-links it from every relevant surface page.
- `docs/getting-started/first-backtest.md` + `loading-data.md` — corrected to
  the shipped APIs (`Tantra.backtest(...).run()`, synthetic/lakehouse/parquet
  data paths); no references to deleted `tantra data load` or
  `Strategy.backtest`.
- Nav + index wiring; `mkdocs build --strict` gate.

## Verification

```bash
mkdocs build --strict
```

## Notes

- Cross-links keep the existing `../` relative style.
- Code snippets are grounded in shipped, tested surfaces: `tantra-examples`
  `examples/backtesting/01_first_backtest.py` and
  `examples/basic/06_paper_trading.py`, `tantra-ffi`
  `python/tests/test_paper_session.py`, and the `tantra-ui` `tantra-cli`
  `args.rs` command set.
