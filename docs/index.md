# Vyapaar Labs Documentation

**Institutional-Grade, AI-Native Algorithmic Trading & Quantitative Research Platform.**

Vyapaar Labs is an institutional-grade, multi-threaded Rust algorithmic trading operating system and Python research framework purpose-built for Indian equities, derivatives (NSE, BSE, NFO, MCX), index universes (NIFTY 50, BANK NIFTY), mutual funds, and international capital markets. It combines temporal determinism across backtesting and production with a three-tier optimization pipeline and an autonomous quantitative research loop.

---

## Why Vyapaar Labs

Existing open-source trading platforms solve isolated problems, but none provide a cohesive, zero-compromise foundation for Indian markets:

- **Temporal Determinism & Parity** — Unified event model ensures that strategies produce identical fills, order sequencing, and P&L across vectorized pre-filters, event-driven backtesting, paper execution, and live broker feeds.
- **Three-Tier Backtesting Architecture** — Combines microsecond vectorized screening, event-driven tick simulation with realistic latency modeling, and distributed parameter sweeps.
- **Indian Market First-Class Architecture** — Built-in NSE/BSE trading sessions, statutory Indian cost models (STT, GST, stamp duty per Finance Act 2026), point-in-time constituent universes, and weekly/monthly options expiry cycles.
- **AI-Native Quantitative OS** — Closed-grammar decision verification (`Decision`), deterministic prompt replaying, automated walk-forward validation, and native Model Context Protocol (MCP) server integration for AI agents.
- **Domain-Driven Design (DDD)** — Strict separation between zero-I/O domain kernel (`vyapaar-core`), stateful accounting aggregates (`vyapaar-ledger`), pre-trade risk controls (`vyapaar-risk`), and execution gateways (`vyapaar-exec`). Zero floats in financial calculations (`rust_decimal`).

---

## Architectural Topology

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      VYAPAAR UNIFIED ARCHITECTURE                      │
 ├────────────────────────────────────────────────────────────────────────┤
 │  USER & RESEARCH APIS                                                  │
 │  - Python-First Strategy SDK (`vyapaar_strategies`)                    │
 │  - Interactive Leptos CSR Web Studio & Simulator (`vyapaar-ui`)        │
 │  - Native Model Context Protocol (MCP) Server for Frontier AI Agents   │
 ├────────────────────────────────────────────────────────────────────────┤
 │  TIER 4: AI & QUANTITATIVE RESEARCH LAYER                              │
 │  - `vyapaar-agent`: Closed-grammar code generation & research loop     │
 │  - Deterministic prompt & trade replay harness                         │
 ├────────────────────────────────────────────────────────────────────────┤
 │  TIER 3: STRATEGY, BACKTESTING & OPTIMIZATION PIPELINE                 │
 │  - Three-tier simulation: Vectorized Pre-filter -> Event Engine ->     │
 │    Distributed Bayesian / Genetic Parameter Sweeps                    │
 ├────────────────────────────────────────────────────────────────────────┤
 │  TIER 2: DATA ADAPTERS & EXECUTION GATEWAYS                            │
 │  - `vyapaar-market`: Parquet lakehouse catalog & real-time WS feeds   │
 │  - `vyapaar-exec`: Outbound broker execution, rate limiters, slicers   │
 │  - `vyapaar-risk`: SEBI algo verification, pre-trade risk limits       │
 ├────────────────────────────────────────────────────────────────────────┤
 │  TIER 1 & 0: KERNEL & AGGREGATES                                       │
 │  - `vyapaar-core`: Zero-I/O canonical domain kernel & wire types       │
 │  - `vyapaar-ledger`: FIFO tax-lot portfolio & double-entry ledger      │
 │  - `vyapaar-runtime`: Actor-oriented multi-threaded Tokio runtime     │
 └────────────────────────────────────────────────────────────────────────┘
```

---

## Where to Start

1. [Installation Guide](getting-started/installation.md) — Set up Rust toolchains, Python packages, and broker credentials.
2. [First Backtest Tutorial](getting-started/first-backtest.md) — Run an event-driven dual moving average backtest on NIFTY 50.
3. [Architecture Overview](architecture/overview.md) — Deep dive into the bounded context separation, crate hierarchy, and actor topology.
4. [Indian Market Calendar](india/market_calendar.md) — Understand exchange session windows, Muhurat trading, and settlement rules.
5. [Indian Cost Modeling](india/cost_model.md) — Learn how statutory STT, GST, and exchange fees are calculated.
6. [Platform Conformance Matrix](conformance_matrix.md) — Track implementation readiness across all 15 platform repositories.
