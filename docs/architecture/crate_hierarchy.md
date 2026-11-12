# Crate Hierarchy

The workspace contains twelve Rust crates with strict dependency rules. The
layout mirrors StockSharp's separation of messages, entities, algorithms,
and strategies, adapted to Rust's crate system.

## The Twelve Crates

    tantra-marketssages              [Layer 1, foundation]
      │
      ├── tantra-core        [Layer 1, domain]
      │     │
      │     ├── tantra-strategies      [Layer 1, engine]
      │     │     │
      │     │     ├── tantra-strategies
      │     │     │     │
      │     │     │     └── tantra-strategies
      │     │     │
      │     │     └── (used by testing)
      │     │
      │     ├── tantra-strategies
      │     ├── tantra-strategies
      │     ├── tantra-data
      │     ├── tantra-data
      │     │
      │     └── tantra-market

## Allowed Dependencies

This table is machine-enforced. Any dependency not listed here fails CI.

| Crate | May depend on |
|---|---|
| `tantra-marketssages` | *(nothing)* |
| `tantra-core` | `tantra-marketssages` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-strategies` | `tantra-strategies` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-strategies` | `tantra-strategies`, `tantra-strategies` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-data` | `tantra-marketssages`, `tantra-core` |
| `tantra-data` | `tantra-marketssages`, `tantra-core` |
| `tantra-market` | `tantra-core` |

Note that `tantra-market` depends **only** on `tantra-core`. It does not
depend on `tantra-strategies`, which means the market module can be tested
in complete isolation from the engine. This is deliberate: NSE calendar
logic should have zero coupling to event dispatch.

## The Foundation Crates

### `tantra-marketssages`

Defines the vocabulary of the engine. Every message that flows through the
system is defined here.

    src/
    ├── market_data/
    │   ├── tick.rs         — Tick, QuoteTick, TradeTick
    │   ├── bar.rs          — Bar, BarType, BarSpecification
    │   ├── order_book.rs   — OrderBookDelta, OrderBookDeltas
    │   ├── quote.rs        — QuoteTick
    │   └── custom.rs       — user-defined data
    ├── orders/
    │   ├── order.rs        — Order, OrderSide, OrderType
    │   ├── fill.rs         — OrderFilled
    │   ├── cancel.rs       — OrderCanceled
    │   └── status.rs       — OrderStatusReport
    ├── subscriptions/
    ├── events/
    └── serialization/      — Arrow schemas, Parquet encoding

**Rule:** `tantra-marketssages` has no business logic. It defines types and their
serde/Arrow representations. Nothing else.

### `tantra-core`

Trading domain models. `Instrument`, `Position`, `Portfolio`, `Order`,
`Trade`. These are entities with identity — you can look them up by ID.

    src/
    ├── instrument/
    │   ├── instrument.rs   — Instrument, InstrumentId
    │   ├── equity.rs       — Equity, EquitySpec
    │   ├── index.rs        — Index, IndexSpec
    │   ├── etf.rs
    │   ├── mutual_fund.rs
    │   ├── option.rs
    │   └── future.rs
    ├── portfolio/
    ├── order/
    ├── trade/
    └── identifiers/        — Symbol, ISIN, Exchange (Nse, Bse)

**Rule:** `tantra-core` never imports from `tantra-strategies`. An `Instrument`
does not know how to be traded; it only knows what it is.

## The Engine Crate

### `tantra-strategies`

The event kernel, connector traits, subscription manager, cache, and risk
engine. This is where the determinism guarantee lives.

    src/
    ├── engine/
    │   ├── kernel.rs       — event loop
    │   ├── clock.rs        — Clock abstraction (live vs sim)
    │   ├── dispatcher.rs   — event routing
    │   └── lifecycle.rs
    ├── connector/
    │   ├── data_client.rs       — DataClient trait
    │   ├── execution_client.rs  — ExecutionClient trait
    │   ├── instrument_provider.rs
    │   └── message_adapter.rs   — AsyncMessageAdapter base
    ├── subscription/
    ├── cache/
    │   ├── cache.rs
    │   └── context.rs      — context-aware caching
    ├── data/
    │   └── catalog.rs      — Parquet catalog wrapper
    └── risk/
        └── position_merger.rs

**Rule:** `tantra-strategies` defines the interfaces that adapters implement. It
never mentions a specific broker.

## The Market Module

### `tantra-market`

Market contracts, market packs, calendars, settlement, and costs.

    src/
    ├── calendar.rs         — Trading calendar abstractions
    ├── costs.rs            — Cost calculation models
    ├── universes.rs        — Universe definitions & rebalance logic
    ├── rules.rs            — Exchange trading rules
    └── india/              — India-specific implementations (NSE/BSE, STT, etc.)

This is the crate where market-specific contracts and logic live, and it
is intentionally isolated. A test of the NSE calendar does not spin up an
engine; it calls `is_trading_day(date)`.

## The Strategy Stack

### `tantra-strategies`

The `Strategy` trait and the machinery around it — position management,
P&L calculation, order generation.

### `tantra-strategies`

Pure functions over bar streams. Each indicator is independent and testable
without the engine.

### `tantra-strategies`

The three-tier backtesting pipeline, latency models, cost models, and
concurrent runners.

### `tantra-strategies`

Monte Carlo, walk-forward, cointegration, regime detection, tearsheets.
These operate on backtest results, not on the engine.

## Why This Hierarchy

Every dependency edge was chosen to answer one question: **if this crate
changed, what else would have to change?**

- `tantra-marketssages` changes only when the vocabulary of the engine changes.
  This is rare.
- `tantra-core` changes when the domain model changes. Less rare.
- `tantra-market` changes whenever market rules change. This happens often,
  and the isolation means it does not ripple into the engine.
- `tantra-strategies` changes when the event model changes. Very rare.
- The strategy and testing crates change constantly during research.

The hierarchy means that the crates that change most often are at the
leaves, and the crates that change least often are at the root. This is
the opposite of typical trading platforms, where adding a new broker
requires a change to the core.

## Enforcing the Hierarchy

`scripts/dependency_graph.py` reads every crate's `Cargo.toml`, extracts
the `tantra-*` dependencies, and verifies they match the allowed table.
It runs in CI on every pull request.

To check locally:

    python3 scripts/dependency_graph.py
    # → Dependency hierarchy OK.

If you need a dependency that violates the table, the correct response is
usually to move the code that needs it into a lower crate, not to add the
edge. If that's not possible, discuss it in an issue before opening a PR.
