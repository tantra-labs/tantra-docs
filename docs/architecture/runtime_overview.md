# `tantra-runtime` Overview — the Central House

> **[STATUS: IMPLEMENTED]** — the `tantra-runtime` repo (14 crates). See [Platform Conformance Matrix](../conformance_matrix.md).

`tantra-runtime` (bounded context: **Central Application & Orchestration Runtime**, Tier 3B "House") is the repo that wires the pure domain heart (`tantra-ledger`), the pre-trade risk gate (`tantra-risk`), market feeds (`tantra-market`), and execution gateways (`tantra-exec`) into four operational surfaces. It is the ported successor of `honba-ya`; every detail on this page is elaborated in the per-crate design docs of that repo (`docs/design/code-*.md`).

## 1. Four operational surfaces

1. **Supervised Tokio actor pipeline** (`tantra-runtime-actors`) — the live/paper event loop: `MarketDataActor → StrategyActor → (PositionSizingActor) → RiskActor → ExecutionActor`, plus a standalone `PortfolioActor` and a Python-isolated `PythonStrategyActor`. See [Actor Runtime & Event Loop](event_loop.md).
2. **Deterministic backtester + enhancer** (`tantra-runtime-backtest`, `tantra-runtime-enhancer`) — the research engine with exact parity to live: L2 fills, latency/slippage, statutory costs, MIS square-off, then GA/TPE/WFO/DSR optimization. See [Strategy Tester & Enhancer](strategy_tester_and_enhancer.md).
3. **Headless REST/WS gateway** (`tantra-runtime-api`, `tantra-runtime-api-rest`) — the `tantra serve` control plane: `/api/v1` + `/api/v2` routes, run journals + SSE, order gate + approval queue, profile/portfolio stores, and the chat agent WebSocket. See [REST API](../api/rest.md) and [Runtime chat agent](runtime_chat.md).
4. **Job scheduler + persistence** (`tantra-runtime-jobs`, `tantra-runtime-persistence`) — cron/background jobs with budgets and fencing, and the SQLite/PostgreSQL stores + SEBI audit ledger. See [Runtime Job Scheduler](runtime_jobs.md).

All four surfaces speak the same wire contract (`schema_version`, `api_version`) and the same domain types from `tantra-core`.

## 2. The 14 crates

| Sub-Crate | Layer | Responsibility |
| :--- | :--- | :--- |
| `tantra-runtime-config` | Config | Self-describing run-config schema (`BacktestRunConfig`), `deny_unknown_fields` everywhere, `[risk]` section (ADR 0018), `ResolvedUniverse` bridge |
| `tantra-runtime-strategy` | Pure Domain | `Strategy` trait + `StrategyContext`, `OrderIntent`, `StrategyRunner`, manifests/IR, multi-broker `dispatch` |
| `tantra-runtime-backtest` | Sim Engine | Event-driven backtester driving the *real* `StrategyRunner`: Parquet catalog loader, NSE calendar, L2 fills, latency/slippage, T+1 ICCL settlement, MIS 15:20 square-off, exact statutory costs |
| `tantra-runtime-enhancer` | Optimizer | Automatic Strategy Enhancer: GA, Bayesian TPE, walk-forward (WFE ≥ 0.60), DSR/PBO guardrails, Monte Carlo stress, Odysseus rule-tree backend |
| `tantra-runtime-actors` | Actor System | Supervised Tokio actors, Prometheus metrics, W3C trace-context spans, formal SLO verify functions (15 µs risk gate) |
| `tantra-runtime-jobs` | Scheduler | `JobSpec`/`CronSchedule` (5-field Vixie), `FileJobRegistry`, `JobBudgets`, `FencingLease`, `BoundedWorkerPool` (429 backpressure) |
| `tantra-runtime-persistence` | Storage Infra | `sqlx` SQLite/PostgreSQL stores (orders, fills, FIFO lots, decisions, chat sessions), embedded migrations, append-only `SqliteAuditLedger` |
| `tantra-runtime-testing` | Test Harness | Deterministic `MockBrokerExecutor`, `MockMarketFeed`, `simulated_fill`, fixed-epoch fixtures |
| `tantra-runtime-api` | API Contracts | Zero-HTTP contract crate: `ResponseEnvelope` + 16 `ErrorCode`s, 44-endpoint registry, `RunId` (Crockford), run manifests, screener AST |
| `tantra-runtime-api-rest` | HTTP/WS Server | Axum server: v1/v2 routing, run executor, SSE, order gate + approval queue, OpenAPI 3.1, auth, chat WebSocket |
| `tantra-runtime-feed` | Feed Shim | Re-export shim over `tantra-market-store` (Parquet tick store, Lakehouse, live quote store) |
| `tantra-runtime-market` | Placeholder | Stub crate (real market-data code lives in `tantra-market`) |
| `tantra-indicators` | Placeholder | Stub crate (real indicators live in `tantra-market-indicators`) |
| `tantra-runtime-test-utils` | Placeholder | Stub crate, superseded by `tantra-runtime-testing` |

## 3. Event pipeline (backtest = live)

```text
  Arrow/Parquet ────┤ CatalogLoader ─▶ MarketEvent stream ─▶ StrategyRunner ─┐
  (backtest)        │                                                        │
                    │            OrderRequest → L2/latency/slippage          │
                    │            → FillReport → TaxCalculator                │
                    │            → double-entry Transaction                  │
                    │            → T+1 settlement / MIS square-off           │
                    │                                                        │
  live ticks ───────┤ MarketDataActor → StrategyActor → (PositionSizingActor)│
  (live/paper)      │                        │                               │
                    │                        ▼                               │
                    │                 RiskActor (check_order)                │
                    │                        ▼                               │
                    │                 ExecutionActor → BrokerExecutor        │
                    │                        ▼                               │
                    │                 PortfolioActor / SqliteAuditLedger     │
```

Backtest and live share the **same** strategy trait, runner, risk engine, ledger crates, and statutory cost calculators — parity is achieved by delegation, not reimplementation.

## 4. Cross-cutting invariants

| Invariant | Where enforced |
| :--- | :--- |
| Zero floats in financial accounting | `rust_decimal::Decimal` in strategy context, backtest engine, ledger postings, persistence columns; float seams are confined to optimizer fitness (f64 by design), config-boundary fields, and documented wire conversions |
| No wall clock in domain state machines | Every transition takes an explicit `DateTime<Utc>`; clock uses are audit rows/metrics/logging only |
| Zero-I/O domain logic | `tantra-runtime-strategy` is I/O-free; actors receive injected ports (`Arc<dyn BrokerExecutor>`, audit ledger) |
| Deterministic replay | `Uuid::new_v5` client order ids, `"{client_order_id}-{seq}"` fill ids, monotonic Crockford run ids; byte-identical journals tested at 1/4/16 workers |
| Tests in `tests/` only | Zero `#[cfg(test)]` in `crates/*/src/` |
| Canonical `prod` profile | `make prod` / `cargo test --workspace --profile prod` |
| Wire strictness | `deny_unknown_fields` on configs/manifests/envelopes; monetary values as strings (documented exception: order-wire JSON numbers) |

## 5. Where to go next

| Interest | Read |
| :--- | :--- |
| Run a backtest | [First Backtest](../getting-started/first-backtest.md), [Using the Simulator](simulator_usage.md) |
| Write strategies | [Writing Strategies](../strategies/writing_strategies.md), manifests/IR in the `code-strategy.md` design doc |
| Optimize & de-overfit | [Strategy Tester & Enhancer](strategy_tester_and_enhancer.md), [Statistical Validation](../backtesting/statistical_validation.md) |
| Serve the API | [REST API](../api/rest.md), [Runtime chat agent](runtime_chat.md) |
| Schedule jobs | [Runtime Job Scheduler](runtime_jobs.md) |
| Source-level detail | `tantra-runtime/docs/design/code-*.md` per-crate design docs |
