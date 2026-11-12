# Migration Plan: Consolidating Pre-Trade Risk from `tantra-ledger-risk` to `tantra-risk`

> **[STATUS: IMPLEMENTED]** — `tantra-risk / tantra-ledger`. See [Platform Conformance Matrix](../conformance_matrix.md).

> **Document Status**: Active Migration Blueprint  
> **Author**: Google DeepMind Agentic Assistant (Antigravity)  
> **Target Subsystems**: `tantra-risk`, `tantra-runtime`, `tantra-ffi`, `tantra-agent`, `tantra-market`, `tantra-exec`, `tantra-ledger`  
> **Target Architecture**: Domain-Driven Design (DDD), Python-First Strategy SDK, Exact Decimal Precision (`rust_decimal`), Zero Floats, Temporal Determinism.

---

## 1. Context & Architectural Root Cause Analysis

### 1.1 The Domain-Driven Design (DDD) Bounded Context Realignment
Under the foundational architecture redesign of the **Tantra (本場)** platform, subsystem responsibilities are strictly demarcated across clear domain boundaries:

* **Kernel (`tantra-core`)**: Shared Kernel value objects (`Price`, `Quantity`, `Money`, `InstrumentId`), wire contracts, and safe closed AI grammar (`Decision`). Zero dependencies, zero I/O.
* **Heart (`tantra-ledger`)**: Institutional Order Management System (`oms`), FIFO tax-lot tracking (`portfolio`), and immutable double-entry general ledger.
* **Gate (`tantra-risk`)**: Pure, synchronous pre-trade regulatory risk engine. Enforces SEBI Retail Algo circular rules, Order-to-Trade Ratio (OTR) sliding-window circuit breakers, scrip-wise circuit price bands, single-order freeze limits, and global kill-switches.
* **House (`tantra-runtime`)**: Multi-threaded Tokio actor runtime, institutional backtester, and strategy optimizer.
* **Soul (`tantra-ffi`)**: PyO3 FFI bridge, Python-First Strategy SDK, and Arrow zero-copy memory transport.
* **Brain (`tantra-agent`)**: Autonomous AI research loop, MCP tools, and Odysseus genetic rule synthesis.

### 1.2 Root Cause of the Broken Dependencies
Historically, pre-trade risk checks were implemented in `tantra-ledger/crates/tantra-ledger-risk` alongside legacy crates (`tantra-ledger-types`, `tantra-ledger-messages`, `tantra-ledger-entities`, `tantra-ledger-ports`). These legacy crates suffered from several severe architectural flaws:
1. **Raw Floating-Point Leaks**: Used `f64` for order quantities, positions, prices, and collars, directly violating the **Zero Floats Policy**.
2. **Scattered Risk Responsibility**: Split risk checks between Kokoro (`RiskStage`) and Mon (`RiskEngine`), creating duplicate and contradictory validation logic.
3. **Premature Deletion in Kokoro**: In commit `245784e`, `tantra-ledger` unified its internal OMS and portfolio engines on `tantra-core` and excised all legacy crates (`crates/tantra-ledger-risk`, `types`, `messages`, `entities`, `ports`).

Because downstream crates in `tantra-runtime`, `tantra-ffi`, `tantra-agent`, `tantra-market`, and `tantra-exec` still declare path dependencies on the excised crates (e.g. `path = "../tantra-ledger/crates/tantra-ledger-risk"`), Cargo fails to resolve their manifests (`No such file or directory (os error 2)`).

This document establishes the **exhaustive, step-by-step migration plan** to purge all obsolete dependencies on `tantra-ledger-risk` and integrate `tantra-risk` as the single authoritative pre-trade risk gate across the platform.

---

## 2. Dependency & Code Usage Inventory

The following table details every broken manifest reference and code usage that must be migrated:

| Repository / Subsystem | File Location | Broken Dependency / Symbol | Action Required |
| :--- | :--- | :--- | :--- |
| **`tantra-market`** | `tantra-market/Cargo.toml` | `tantra-ledger-types` | Replace with `tantra-core = { path = "../tantra-core" }`. |
| **`tantra-exec`** | `tantra-exec/Cargo.toml` | `tantra-ledger-types` | Replace with `tantra-core = { path = "../tantra-core" }`. |
| **`tantra-risk`** | `src/engine.rs:274-285` | `Decision::Buy`, `Decision::Sell` | Update pattern match to `Decision::PlaceOrder { symbol, side, qty, price_limit, algo_id, .. }`. |
| **`tantra-risk`** | `src/engine.rs:310` | `order.validate()` | Use `order.order_type.validate()` or implement structural validation in `tantra-core::OrderRequest`. |
| **`tantra-runtime`** | `tantra-runtime/Cargo.toml:84-92` | `tantra-ledger-risk`, `tantra-risk`, `tantra-ports`, `tantra-marketssages`, `tantra-core` | Prune legacy paths. Add `tantra-risk = { path = "../tantra-risk" }` and `tantra-core = { path = "../tantra-core" }`. |
| **`tantra-runtime`** | `crates/tantra-runtime-config/src/lib.rs` | `tantra_risk::{OrderRateLimit, RiskLimits}` | Replace with `tantra_risk::{OrderRateLimit, RiskLimits}`. |
| **`tantra-runtime`** | `crates/tantra-runtime-cli/src/serve.rs` | `tantra_risk::RiskLimits` | Migrate to `tantra_risk::RiskLimits`. |
| **`tantra-runtime`** | `crates/tantra-runtime-actors/src/risk.rs` | `RiskActor` | Connect `RiskActor` synchronously to `tantra_risk::RiskEngine`. |
| **`tantra-runtime`** | `crates/tantra-runtime-engine/` | `tantra_risk::{RiskStage, RiskCheck, ...}` | Deprecate `tantra-runtime-engine` in favor of `tantra-runtime-actors` per Master Plan §0.1. |
| **`tantra-runtime`** | `crates/tantra-runtime-api-rest/src/orders.rs` | `tantra_risk::{RiskStage, RiskRefusal}` | Migrate pre-trade order refusal to `tantra_risk::RiskRefusal`. |
| **`tantra-ffi`**| `tantra-ffi/Cargo.toml:52-59` | `tantra-ledger-risk`, `tantra-ports`, `tantra-marketssages` | Prune legacy paths. Add `tantra-risk = { path = "../tantra-risk" }` and `tantra-core`. |
| **`tantra-ffi`**| `crates/tantra-ffi-py/src/pyclasses/risk.rs` | `tantra_risk::{OrderRateLimit, RiskDecision}` | Wrap `tantra_risk::RiskEngine`, `RiskLimits`, `RiskRefusal` via PyO3. |
| **`tantra-ffi`**| `python/tantra/risk.py` | Legacy `_POSITION_EPS = 1e-9` and float checks | Replace with decimal validation invoking native `tantra._tantra.RiskEngine`. |
| **`tantra-agent`** | `tantra-agent/Cargo.toml:55-61` | `tantra-ledger-risk`, `tantra-marketssages`, `tantra-core` | Prune legacy paths. Add `tantra-risk = { path = "../tantra-risk" }` and `tantra-core`. |
| **`tantra-agent`** | `crates/tantra-agent-strategy/src/runner.rs` | `tantra_risk::{RiskCheck, RiskStage}` | Evaluate `tantra_core::Decision` against `tantra_risk::RiskEngine`. |
| **`tantra-agent`** | `crates/tantra-agent-trader-loop/src/lib.rs` | `tantra_risk::RiskLimits` | Replace with `tantra_risk::RiskLimits`. |

---

## 3. Domain Model & API Transformation Matrix

### 3.1 `RiskLimits`: Floats to Exact Decimals & SEBI Compliance

| Old `tantra-ledger-risk::RiskLimits` | New `tantra-risk::RiskLimits` | Rationale & Behavioral Difference |
| :--- | :--- | :--- |
| `max_notional_per_order: Option<f64>` | `max_notional_per_order: Option<Decimal>` | Zero Floats Policy. Exact paisa-level precision without float drift. |
| `max_notional_per_day: Option<f64>` | `max_daily_notional: Option<Decimal>` | Aggregated cumulative daily turnover threshold. |
| `max_quantity_per_order: Option<f64>` | `single_order_freeze_limit: Option<Quantity>` | Strongly typed `Quantity`. Enforces exchange freeze limits (e.g. NIFTY 1,800, BANKNIFTY 900). |
| `price_collar_fraction: Option<f64>` | `scrip_circuit_limit_pct: Option<Decimal>` | Scrip operational band (2%, 5%, 10%, 20%). Replaces arbitrary float collars with exchange bands. |
| `order_rate_limit: Option<OrderRateLimit>` | `order_rate_limit: Option<OrderRateLimit>` | Max order events within a sliding window (e.g. 50 orders / 1,000 ms). |
| *(Missing in legacy)* | `max_otr: Option<Decimal>` | **SEBI Retail Algo Mandatory**: Order-to-Trade Ratio calculation ($OTR = \frac{Total Orders}{Executed Trades}$). Breaker halts algo if $OTR > 50$. |
| *(Missing in legacy)* | `require_sebi_algo_id: bool` | Strict rejection of orders lacking registered algo identifier. |

### 3.2 `RiskRefusal`: Strongly Typed, Serializable Taxonomy

The legacy `RiskRefusal` enum used raw floats and lacked JSON Schema serialization. In `tantra-risk`, `RiskRefusal` is a comprehensive, typed, serializable enumeration deriving `schemars::JsonSchema`:

```rust
// tantra-risk/src/refusal.rs
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
// MODERN (tantra-risk):
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
        M1["tantra-market: Point to tantra-core"]
        M2["tantra-exec: Point to tantra-core"]
    end

    subgraph Phase 2: tantra-risk Engine Polish
        MON1["Fix Decision::PlaceOrder matching in RiskEngine"]
        MON2["Ensure 100% tests pass in tantra-risk/tests/"]
    end

    subgraph Phase 3: tantra-runtime Actor & Runtime Migration
        YA1["Purge tantra-ledger-* from tantra-runtime/Cargo.toml"]
        YA2["Wire tantra-runtime-actors::RiskActor to tantra-risk::RiskEngine"]
        YA3["Update tantra-runtime-config & tantra-runtime-api-rest to tantra_risk types"]
        YA4["Retire legacy tantra-runtime-engine"]
    end

    subgraph Phase 4: tantra-ffi Python SDK & PyO3
        TAM1["Purge legacy kokoro crates in Cargo.toml"]
        TAM2["Wrap tantra-risk::RiskEngine in PyO3 (tantra._tantra)"]
        TAM3["Refactor python/tantra/risk.py to native FFI"]
    end

    subgraph Phase 5: tantra-agent AI Brain & Runner
        NOU1["Purge legacy kokoro crates in Cargo.toml"]
        NOU2["Connect StrategyRunner to tantra-risk via Decision grammar"]
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

### 4.1 Phase 1: Leaf Crate Manifest Unification (`tantra-market` & `tantra-exec`)
* **Goal**: Unblock Cargo manifest parsing in market data and execution subsystems.
* **Tasks**:
  1. In `tantra-market/Cargo.toml`, remove `tantra-ledger-types` and replace with `tantra-core = { path = "../tantra-core" }`.
  2. In `tantra-exec/Cargo.toml`, remove `tantra-ledger-types` and replace with `tantra-core = { path = "../tantra-core" }`.
  3. Verify `cargo check --manifest-path tantra-market/Cargo.toml` and `cargo check --manifest-path tantra-exec/Cargo.toml` pass cleanly.

### 4.2 Phase 2: `tantra-risk` Engine Polish
* **Goal**: Ensure `tantra-risk` compiles cleanly and passes all unit and integration tests.
* **Tasks**:
  1. In `tantra-risk/src/engine.rs`, update `check_decision()` to match `Decision::PlaceOrder { symbol, side, qty, price_limit, algo_id, .. }`.
  2. Implement structural order validation in `tantra-core::OrderRequest` or replace `order.validate()` with `order.order_type.validate()` in `tantra-risk/src/engine.rs`.
  3. Execute `cargo test --manifest-path tantra-risk/Cargo.toml` to guarantee 100% test pass rate in external `tests/` directory.

### 4.3 Phase 3: `tantra-runtime` Actor & Runtime Migration
* **Goal**: Modernize `tantra-runtime` to utilize `tantra-risk` for all pre-trade risk and retire legacy `tantra-runtime-engine`.
* **Tasks**:
  1. In `tantra-runtime/Cargo.toml`:
     - Delete `tantra-ledger-types`, `tantra-ledger-messages`, `tantra-ledger-entities`, `tantra-ledger-ports`, `tantra-ledger-risk`.
     - Add `tantra-risk = { path = "../tantra-risk" }`.
     - Point `tantra-core` directly to `../tantra-core`.
  2. In `tantra-runtime/crates/tantra-runtime-config/Cargo.toml`:
     - Replace `tantra-risk` dependency with `tantra-risk`.
     - In `src/lib.rs`, re-export `pub use tantra_risk::{OrderRateLimit, RiskLimits};`.
  3. In `tantra-runtime/crates/tantra-runtime-actors`:
     - Verify `RiskActor` holds `tantra_risk::RiskEngine`.
     - Ensure synchronous evaluation of order requests before passing to `ExecutionActor`.
  4. In `tantra-runtime/crates/tantra-runtime-api-rest`:
     - Update order placement endpoint in `src/orders.rs` to validate with `AppState.risk_engine` (`tantra-risk`).
     - Map `tantra_risk::RiskRefusal` to HTTP 422 Unprocessable Entity with structured JSON refusal payload.
  5. In `tantra-runtime/crates/tantra-runtime-cli`:
     - Update `serve.rs` to parse `RiskLimits` from `tantra-risk`.
  6. Retire or remove `tantra-runtime-engine` and `tantra-runtime-sim` references in favor of `tantra-runtime-actors` and `tantra-runtime-backtest`.

### 4.4 Phase 4: `tantra-ffi` Python SDK & PyO3 Native Bridge
* **Goal**: Expose `tantra-risk` to Python quantitative research and replace float-based checks.
* **Tasks**:
  1. In `tantra-ffi/Cargo.toml`:
     - Remove dead Kokoro crate references.
     - Add `tantra-risk = { path = "../tantra-risk" }` and `tantra-core = { path = "../tantra-core" }`.
  2. In `crates/tantra-ffi-py/src/pyclasses/risk.rs`:
     - Implement PyO3 wrappers `PyRiskEngine`, `PyRiskLimits`, and `PyRiskRefusal`.
     - Expose `.check_order(order: PyOrderRequest)` and `.check_decision(decision: PyDecision)`.
     - Release GIL (`py.allow_threads`) during risk evaluation.
  3. In `python/tantra/risk.py`:
     - Prune legacy float epsilon checks (`_POSITION_EPS`).
     - Route all risk checks to `tantra._tantra.RiskEngine`.

### 4.5 Phase 5: `tantra-agent` AI Brain & Strategy Runner Migration
* **Goal**: Connect AI strategy loops directly to `tantra-risk`.
* **Tasks**:
  1. In `tantra-agent/Cargo.toml`:
     - Remove `tantra-ledger-risk`, `tantra-marketssages`, `tantra-core`.
     - Add `tantra-risk = { path = "../tantra-risk" }` and `tantra-core = { path = "../tantra-core" }`.
  2. In `crates/tantra-agent-strategy/src/runner.rs`:
     - Update `StrategyRunner` to validate generated `Decision`s against `tantra_risk::RiskEngine`.
     - Persist SHA-256 prompt hashes and pre-trade refusal diagnostics in `tantra-runtime-persistence` audit logs.
  3. In `crates/tantra-agent-trader-loop/src/lib.rs`:
     - Update `RiskLimits` import to `tantra_risk::RiskLimits`.

### 4.6 Phase 6: System-Wide Verification & CI Integration
* **Goal**: Validate zero compilation errors, full test suite execution, and documentation parity.
* **Tasks**:
  1. Run `cargo check` across all Rust workspaces:
     ```bash
     for repo in tantra-core tantra-risk tantra-ledger tantra-market tantra-exec tantra-runtime tantra-agent tantra-ffi; do
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
     cd tantra-docs && ../.venv/bin/mkdocs build
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
   `tantra-risk` must remain strictly zero-I/O with no clock calls (`SystemTime::now()` is prohibited; state transitions take explicit `DateTime<Utc>`).
