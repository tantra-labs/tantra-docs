# Architectural Layers & Bounded Context Topology

> **[STATUS: IMPLEMENTED]** — All 15 repositories mapped. See [Platform Conformance Matrix](../conformance_matrix.md).
>
> This page documents the **new DDD design**: Tantra's 15 strictly bounded repositories organized across 6 architectural layers. It is the authoritative topological reference for the platform's dependency direction and I/O policy.

---

## 1. Six-Layer Architecture

Tantra partitions the algorithmic trading and quantitative research domain into **15 strictly bounded repositories** organized across 6 architectural layers. Dependencies flow strictly downward: a layer may depend only on layers below it, never on layers above or at the same level (except peer collaboration within a layer).

| Layer | Bounded Context Repo | Core Responsibility | I/O Policy |
| :---: | :--- | :--- | :--- |
| **L0** | `tantra-core` | **Shared Kernel**: Canonical `Decimal` Value Objects (`Price`, `Quantity`, `Money`), Strongly-Typed IDs (`InstrumentId`, `ClientOrderId`, `AlgoId`, `AccountId`), Wire DTOs, `Decision` grammar, `DomainEvent`s, and Port traits. | **Zero-I/O** |
| **L1** | `tantra-risk` | **Regulatory Risk Gate**: Sub-15 µs synchronous pre-trade gate (SEBI Algo ID registry, OTR circuit breakers, scrip price bands, freeze limits, emergency kill-switch). | **Zero-I/O** |
| **L1** | `tantra-ledger` | **Domain Heart**: Order Management System (`oms`), FIFO tax-lot & T+1 Demat settlement accounting (`portfolio`), Double-Entry General Ledger (`journal`), and pure Repository traits. | **Zero-I/O** |
| **L1** | `tantra-ledger-allocation` | Portfolio allocation & optimization: mean-variance and risk-parity target weights, weight-bounds constraints, `PortfolioState` read-adapter, pure deterministic `optimize()` (Phase 1: `MeanVariance` / `RiskParity`; Phases 2–4: Hrp/Herc, Black-Litterman, discrete allocation planned). | **Zero-I/O** |
| **L1** | `tantra-ledger-performance` | Trade-performance journal: trade annotations (tags/rating/review/planned risk), `JournalStore`, performance metrics engine + edge score composite (v1), daily P&L calendar, account-vs-account comparison. | **Zero-I/O** |
| **L2** | `tantra-market` | **Market Eye**: Market microstructure rules (`finance`), incremental indicators (`indicators`), alpha signals (`signals`), symbol normalizer (`normalizer`), live feeds (`feed`), Parquet lakehouse (`store`), and broker WebSocket ACLs. | Compute: **Zero-I/O**<br>Adapters/Store: Async I/O |
| **L2** | `tantra-exec` | **Execution Hand**: Token-bucket rate limiter (`core`), headless TOTP/eDIS auth (`auth`), freeze slicer (`slicer`), Smart Order Router (`router`), tamper-evident SQLite WAL journal (`audit`), and broker REST ACLs. | Async I/O |
| **L3** | `tantra-agent` | **AI Agent**: Closed-grammar LLM providers (`llm`), prompt templates (`prompt`), SHA-256 deterministic replay (`replay`), trader loop (`trader-loop`), genetic synthesizer (`genetic`), MCP server (`mcp`), tools, plugins, and Typst reports (`report`). | Async I/O + Pure Core |
| **L3** | `tantra-runtime` | **Central House**: Supervised Tokio actor pipeline (`actors`), event-driven backtester (`backtest`), strategy runner (`strategy`), GA/WFO enhancer (`enhancer`), SQLite/Postgres repositories (`persistence`), cron jobs (`jobs`), and Axum OpenAPI 3.1 server (`api-rest`). | Async I/O |
| **L3** | `tantra-runtime-jobs` | Deterministic cron/background job scheduler (`JobScheduler`, `JobSpec`, `CronSchedule`), bounded worker pool, fencing leases, approval queue, per-run journal (`manifest.json`, `events.ndjson`, `trades.json`, `metrics.json`). | Async I/O |
| **L4** | `tantra-ffi` | **Python FFI Bridge**: Schema codegen (`codegen`) and PyO3 + Apache Arrow PyCapsule zero-copy extension (`py`) compiling the `tantra` wheel. | FFI Bridge |
| **L5** | `tantra-ui` | **Unified Workstations**: Leptos 0.8 WASM Strategy Studio & Screener (`ui-app`), HTML5 canvas charts (`ui-charts`), Ratatui TUI (`tui`), and native CLI (`cli`). | WASM / TUI |
| **L6** | `tantra-data` | **Financial Lakehouse**: DuckDB point-in-time fundamentals, corporate actions, and Parquet catalog management. | Python + DuckDB |
| **L6** | `tantra-adapters` | **Community Broker SDK**: Pluggable Python broker adapters (Dhan, Zerodha, Upstox, Angel One, Fyers, Kotak, IIFL). | Python I/O |
| **L6** | `tantra-strategies`| **Strategy Catalog**: Production Python strategies & declarative `step.toml` catalog chains. | Python Pure |
| **L6** | `tantra-examples` | **Learning Path**: Deterministic runnable tutorials for Indian equities, F&O, WFO/DSR, and AI research. | Python |
| **L6** | `tantra-docs` | **Documentation**: MkDocs Material technical reference and conformance matrix. | Static Docs |

---

## 2. Dependency Direction

```
L0  tantra-core  (Shared Kernel — zero dependencies)
    ├─► L1  tantra-risk     (Zero-I/O)
    ├─► L1  tantra-ledger   (Zero-I/O)
    ├─► L2  tantra-market   (Compute: Zero-I/O; Adapters/Store: Async)
    ├─► L2  tantra-exec     (Async I/O)
    │       └─► tantra-risk (pre-trade gate before broker order)
    ├─► L3  tantra-agent    (Async I/O + Pure Core; depends on core & risk only)
    ├─► L3  tantra-runtime  (Async I/O; depends on core only; no upward dep on agent)
    │       └─► L4  tantra-ffi (FFI bridge)
    ├─► L5  tantra-ui       (WASM / TUI; depends on lower layers through read ports)
    └─► L6  tantra-ffi      (Python bridge → Python ecosystem L6)
            ├─► L6  tantra-data
            ├─► L6  tantra-adapters
            ├─► L6  tantra-strategies
            ├─► L6  tantra-examples
            └─► L6  tantra-docs
```

**Key invariant**: `tantra-runtime` depends on `tantra-core` only — it must **never** depend on `tantra-agent`. The agent-to-runtime dependency cycle from the legacy `honba` workspace was broken in the new design.

---

## 3. Tactical DDD Invariants

These invariants apply across all layers and are enforced in CI:

1. **Zero-I/O Domain Purity** — `tantra-core`, `tantra-risk`, `tantra-ledger`, `tantra-market-{indicators,signals,normalizer,finance}`, and `tantra-runtime-strategy` must never perform network, disk, database, or wall-clock (`Utc::now()`, `Instant::now()`) calls. All state transitions receive an explicit `DateTime<Utc>`.

2. **Strict Zero-Floats Policy** — `f32`/`f64` (Rust) and `float` (Python) are banned for prices, quantities, cash balances, fees, taxes, and margins. All monetary/quantity values use `rust_decimal::Decimal` / `decimal.Decimal` wrapped in `Price`, `Quantity`, and `Money`.

3. **Self-Validating Immutable Value Objects** — Value objects validate invariants at construction and deserialization boundaries (e.g., non-negative `Price`, non-negative `Quantity`, valid `InstrumentId`, non-empty SEBI `AlgoId`).

4. **Rich Domain Aggregates** — State mutations happen exclusively through Aggregate Root domain methods (`order_book.apply_fill(...)`, `portfolio.apply_fill(...)`, `ledger.post(...)`, `risk_engine.check_order(...)`) that enforce invariants and emit immutable `DomainEvent`s.

5. **Anti-Corruption Layers (ACL)** — Broker-specific wire formats (Zerodha binary packets, Upstox Protobuf, Angel One SmartAPI JSON) are strictly confined to adapter crates and immediately translated into `tantra-core` canonical models.

6. **Parallel Test Directory Rule** — All tests reside in `<crate>/tests/` parallel to `<crate>/src/`. Inline `#[cfg(test)]` blocks inside `src/` are strictly forbidden.

---

## 4. Layer Responsibilities at a Glance

| Layer | Name | Concern | Example Crates |
| :---: | :--- | :--- | :--- |
| L0 | Shared Kernel | Canonical types, wire contracts, port traits | `tantra-core` |
| L1 | Domain Guards | Zero-I/O purity: risk gate, ledger heart | `tantra-risk`, `tantra-ledger` |
| L2 | Market & Execution | Async I/O: feeds, lakehouse, broker adapters, SOR | `tantra-market`, `tantra-exec` |
| L3 | Intelligence | Actors, backtest, AI agent, REST gateway | `tantra-runtime`, `tantra-agent` |
| L4 | Bridge | PyO3 + Arrow zero-copy, schema codegen | `tantra-ffi` |
| L5 | Workstations | WASM studio, TUI, CLI | `tantra-ui` |
| L6 | Python Ecosystem | Data lakehouse, broker adapters, strategies, examples, docs | `tantra-data`, `tantra-adapters`, `tantra-strategies`, `tantra-examples`, `tantra-docs` |

---

## 5. Related Documents

* **[Domain-Driven Design (DDD)](domain_driven_design.md)** — Deep dive into bounded contexts, aggregates, value objects, domain events, and state invariants.
* **[DDD Conflicts & Resolutions](ddd_conflicts_resolutions.md)** — Bounded-context conflicts identified during the `honba` → `tantra` migration and their resolutions.
* **[Python-First Architecture](python_first.md)** — Python strategy authoring ergonomics, PyO3 zero-copy FFI bridge, and GIL-free asynchronous execution.
* **[Actor Runtime & Event Loop](event_loop.md)** — Multi-threaded actor architecture, Tokio pipelines, lock-free channels, and supervision trees.
* **[Platform Conformance Matrix](../conformance_matrix.md)** — Per-repo implementation status badge (`IMPLEMENTED` / `IN-PROGRESS` / `SCAFFOLD` / `PLANNED`).
