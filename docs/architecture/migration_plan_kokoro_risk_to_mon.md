# Migration Plan: Consolidating Pre-Trade Risk from `vyapaar-ledger-risk` to `vyapaar-risk`

> **[STATUS: IMPLEMENTED]** — `vyapaar-risk / vyapaar-ledger`. See [Platform Conformance Matrix](../conformance_matrix.md).

> **Document Status**: Active Migration Blueprint  
> **Author**: Google DeepMind Agentic Assistant (Antigravity)  
> **Target Subsystems**: `vyapaar-risk`, `vyapaar-runtime`, `vyapaar-ffi`, `vyapaar-agent`, `vyapaar-market`, `vyapaar-exec`, `vyapaar-ledger`  
> **Target Architecture**: Domain-Driven Design (DDD), Python-First Strategy SDK, Exact Decimal Precision (`rust_decimal`), Zero Floats, Temporal Determinism.

---

## 1. Context & Architectural Root Cause Analysis

### 1.1 The Domain-Driven Design (DDD) Bounded Context Realignment
Under the foundational architecture redesign of the **Vyapaar (本場)** platform, subsystem responsibilities are strictly demarcated across clear domain boundaries:

* **Kernel (`vyapaar-core`)**: Shared Kernel value objects (`Price`, `Quantity`, `Money`, `InstrumentId`), wire contracts, and safe closed AI grammar (`Decision`). Zero dependencies, zero I/O.
* **Heart (`vyapaar-ledger`)**: Institutional Order Management System (`oms`), FIFO tax-lot tracking (`portfolio`), and immutable double-entry general ledger.
* **Gate (`vyapaar-risk`)**: Pure, synchronous pre-trade regulatory risk engine. Enforces SEBI Retail Algo circular rules, Order-to-Trade Ratio (OTR) sliding-window circuit breakers, scrip-wise circuit price bands, single-order freeze limits, and global kill-switches.
* **House (`vyapaar-runtime`)**: Multi-threaded Tokio actor runtime, institutional backtester, and strategy optimizer.
* **Soul (`vyapaar-ffi`)**: PyO3 FFI bridge, Python-First Strategy SDK, and Arrow zero-copy memory transport.
* **Brain (`vyapaar-agent`)**: Autonomous AI research loop, MCP tools, and Odysseus genetic rule synthesis.

### 1.2 Root Cause of the Broken Dependencies
Historically, pre-trade risk checks were implemented in `vyapaar-ledger/crates/vyapaar-ledger-risk` alongside legacy crates (`vyapaar-ledger-types`, `vyapaar-ledger-messages`, `vyapaar-ledger-entities`, `vyapaar-ledger-ports`). These legacy crates suffered from several severe architectural flaws:
1. **Raw Floating-Point Leaks**: Used `f64` for order quantities, positions, prices, and collars, directly violating the **Zero Floats Policy**.
2. **Scattered Risk Responsibility**: Split risk checks between Kokoro (`RiskStage`) and Mon (`RiskEngine`), creating duplicate and contradictory validation logic.
3. **Premature Deletion in Kokoro**: In commit `245784e`, `vyapaar-ledger` unified its internal OMS and portfolio engines on `vyapaar-core` and excised all legacy crates (`crates/vyapaar-ledger-risk`, `types`, `messages`, `entities`, `ports`).

Because downstream crates in `vyapaar-runtime`, `vyapaar-ffi`, `vyapaar-agent`, `vyapaar-market`, and `vyapaar-exec` still declare path dependencies on the excised crates (e.g. `path = "../vyapaar-ledger/crates/vyapaar-ledger-risk"`), Cargo fails to resolve their manifests (`No such file or directory (os error 2)`).

This document establishes the **exhaustive, step-by-step migration plan** to purge all obsolete dependencies on `vyapaar-ledger-risk` and integrate `vyapaar-risk` as the single authoritative pre-trade risk gate across the platform.

---

## 2. Dependency & Code Usage Inventory

The following table details every broken manifest reference and code usage that must be migrated:

| Repository / Subsystem | File Location | Broken Dependency / Symbol | Action Required |
| :--- | :--- | :--- | :--- |
| **`vyapaar-market`** | `vyapaar-market/Cargo.toml` | `vyapaar-ledger-types` | Replace with `vyapaar-core = { path = "../vyapaar-core" }`. |
| **`vyapaar-exec`** | `vyapaar-exec/Cargo.toml` | `vyapaar-ledger-types` | Replace with `vyapaar-core = { path = "../vyapaar-core" }`. |
| **`vyapaar-risk`** | `src/engine.rs:274-285` | `Decision::Buy`, `Decision::Sell` | Update pattern match to `Decision::PlaceOrder { symbol, side, qty, price_limit, algo_id, .. }`. |
| **`vyapaar-risk`** | `src/engine.rs:310` | `order.validate()` | Use `order.order_type.validate()` or implement structural validation in `vyapaar-core::OrderRequest`. |
| **`vyapaar-runtime`** | `vyapaar-runtime/Cargo.toml:84-92` | `vyapaar-ledger-risk`, `vyapaar-risk`, `vyapaar-ports`, `vyapaar-marketssages`, `vyapaar-core` | Prune legacy paths. Add `vyapaar-risk = { path = "../vyapaar-risk" }` and `vyapaar-core = { path = "../vyapaar-core" }`. |
| **`vyapaar-runtime`** | `crates/vyapaar-runtime-config/src/lib.rs` | `vyapaar_risk::{OrderRateLimit, RiskLimits}` | Replace with `vyapaar_risk::{OrderRateLimit, RiskLimits}`. |
| **`vyapaar-runtime`** | `crates/vyapaar-runtime-cli/src/serve.rs` | `vyapaar_risk::RiskLimits` | Migrate to `vyapaar_risk::RiskLimits`. |
| **`vyapaar-runtime`** | `crates/vyapaar-runtime-actors/src/risk.rs` | `RiskActor` | Connect `RiskActor` synchronously to `vyapaar_risk::RiskEngine`. |
| **`vyapaar-runtime`** | `crates/vyapaar-runtime-engine/` | `vyapaar_risk::{RiskStage, RiskCheck, ...}` | Deprecate `vyapaar-runtime-engine` in favor of `vyapaar-runtime-actors` per Master Plan §0.1. |
| **`vyapaar-runtime`** | `crates/vyapaar-runtime-api-rest/src/orders.rs` | `vyapaar_risk::{RiskStage, RiskRefusal}` | Migrate pre-trade order refusal to `vyapaar_risk::RiskRefusal`. |
| **`vyapaar-ffi`**| `vyapaar-ffi/Cargo.toml:52-59` | `vyapaar-ledger-risk`, `vyapaar-ports`, `vyapaar-marketssages` | Prune legacy paths. Add `vyapaar-risk = { path = "../vyapaar-risk" }` and `vyapaar-core`. |
| **`vyapaar-ffi`**| `crates/vyapaar-ffi-py/src/pyclasses/risk.rs` | `vyapaar_risk::{OrderRateLimit, RiskDecision}` | Wrap `vyapaar_risk::RiskEngine`, `RiskLimits`, `RiskRefusal` via PyO3. |
| **`vyapaar-ffi`**| `python/vyapaar/risk.py` | Legacy `_POSITION_EPS = 1e-9` and float checks | Replace with decimal validation invoking native `vyapaar._vyapaar.RiskEngine`. |
| **`vyapaar-agent`** | `vyapaar-agent/Cargo.toml:55-61` | `vyapaar-ledger-risk`, `vyapaar-marketssages`, `vyapaar-core` | Prune legacy paths. Add `vyapaar-risk = { path = "../vyapaar-risk" }` and `vyapaar-core`. |
| **`vyapaar-agent`** | `crates/vyapaar-agent-strategy/src/runner.rs` | `vyapaar_risk::{RiskCheck, RiskStage}` | Evaluate `vyapaar_core::Decision` against `vyapaar_risk::RiskEngine`. |
| **`vyapaar-agent`** | `crates/vyapaar-agent-trader-loop/src/lib.rs` | `vyapaar_risk::RiskLimits` | Replace with `vyapaar_risk::RiskLimits`. |

---

## 3. Domain Model & API Transformation Matrix

### 3.1 `RiskLimits`: Floats to Exact Decimals & SEBI Compliance

| Old `vyapaar-ledger-risk::RiskLimits` | New `vyapaar-risk::RiskLimits` | Rationale & Behavioral Difference |
| :--- | :--- | :--- |
| `max_notional_per_order: Option<f64>` | `max_notional_per_order: Option<Decimal>` | Zero Floats Policy. Exact paisa-level precision without float drift. |
| `max_notional_per_day: Option<f64>` | `max_daily_notional: Option<Decimal>` | Aggregated cumulative daily turnover threshold. |
| `max_quantity_per_order: Option<f64>` | `single_order_freeze_limit: Option<Quantity>` | Strongly typed `Quantity`. Enforces exchange freeze limits (e.g. NIFTY 1,800, BANKNIFTY 900). |
| `price_collar_fraction: Option<f64>` | `scrip_circuit_limit_pct: Option<Decimal>` | Scrip operational band (2%, 5%, 10%, 20%). Replaces arbitrary float collars with exchange bands. |
| `order_rate_limit: Option<OrderRateLimit>` | `order_rate_limit: Option<OrderRateLimit>` | Max order events within a sliding window (e.g. 50 orders / 1,000 ms). |
| *(Missing in legacy)* | `max_otr: Option<Decimal>` | **SEBI Retail Algo Mandatory**: Order-to-Trade Ratio calculation ($OTR = \frac{Total Orders}{Executed Trades}$). Breaker halts algo if $OTR > 50$. |
| *(Missing in legacy)* | `require_sebi_algo_id: bool` | Strict rejection of orders lacking registered algo identifier. |

### 3.2 `RiskRefusal`: Strongly Typed, Serializable Taxonomy

The legacy `RiskRefusal` enum used raw floats and lacked JSON Schema serialization. In `vyapaar-risk`, `RiskRefusal` is a comprehensive, typed, serializable enumeration deriving `schemars::JsonSchema`:

```rust
// vyapaar-risk/src/refusal.rs
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(tag = "reason", content = "details", rename_all = "snake_case")]
pub enum RiskRefusal {
    GlobalHalted { reason: String },
    AlgoHalted { algo_id: String, reason: String },
    MarketCircuitHalt { index_symbol: String, stage_pct: u8, resume_at: Option<DateTime<Utc>> },
    OtrBreached { algo_id: String, current_otr: Decimal, max_otr: Decimal },
    PriceBandViolation { price: Price, band: PriceBand },
    MaxNotionalExceeded { requested: Decimal, limit: Decimal },
    SingleOrderFreezeExceeded { requested: Quantity, limit: Quantity },
    OrderRateLimitExceeded { count: u32, window_ms: u64 },
    MissingAlgoId,
    InvalidOrder { error: String },
}
```

### 3.3 Engine Invocation & Interface Shift
The legacy design required constructing a synthetic `RiskRequest` object:
```rust
// LEGACY (DEPRECATED):
let request = RiskRequest::new(&order, &market_state);
let decision = risk_stage.check(&request);
```

The new interface operates directly on canonical domain contracts with zero intermediate allocation:
```rust
// MODERN (vyapaar-risk):
let mut risk_engine = RiskEngine::new(risk_limits, otr_config);

// 1. Direct validation of outgoing broker orders:
risk_engine.check_order(&order_request, Utc::now())?;

// 2. Direct validation of untrusted AI/LLM decisions:
risk_engine.check_decision(&decision, Utc::now())?;
```

---

## 4. Subsystem-by-Subsystem Migration Plan

```mermaid
flowchart TD
    subgraph Phase 1: Leaf Crate Manifest Unification
        M1["vyapaar-market: Point to vyapaar-core"]
        M2["vyapaar-exec: Point to vyapaar-core"]
    end

    subgraph Phase 2: vyapaar-risk Engine Polish
        MON1["Fix Decision::PlaceOrder matching in RiskEngine"]
        MON2["Ensure 100% tests pass in vyapaar-risk/tests/"]
    end

    subgraph Phase 3: vyapaar-runtime Actor & Runtime Migration
        YA1["Purge vyapaar-ledger-* from vyapaar-runtime/Cargo.toml"]
        YA2["Wire vyapaar-runtime-actors::RiskActor to vyapaar-risk::RiskEngine"]
        YA3["Update vyapaar-runtime-config & vyapaar-runtime-api-rest to vyapaar_risk types"]
        YA4["Retire legacy vyapaar-runtime-engine"]
    end

    subgraph Phase 4: vyapaar-ffi Python SDK & PyO3
        TAM1["Purge legacy kokoro crates in Cargo.toml"]
        TAM2["Wrap vyapaar-risk::RiskEngine in PyO3 (vyapaar._vyapaar)"]
        TAM3["Refactor python/vyapaar/risk.py to native FFI"]
    end

    subgraph Phase 5: vyapaar-agent AI Brain & Runner
        NOU1["Purge legacy kokoro crates in Cargo.toml"]
        NOU2["Connect StrategyRunner to vyapaar-risk via Decision grammar"]
    end

    subgraph Phase 6: System Verification
        V1["cargo check --all across entire workspace"]
        V2["Run parallel test suites (tests/*)"]
        V3["Commit all repositories on branch main"]
    end

    Phase 1 --> Phase 2
    Phase 2 --> Phase 3
    Phase 3 --> Phase 4
    Phase 4 --> Phase 5
    Phase 5 --> Phase 6
```

### 4.1 Phase 1: Leaf Crate Manifest Unification (`vyapaar-market` & `vyapaar-exec`)
* **Goal**: Unblock Cargo manifest parsing in market data and execution subsystems.
* **Tasks**:
  1. In `vyapaar-market/Cargo.toml`, remove `vyapaar-ledger-types` and replace with `vyapaar-core = { path = "../vyapaar-core" }`.
  2. In `vyapaar-exec/Cargo.toml`, remove `vyapaar-ledger-types` and replace with `vyapaar-core = { path = "../vyapaar-core" }`.
  3. Verify `cargo check --manifest-path vyapaar-market/Cargo.toml` and `cargo check --manifest-path vyapaar-exec/Cargo.toml` pass cleanly.

### 4.2 Phase 2: `vyapaar-risk` Engine Polish
* **Goal**: Ensure `vyapaar-risk` compiles cleanly and passes all unit and integration tests.
* **Tasks**:
  1. In `vyapaar-risk/src/engine.rs`, update `check_decision()` to match `Decision::PlaceOrder { symbol, side, qty, price_limit, algo_id, .. }`.
  2. Implement structural order validation in `vyapaar-core::OrderRequest` or replace `order.validate()` with `order.order_type.validate()` in `vyapaar-risk/src/engine.rs`.
  3. Execute `cargo test --manifest-path vyapaar-risk/Cargo.toml` to guarantee 100% test pass rate in external `tests/` directory.

### 4.3 Phase 3: `vyapaar-runtime` Actor & Runtime Migration
* **Goal**: Modernize `vyapaar-runtime` to utilize `vyapaar-risk` for all pre-trade risk and retire legacy `vyapaar-runtime-engine`.
* **Tasks**:
  1. In `vyapaar-runtime/Cargo.toml`:
     - Delete `vyapaar-ledger-types`, `vyapaar-ledger-messages`, `vyapaar-ledger-entities`, `vyapaar-ledger-ports`, `vyapaar-ledger-risk`.
     - Add `vyapaar-risk = { path = "../vyapaar-risk" }`.
     - Point `vyapaar-core` directly to `../vyapaar-core`.
  2. In `vyapaar-runtime/crates/vyapaar-runtime-config/Cargo.toml`:
     - Replace `vyapaar-risk` dependency with `vyapaar-risk`.
     - In `src/lib.rs`, re-export `pub use vyapaar_risk::{OrderRateLimit, RiskLimits};`.
  3. In `vyapaar-runtime/crates/vyapaar-runtime-actors`:
     - Verify `RiskActor` holds `vyapaar_risk::RiskEngine`.
     - Ensure synchronous evaluation of order requests before passing to `ExecutionActor`.
  4. In `vyapaar-runtime/crates/vyapaar-runtime-api-rest`:
     - Update order placement endpoint in `src/orders.rs` to validate with `AppState.risk_engine` (`vyapaar-risk`).
     - Map `vyapaar_risk::RiskRefusal` to HTTP 422 Unprocessable Entity with structured JSON refusal payload.
  5. In `vyapaar-runtime/crates/vyapaar-runtime-cli`:
     - Update `serve.rs` to parse `RiskLimits` from `vyapaar-risk`.
  6. Retire or remove `vyapaar-runtime-engine` and `vyapaar-runtime-sim` references in favor of `vyapaar-runtime-actors` and `vyapaar-runtime-backtest`.

### 4.4 Phase 4: `vyapaar-ffi` Python SDK & PyO3 Native Bridge
* **Goal**: Expose `vyapaar-risk` to Python quantitative research and replace float-based checks.
* **Tasks**:
  1. In `vyapaar-ffi/Cargo.toml`:
     - Remove dead Kokoro crate references.
     - Add `vyapaar-risk = { path = "../vyapaar-risk" }` and `vyapaar-core = { path = "../vyapaar-core" }`.
  2. In `crates/vyapaar-ffi-py/src/pyclasses/risk.rs`:
     - Implement PyO3 wrappers `PyRiskEngine`, `PyRiskLimits`, and `PyRiskRefusal`.
     - Expose `.check_order(order: PyOrderRequest)` and `.check_decision(decision: PyDecision)`.
     - Release GIL (`py.allow_threads`) during risk evaluation.
  3. In `python/vyapaar/risk.py`:
     - Prune legacy float epsilon checks (`_POSITION_EPS`).
     - Route all risk checks to `vyapaar._vyapaar.RiskEngine`.

### 4.5 Phase 5: `vyapaar-agent` AI Brain & Strategy Runner Migration
* **Goal**: Connect AI strategy loops directly to `vyapaar-risk`.
* **Tasks**:
  1. In `vyapaar-agent/Cargo.toml`:
     - Remove `vyapaar-ledger-risk`, `vyapaar-marketssages`, `vyapaar-core`.
     - Add `vyapaar-risk = { path = "../vyapaar-risk" }` and `vyapaar-core = { path = "../vyapaar-core" }`.
  2. In `crates/vyapaar-agent-strategy/src/runner.rs`:
     - Update `StrategyRunner` to validate generated `Decision`s against `vyapaar_risk::RiskEngine`.
     - Persist SHA-256 prompt hashes and pre-trade refusal diagnostics in `vyapaar-runtime-persistence` audit logs.
  3. In `crates/vyapaar-agent-trader-loop/src/lib.rs`:
     - Update `RiskLimits` import to `vyapaar_risk::RiskLimits`.

### 4.6 Phase 6: System-Wide Verification & CI Integration
* **Goal**: Validate zero compilation errors, full test suite execution, and documentation parity.
* **Tasks**:
  1. Run `cargo check` across all Rust workspaces:
     ```bash
     for repo in vyapaar-core vyapaar-risk vyapaar-ledger vyapaar-market vyapaar-exec vyapaar-runtime vyapaar-agent vyapaar-ffi; do
       echo "Checking $repo..."
       cargo check --manifest-path "$repo/Cargo.toml" --all-targets
     done
     ```
  2. Run all unit and integration test suites in `tests/`:
     ```bash
     cargo test --all
     ```
  3. Run Python linting and type checks:
     ```bash
     ruff check . && ruff format --check . && pyright
     ```
  4. Build and verify documentation:
     ```bash
     cd vyapaar-docs && ../.venv/bin/mkdocs build
     ```

---

## 5. Architectural Invariants & Agent Guidelines

During the execution of this migration plan, all agents and contributors must strictly enforce:
1. **Parallel Test Directory Rule (`AGENTS.md §1.1`)**:
   Under no circumstances should `#[test]` or `#[cfg(test)] mod tests` be introduced into production files (`src/*.rs`). All tests must be placed in `tests/` parallel to `src/`.
2. **Interface-First Coding (`AGENTS.md §2.1`)**:
   Define traits and abstract contracts (`RiskGate`, `OrderValidator`) before implementing concrete broker or simulation adapters.
3. **Zero Floats Policy (`AGENTS.md §2.4`)**:
   All monetary amounts, execution prices, quantities, and statutory fees must utilize `rust_decimal::Decimal` (or `Price` / `Quantity` / `Money`). Floating-point types (`f32`, `f64`, Python `float`) are forbidden.
4. **Deterministic Temporal Purity (`AGENTS.md §2.5`)**:
   `vyapaar-risk` must remain strictly zero-I/O with no clock calls (`SystemTime::now()` is prohibited; state transitions take explicit `DateTime<Utc>`).
