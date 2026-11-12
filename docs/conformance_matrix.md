# Platform Conformance Matrix

> **Single source of truth** mapping every Tantra crate/module to its documented
> capability and implementation status. This is the authoritative reference for
> closing the documentation↔implementation lag (Gap 7). Status badges on each
> architecture page mirror this matrix.

## Status taxonomy

| Badge | Meaning |
|:------|:--------|
| `[STATUS: IMPLEMENTED]` | Code is compiled, unit-tested, and passing CI conformance. |
| `[STATUS: IN-PROGRESS]` | Core contracts and basic engines active; edge features under development. |
| `[STATUS: SCAFFOLD]` | Uniform API skeleton and interfaces defined; execution logic stubbed. |
| `[STATUS: PLANNED]` | Architectural blueprint formulated; implementation not yet started. |

## Matrix

| Crate / module | Documented capability | Status | Doc reference | Test coverage |
|:---------------|:----------------------|:-------|:--------------|:--------------|
| `tantra-core` | Value objects (`Price`, `Quantity`, `Money`), `InstrumentId`, `Decision`, `Order`, `Portfolio`, `Signal`, `Sizing`, `Market`, `Calendar`, `Events`, `Wire`, `Types`, quant transform primitives (`simple_returns`, `realized_volatility`, `ewma_volatility`, `rolling_mean`, `rolling_stdev`, `sharpe_ratio`, `max_drawdown`, `correlation`, `beta`, `historical_var`, `historical_cvar`, `tracking_error`), statistical validation gates (`ValidationBlock`: DSR, PBO, walk-forward, holdout, Monte Carlo, cost-stress) | `[STATUS: IMPLEMENTED]` | [DDD](architecture/domain_driven_design.md), [Money](architecture/money.md), [Contracts](architecture/contracts_from_rust.md), [Analytics Gates](architecture/domain_driven_design.md), [Quant Primitives](architecture/domain_driven_design.md) | `tests/core_tests.rs`, `tests/proptest_invariants.rs`, `tests/golden_test.rs`, `tests/schema_compatibility_test.rs`, `tests/quant_tests.rs`, `tests/quant_proptest.rs`, `tests/analytics_gates_tests.rs` |
| `tantra-ledger` | Double-entry FIFO ledger, OMS state machine, tax-lot matching, portfolio accounting, repository traits | `[STATUS: IMPLEMENTED]` | [Money](architecture/money.md), [Order Reject & Cancel](architecture/order_reject_cancel.md), [Tradebook](architecture/tradebook.md), [Architecture Layers](architecture/architecture_layers.md) | `crates/tantra-ledger-book/tests/ledger_proptest_invariants.rs`, `crates/tantra-ledger-portfolio/tests/apply_fill_tests.rs`, `crates/tantra-ledger/tests/repository_and_sizing_tests.rs`, `crates/tantra-ledger-oms/tests/*`, `crates/tantra-ledger-journal/tests/*` |
| `tantra-ledger-allocation` | Portfolio allocation & optimization: mean-variance, risk-parity target weights, weight-bounds constraints, `PortfolioState` read-adapter over `tantra-ledger-portfolio`, pure deterministic `optimize()` | `[STATUS: IMPLEMENTED]` | [Ledger Allocation](architecture/ledger_allocation.md) | `tests/optimize_tests.rs` |
| `tantra-ledger-performance` | Trade-performance journal: annotations (tags/rating/review/planned risk), `JournalStore`, performance metrics engine + edge score composite (v1), daily P&L calendar, account-vs-account comparison | `[STATUS: IMPLEMENTED]` | [Ledger Performance](architecture/ledger_performance.md) | `tests/model_tests.rs`, `tests/store_tests.rs`, `tests/metrics_tests.rs`, `tests/calendar_tests.rs`, `tests/compare_tests.rs` |
| `tantra-risk` | SEBI algo_id registry, OTR circuit breakers, price bands, freeze limits, pre-trade risk gate | `[STATUS: IMPLEMENTED]` | [Order Reject & Cancel](architecture/order_reject_cancel.md), [Risk Migration Plan](architecture/migration_plan_kokoro_risk_to_mon.md) | `tests/proptest_tests.rs`, `tests/risk_tests.rs`, `tests/phase7_tests.rs` |
| `tantra-market` | Multi-broker binary WebSocket feeds, tick coalescing, L2/L3 depth, 100+ StockSharp indicators, Parquet Lakehouse, Bhavcopy loaders | `[STATUS: IMPLEMENTED]` | [Adapter Interface](architecture/adapter_interface.md), [WASM Indicators](architecture/wasm_indicators.md) | `crates/tantra-market-indicators/tests/*`, `crates/tantra-market-feed/tests/*`, `crates/tantra-market-market/tests/*`, `crates/tantra-market-loaders/tests/*` |
| `tantra-exec` | Token-bucket rate limiter, freeze slicer, headless TOTP auth, Smart Order Router (SOR), SQLite WAL audit journal, broker execution adapters | `[STATUS: IMPLEMENTED]` | [Adapter Interface](architecture/adapter_interface.md), [Order Reject & Cancel](architecture/order_reject_cancel.md) | `crates/tantra-exec-core/tests/*`, `crates/tantra-exec-router/tests/*`, `crates/tantra-exec-slicer/tests/*`, `crates/tantra-exec-audit/tests/*`, `crates/tantra-exec-auth/tests/*` |
| `tantra-runtime` | Tokio actor pipeline, backtest engine, REST API server, persistence, strategy tester/runner, GA/Bayesian/WFO/DSR enhancer, CLI, job scheduler (`tantra-runtime-jobs`), trade-journal + market reference REST endpoints (`tantra-runtime-api-rest`), chat agent runtime (`/ws/chat` with read-only tools + profile alert store; sessions in-memory pending gap 0006) | `[STATUS: IMPLEMENTED]` | [Actor Runtime & Event Loop](architecture/event_loop.md), [Strategy Tester & Enhancer](architecture/strategy_tester_and_enhancer.md), [Runtime Overview](architecture/runtime_overview.md), [Runtime Chat Agent](architecture/runtime_chat.md), [Using the Simulator](architecture/simulator_usage.md), [Job Scheduler](architecture/runtime_jobs.md), [REST API](api/rest.md) | `crates/tantra-runtime-backtest/tests/*`, `crates/tantra-runtime-api-rest/tests/*`, `crates/tantra-runtime-actors/tests/*`, `crates/tantra-runtime-enhancer/tests/*`, `crates/tantra-runtime-persistence/tests/*`, `crates/tantra-runtime-jobs/tests/*`, `crates/tantra-runtime-api-rest/tests/trade_journal.rs`, `crates/tantra-runtime-api-rest/tests/market_reference.rs`, `crates/tantra-runtime-api-rest/tests/chat_*` |
| `tantra-runtime-jobs` | Deterministic cron/background job scheduler (`JobScheduler`, `JobSpec`, `CronSchedule`), bounded worker pool, fencing leases, approval queue, per-run journal (`manifest.json`, `events.ndjson`, `trades.json`, `metrics.json`) | `[STATUS: IMPLEMENTED]` | [Job Scheduler](architecture/runtime_jobs.md), [REST API](api/rest.md) | `crates/tantra-runtime-jobs/tests/*` |
| `tantra-ffi` | PyO3 FFI bridge, zero-copy Arrow/PyCapsule memory, `tantra` Python wheel, GIL management (`py.allow_threads`), codegen | `[STATUS: IMPLEMENTED]` | [Python-First Architecture](architecture/python_first.md), [Contracts from Rust](architecture/contracts_from_rust.md) | `crates/tantra-ffi-py/tests/*`, `crates/tantra-ffi-codegen/tests/*`, `tests/*.py` |
| `tantra-agent` | Autonomous research loop, MCP server, prompt replayer, LLM integration, genetic strategy synthesis, DSR/PBO/walk-forward analytics | `[STATUS: IMPLEMENTED]` | [AI Engine & Quant Researcher](architecture/ai_engine.md) | `crates/tantra-agent-analytics/tests/*`, `crates/tantra-agent-mcp/tests/mcp_tests.rs`, `crates/tantra-agent-agent/tests/*` |
| `tantra-ui` | Leptos CSW frontend, Strategy Studio visual canvas, Simulator port, openalgo-charts bridge, WASM charting | `[STATUS: IMPLEMENTED]` | [tantra-ui Simulator Port](architecture/kao_simulator_port.md), [tantra-ui Strategy Studio](architecture/strategy_studio.md), [WASM Indicators](architecture/wasm_indicators.md) | `crates/openalgo-charts-rs/tests/*`, `crates/tantra-ui-app/tests/*`, `crates/tantra-ui-api-wasm/tests/*` |
| `tantra-strategies` | Production strategy catalog (quoting, arbitrage, TWAP/VWAP slicers, Turtle breakout, risk parity), `step.toml` manifests, `registry.json` | `[STATUS: IMPLEMENTED]` | [Strategies index](strategies/index.md), [Step Manifests & Chaining](strategies/step_manifests_and_chaining.md) | `test_readme_sections.py`, `test_step_manifests.py`, per-strategy `tests/` |
| `tantra-adapters` | Python Broker ACL SDK: single package with 7 broker modules (Dhan, Zerodha, Angel One, Upstox, Fyers, Kotak, IIFL — all implemented, Dhan + Zerodha contract-certified), injected transports (`UrllibTransport`/`MockTransport`), deterministic `PaperBroker` + JSONL record/replay, entry-point registry. REST-only; parity gaps 0001–0007 tracked by plan 0003 | `[STATUS: IN-PROGRESS]` | [Adapters Package](api/adapters-package.md), [Brokers](india/brokers.md), [Adapter Configuration](india/adapter_configuration.md) | `tests/test_dhan.py`, `tests/test_zerodha.py`, `tests/test_registry.py`, `tests/test_paper.py`, `tests/test_replay.py` |
| `tantra-data` | Point-in-time corporate actions, splits, dividends, coverage ledgers, Parquet catalog, DuckDB queries | `[STATUS: IMPLEMENTED]` | [Universes](india/universes.md), [Cost Model](india/cost_model.md) | Python test suite (`pytest`) |
| `tantra-examples` | Runnable Python reference scripts (backtesting, screening, SIP, options, AI research, production) | `[STATUS: IMPLEMENTED]` | [Examples](examples/index.md), [Known Issues](examples/known_issues.md) | `pytest` per numbered script `Pitfalls::` sections |
| `tantra-fe` | TypeScript web desktop UI: dockview workspace, trading terminal, real-time depth, screener, portfolio management | `[STATUS: IMPLEMENTED]` | [tantra-ui Strategy Studio](architecture/strategy_studio.md) | `vitest`, `tsc --noEmit` |
| `tantra-ledger-journal` | Double-entry general ledger for the Indian equity trading lifecycle (`AccountCode`-keyed chart of accounts, `Transaction`/`DoubleEntryLedger`) and the Indian statutory tax calculator (STT, GST, Stamp Duty, SEBI fees, DP charges, exchange turnover fee); pure zero-I/O, temporal determinism | `[STATUS: IMPLEMENTED]` | [Tradebook (Journal & Replay)](architecture/tradebook.md), [Money](architecture/money.md) | `crates/tantra-ledger-journal/tests/unit_tests.rs`, `tax_calculator_tests.rs`, `ledger_proptest_invariants.rs`, `golden.rs` |
| `tantra-runtime-enhancer` | GA, Bayesian optimization, walk-forward analysis, DSR gate (sub-crate of tantra-runtime) | `[STATUS: IMPLEMENTED]` | [Strategy Tester & Enhancer](architecture/strategy_tester_and_enhancer.md) | `crates/tantra-runtime-enhancer/tests/unit_tests.rs` |

## Status summary

| Status | Count | Crates/modules |
|:-------|:------|:---------------|
| IMPLEMENTED | 17 | tantra-core, tantra-ledger, tantra-ledger-allocation, tantra-ledger-journal, tantra-ledger-performance, tantra-risk, tantra-market, tantra-exec, tantra-runtime, tantra-runtime-jobs, tantra-ffi, tantra-agent, tantra-ui, tantra-strategies, tantra-data, tantra-examples, tantra-fe |
| IN-PROGRESS | 1 | tantra-adapters |
| SCAFFOLD | 0 | — |
| PLANNED | 0 | — |

## How this matrix is verified

- Rust crates: `cargo test --workspace` must be green; clippy with `-D warnings`.
- Python packages (`tantra-ffi`, `tantra-strategies`, `tantra-adapters`, `tantra-data`, `tantra-examples`): `pytest -q` must be green.
- `scripts/verify_conformance.py` parses `Cargo.toml`/`pyproject.toml` members and git history to flag crates referenced in docs but absent from the workspace (and vice versa). Run in CI.

## Change log

- 2026-11-12: Runtime documentation pass — added chat-agent runtime + runtime overview rows/links; corrected `tantra-ledger-journal` to IMPLEMENTED (double-entry ledger + statutory tax calculator); corrected enhancer test-coverage reference.
- 2026-10-30: Initial matrix published (M4-1). All statuses verified against crate source and test files in the workspace.
