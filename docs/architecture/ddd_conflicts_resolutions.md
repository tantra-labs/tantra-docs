# DDD Bounded Context Conflicts & Resolutions

> **[STATUS: IMPLEMENTED]** — Migration from `honba-workspace` to `tantra-labs`; 7 of 9 conflicts resolved, 1 HIGH priority (Zero-I/O) in progress, 1 partial (Screener/Signal ownership).
>
> This document identifies **DDD bounded context conflicts** that arose during the migration from `honba-workspace` to `tantra-labs` (the **new design**). Each conflict is mapped to its resolution, with responsibility assignments and dependency ordering.

---

## Executive Summary

The migration from `honba-workspace` to `tantra-labs` introduced a strict DDD architecture with 15 bounded repositories across 6 layers. During this migration, 9 bounded-context conflicts were identified. This document records each conflict, the old (`honba-*`) state, the new (`tantra-*`) state, and the resolution.

Overall status: **7/9 Resolved** | **1 HIGH Priority** (Zero-I/O domain purity) | **1 Partial** (Screener/Signal ownership).

---

## 1. Architecture Layer Dependencies

```mermaid
flowchart BT
    T0[Tier 0: tantra-core\n(Shared Kernel - No deps)]
    T1A[Tier 1A: tantra-risk\n(Zero-I/O)]
    T1B[Tier 1B: tantra-ledger\n(Zero-I/O)]
    T2A[Tier 2A: tantra-market\n(Compute: Zero-I/O,\nAdapters: Async)]
    T2B[Tier 2B: tantra-exec\n(Async I/O)]
    T3A[Tier 3A: tantra-agent\n(Async + Pure Core)]
    T3B[Tier 3B: tantra-runtime\n(Async)]
    T4[Tier 4: tantra-ffi\n(FI Bridge)]
    T5[Tier 5: tantra-ui\n(WASM / TUI)]
    T6[Tier 6: Python Ecosystem]

    T0 --> T1A
    T0 --> T1B
    T0 --> T2A
    T0 --> T2B
    T1A --> T2B
    T1A --> T3A
    T1A --> T3B
    T1B --> T3B
    T2A --> T3B
    T2B --> T3B
    T3A --> T3B
    T3B --> T4
    T0 --> T5
    T3B --> T5
    T4 --> T6
```

See [Architectural Layers & Bounded Context Topology](architecture_layers.md) for the full layer table.

---

## 2. Conflicting Responsibilities & Resolutions

### Conflict #1: Shared Kernel Bloat

| Aspect | `honba-core` (Old) | `tantra-core` (New) | Resolution |
|:-------|:-------------------|:---------------------|:-----------|
| **Portfolio Snapshot Types** | Included `PortfolioSnapshot`, `PortfolioPosition`, `PortfolioHolding`, `PortfolioTotals`, `PortfolioGreeks` | **MOVED** to `tantra-runtime-persistence` as repository read models | ✅ Clean separation: Domain events in core, read models in application layer |
| **Screener Types** | Included `ScreenerScanRequest`, `ScreenerRow`, `FilterOp`, `MetricDefinition`, `Signal` | **MOVED** to `tantra-runtime` (strategy) or `tantra-ui` (UI) | ⚠️ **PENDING**: Decide between runtime (domain signals) vs UI (screening UI) |
| **Signal Types** | Included `Signal`, `SignalDirection`, `SignalHorizon`, `Timeframe` | **REMAINS** in `tantra-core` (unclear boundary) | ⚠️ **CONSIDER**: Move to `tantra-runtime-strategy` or `tantra-agent` |
| **Size Method Types** | Included `SizingMethod`, `RiskBudget`, `PositionSizingRequest`, `PositionSizingResult` | **REMAINS** in `tantra-core` (shared across agent/runtime) | ✅ Correct - these are domain abstractions |

**Status**: ✅ Partially resolved | ⚠️ Pending (Screener/Signal)

**Action Required**: Decide on Screener/Signal ownership:
- **Option A**: `tantra-runtime-strategy` owns all strategy-related types (`Signal`, `Screener`)
- **Option B**: `tantra-ui` owns `Screener` (UI concern), `tantra-runtime-strategy` owns `Signal` (domain concept)

---

### Conflict #2: Portfolio Aggregate Responsibility

| Aspect | `honba-kokoro-portfolio` (Old) | `tantra-ledger-portfolio` (New) | Resolution |
|:-------|:-------------------------------|:---------------------------------|:-----------|
| **FIFO Tax-Lot Matching** | Embedded in `InMemoryPositionRepository` (application layer) | **ENCAPSULATED** in `Portfolio` aggregate root | ✅ Correct - business logic in domain |
| **Tax Lot Types** | Separate `Fitolot`, `CostBasisLot`, `TaxLot` | **UNIFIED** into single `TaxLot` entity | ✅ Correct - single canonical model |
| **Account State** | `AccountState` with `positions`, `holdings`, `totals` | **REMAINS** as domain state (not read model) | ✅ Correct - this is domain state machine |

**Key Difference**:
- **Old**: `InMemoryPositionRepository.match_lots()` was an application service method
- **New**: `PortfolioAggregate.apply_fill(fill)` encapsulates FIFO matching

**Status**: ✅ RESOLVED

---

### Conflict #3: Exchange / ProductType Unification

| Aspect | `honba-*` (Old) | `tantra-*` (New) | Resolution |
|:-------|:----------------|:------------------|:-----------|
| **Exchange Enum** | Redefined in `honba-kokoro-oms`, `honba-kokoro-ledger`, `honba-me-market`, `honba-te-*` | **CANONICAL** in `tantra-core::Exchange` with variants `{Nse, Bse, Nfo, Mcx, Cds}` | ✅ Correct - single source of truth |
| **Product Type** | Redefined in multiple places | **ADDED** to `tantra-core::ProductType` (if missing) | ⚠️ **VERIFY**: Ensure `ProductType::{Delivery, Intraday, Margin, CoverOrder, BracketOrder}` exists |

**Status**: ✅ RESOLVED (Exchange) | ⚠️ VERIFY (ProductType)

**Action Required**: Verify `ProductType` enum exists in `tantra-core/src/types.rs`:
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum ProductType {
    Delivery,
    Intraday,
    Margin,
    CoverOrder,
    BracketOrder,
}
```

---

### Conflict #4: Market Finance Ownership

| Aspect | `honba-me-market` (Old) | `tantra-market-*` (New) | Resolution |
|:-------|:------------------------|:-----------------------|:-----------|
| **Indian Market Profile** | `honba-me-market` owned `NseCalendar`, `CostModel`, `FnoContract`, statutory costs | **ASSIGNED** to `tantra-market-finance` | ✅ Correct |
| **Cost Schedule** | STT, Stamp Duty, GST, SEBI, Exchange turnover | **ASSIGNED** to `tantra-market-finance::india::costs` | ✅ Correct |
| **Macro/Financial Series** | Mixed with market data | **ASSIGNED** to `tantra-market-finance` | ✅ Correct |

**Sub-Crate Split**: `honba-me-feed` → `tantra-market-feed` + `tantra-market-store`

| `tantra-market-feed` | `tantra-market-store` |
|:---------------------:|:---------------------:|
| Live stream traits | Parquet lakehouse storage |
| `CoalescingTickBuffer` | `lakehouse.rs`, `parquet_ticks.rs` |
| `ReconnectionManager` | `recorder.rs`, `export/`, `import/` |
| `live_quotes.rs` | `dataset.rs` |

**Status**: ✅ RESOLVED

---

### Conflict #5: Zero-I/O Domain Purity

| Crate | `honba-*` Dependencies | `tantra-*` Dependencies | Status |
|:------|:----------------------|:------------------------|:-------|
| `tantra-core` | No async | No `tokio` | ✅ Compliant |
| `tantra-risk` | No async | No `tokio` | ✅ Compliant |
| `tantra-ledger` | `honba-kokoro` had `tokio` | **MUST REMOVE** `tokio` from workspace | 🚧 **IN PROGRESS** |
| `tantra-ledger-oms` | Had `#[tokio::test]` | Synchronous only with `now: DateTime<Utc>` | 🚧 **IN PROGRESS** |
| `tantra-ledger-portfolio` | Had `async fn` methods | Synchronous with explicit timestamp | 🚧 **IN PROGRESS** |
| `tantra-market-*` | Mixed `tokio`/`async-trait` | Compute crates: no `tokio`; Adapters: `tokio` OK | 🚧 **IN PROGRESS** |
| `tantra-exec-*` | Had `tokio` | Async OK (application layer) | 🚧 **IN PROGRESS** |
| `tantra-runtime-*` | Had `tokio` | Async OK (application layer) | 🚧 **IN PROGRESS` |

**Key Rule**:
- **Domain Layer (L0-L1)**: `tantra-core`, `tantra-risk`, `tantra-ledger-*` — **ZERO `tokio`**
- **Application Layer (L2+)**: `tantra-market-*`, `tantra-exec-*`, `tantra-runtime-*` — `tokio` OK

**Status**: 🚧 **IN PROGRESS** (tantra-ledger workspace tokio removal) — **HIGH Priority**

---

### Conflict #6: Anti-Corruption Layer (ACL) Boundaries

| Component | Old Location | New Location | Responsibility |
|:----------|:-------------|:-------------|:---------------|
| **Zerodha Kite Wire Format** | `honba-te-zerodha` (mixed) | `tantra-exec-zerodha` | ✅ ACL: `zerodha_proto` ↔ `tantra_core` |
| **Upstox Protobuf Wire** | `honba-te-upstox` (mixed) | `tantra-exec-upstox` | ✅ ACL: `upstox_proto` ↔ `tantra_core` |
| **Angel One SmartAPI** | `honba-te-angelone` (mixed) | `tantra-exec-angelone` | ✅ ACL: `angelone_json` ↔ `tantra_core` |
| **Risk Engine Integration** | `honba-te-router` called `honba_mon::RiskEngine` | `tantra-exec-router` calls `tantra_risk::RiskEngine` | ✅ ACL: Risk check before broker order |

**Status**: ✅ RESOLVED (ACL pattern established, implementation pending)

---

### Conflict #7: Read Model vs Domain State

| Type | Old Location | New Location | Reason |
|:-----|:-------------|:-------------|:-------|
| `PortfolioSnapshot` | `honba-core` (shared kernel) | `tantra-runtime-persistence` | Repository read model (application layer) |
| `PortfolioPosition` | `honba-core` (shared kernel) | `tantra-runtime-persistence` | Repository read model |
| `PortfolioHolding` | `honba-core` (shared kernel) | `tantra-runtime-persistence` | Repository read model |
| `PortfolioTotals` | `honba-core` (shared kernel) | `tantra-runtime-persistence` | Repository read model |
| `PortfolioGreeks` | `honba-core` (shared kernel) | `tantra-runtime-persistence` | Repository read model |
| `PortfolioSnapshot` (domain) | N/A | `tantra-ledger-portfolio::AccountState` | Domain state machine |

**Status**: ✅ RESOLVED (read models moved to application layer)

**Key Insight**:
- **Domain**: `PortfolioAggregate` has internal state `positions: Vec<PortfolioPosition>` (domain entity)
- **Application**: `PortfolioSnapshot` is serialized read model for UI/API (DTO)

---

### Conflict #8: Test Organization

| Crate | Old Pattern | New Pattern | Status |
|:------|:-----------|:-----------|:-------|
| `honba-*` | `#[cfg(test)] mod tests` inline in `src/` | `crates/*/tests/*.rs` | 🚧 Migration in progress |
| `tantra-*` | — | Strict parallel `tests/` directory | ✅ Policy established |

**Rule**:
```
❌ VIOLATION: src/lib.rs contains #[cfg(test)] mod tests
✅ CORRECT: tests/unit_tests.rs parallel to src/lib.rs
```

**Status**: 🚧 **IN PROGRESS**

---

### Conflict #9: Agent-Runtime Dependency Cycle

| Aspect | `honba-nou` (Old) | `tantra-agent` (New) | Resolution |
|:-------|:-----------------|:---------------------|:-----------|
| **Dependency on Strategy** | `honba-nou-trader-loop` → `honba-ya-strategy` | `tantra-agent-trader-loop` → `tantra_risk` only | ✅ Cycle broken |
| **Strategy as Dependency** | `tantra-runtime` could depend on `tantra-agent` | **FORBIDDEN**: `tantra-runtime` depends on `tantra-core` only | ✅ Dependency graph simplified |

**New Dependency Graph**:
```
tantra-core ← tantra-risk ← tantra-agent
                              ↑
              tantra-runtime depends only on tantra-core
```

**Status**: ✅ RESOLVED (dependency cycle removed)

---

## 3. Remaining Ambiguities

### Ambiguity #1: Signal vs Strategy Ownership

| Question | Options |
|:---------|:-------|
| **Where does `Signal` belong?** | A) `tantra-core` (domain primitive)<br>B) `tantra-runtime-strategy` (application signal)<br>C) `tantra-agent` (AI signal generation) |
| **Current State** | `tantra-core/src/signal.rs` contains `Signal`, `SignalDirection`, `SignalHorizon`, `Timeframe` |
| **Recommendation** | **A) `tantra-core`** - Signals are domain primitives (like `Order`, `Fill`) |

**Decision Required**: None - current placement is correct.

---

### Ambiguity #2: Screener Ownership

| Question | Options |
|:---------|:-------|
| **Where does `Screener` belong?** | A) `tantra-runtime` (strategy scanning)<br>B) `tantra-ui` (UI screening UI) |
| **Current State** | `tantra-core/src/screener.rs` contains `ScreenerScanRequest`, `ScreenerRow`, `FilterOp`, `MetricDefinition` |
| **Recommendation** | **A) `tantra-runtime`** - Screener is strategy tool, UI consumes runtime API |

**Decision Required**: Move `screener.rs` to `tantra-runtime-strategy` or keep in `tantra-core`?

---

### Ambiguity #3: Market Finance Scope

| Question | Options |
|:---------|:-------|
| **What goes in `tantra-market-finance`?** | A) Only `NseCalendar`, `CostModel`<br>B) Also `indicators`, `signals`, `normalizer` |
| **Current State** | Crate exists but empty stub |
| **Recommendation** | **A) Only canonical market data** - indicators/signals belong in separate crates |

**Decision Required**: Keep `tantra-market-finance` narrow (calendar/costs) or expand?

---

## 4. Migration Checklist

### Tier 0: Shared Kernel (`tantra-core`) ✅
- [x] `Exchange::{Nse, Bse, Nfo, Mcx, Cds}` unified
- [x] Strongly-typed IDs: `ClientOrderId`, `AlgoId`, `AccountId`, `TransactionId`
- [x] Self-validating `Price::try_new`, `Quantity::try_new`
- [ ] ⚠️ Decision on `screener.rs` location
- [ ] ⚠️ Decision on `signal.rs` location
- [ ] Verify `ProductType` enum exists

### Tier 1A: Risk Gate (`tantra-risk`) ✅
- [x] Zero `tokio` dependency
- [x] Explicit `now: DateTime<Utc>` on all checks
- [ ] Extract inline tests to `tests/`

### Tier 1B: Ledger Domain (`tantra-ledger`) 🚧
- [ ] **REMOVE `tokio`** from workspace dependencies
- [ ] Implement `tantra-ledger-oms` with `OrderStateMachine`
- [ ] Implement `tantra-ledger-portfolio` with `PortfolioAggregate`
- [ ] Implement `tantra-ledger-journal` with double-entry ledger
- [ ] Extract all tests to `tests/`

### Tier 2A: Market (`tantra-market`) 🚧
- [ ] Implement `tantra-market-finance` (NseCalendar, CostModel, India pack)
- [ ] Split `tantra-market-feed` / `tantra-market-store`
- [ ] Implement `tantra-market-indicators`, `tantra-market-signals`
- [ ] Extract all tests to `tests/`

### Tier 2B: Execution (`tantra-exec`) 🚧
- [ ] Implement `tantra-exec-router` with `tantra_risk::RiskEngine` gate
- [ ] Implement ACL modules for all brokers (Zerodha, Upstox, Angel One, Fyers)
- [ ] Extract all tests to `tests/`

### Tier 3A: Agent (`tantra-agent`) 🚧
- [ ] Implement `tantra-agent-tools`, `tantra-agent-plugins`, `tantra-agent-report`
- [ ] Ensure no upward dependency on `tantra-runtime`
- [ ] Extract all tests to `tests/`

### Tier 3B: Runtime (`tantra-runtime`) 🚧
- [ ] Implement `tantra-runtime-jobs`
- [ ] Move `src/tests/*` to `tests/` (both `tantra-runtime-strategy` and `tantra-runtime-testing`)
- [ ] Extract all tests to `tests/`

### Tier 4: FFI Bridge (`tantra-ffi`) ✅
- [x] Port PyO3 FFI bridge (`tantra-ffi-py`)
- [x] Implement schema codegen (`tantra-ffi-codegen`)
- [x] Build `tantra` wheel with `tantra._tantra` native module
- [x] Ensure GIL release (`py.detach` / `py.allow_threads`) during Rust actor execution

### Tier 5: Workstations (`tantra-ui`) 🚧
- [ ] Implement `tantra-cli`, `tantra-tui`, `tantra-highlight`
- [ ] Extract all tests to `tests/`
- [ ] Verify WASM portability (`cargo check -p tantra-ui-app --target wasm32-unknown-unknown`)

### Tier 6: Python Ecosystem 🚧
- [ ] **tantra-data**: Fix `pyproject.toml` (remove `rust_decimal`, add `duckdb`, `polars`, `pyarrow`, `pydantic`)
- [ ] **tantra-adapters**: Fix `pyproject.toml`, configure entry points for broker adapters
- [ ] **tantra-strategies**: Fix `pyproject.toml`, port strategy catalog
- [ ] **tantra-examples**: Port runnable reference scripts
- [ ] All: Extract tests to `tests/` directories

---

## 5. Conflict Summary Table

| Conflict # | Description | Status | Impact |
|:-----------|:-----------|:-------|:-------|
| #1 | Shared kernel bloat (PortfolioSnapshot, Screener, Signal) | ✅ Partially resolved | Low - pending screener/signal decision |
| #2 | Portfolio FIFO matching in repository | ✅ Resolved | None - fixed |
| #3 | Exchange/ProductType redefinition | ✅ Resolved | None - canonical types in core |
| #4 | Market finance ownership | ✅ Resolved | None - clear split |
| #5 | Zero-I/O domain purity | 🚧 In progress | **HIGH** - tantra-ledger tokio must be removed |
| #6 | ACL boundaries | ✅ Pattern established | None - implementation pending |
| #7 | Read model vs domain state | ✅ Resolved | None - clear separation |
| #8 | Test organization | 🚧 In progress | Medium - parallel tests required |
| #9 | Agent-runtime dependency cycle | ✅ Resolved | None - cycle broken |

**Overall Status**: **7/9 Resolved** | **1 HIGH Priority** (Zero-I/O) | **1 Partial** (Screener/Signal)

---

## 6. Next Steps

### Immediate (This Week)
1. **Remove `tokio` from `tantra-ledger/Cargo.toml` workspace dependencies**
2. **Verify `ProductType` enum exists** in `tantra-core/src/types.rs`
3. **Document screener/signal ownership** decision in this file
4. **Fix Python `pyproject.toml` files** (remove invalid `rust_decimal`, add proper dependencies)

### Short Term (This Month)
1. Implement `tantra-ledger-oms`, `tantra-ledger-portfolio`, `tantra-ledger-journal`
2. Implement `tantra-market-finance` with India market profile
3. Extract all tests to `tests/` directories (Rust + Python)
4. Implement schema codegen and FFI bridge (`tantra-ffi`)

### Medium Term (Next Quarter)
1. Implement ACL modules in all broker executors
2. Complete Tier 3 (Agent + Runtime) migration
3. Complete Tier 5 (UI) migration
4. Validate zero-I/O compliance across all domain crates (L0-L1)

---

## Related Documents

* **[Architectural Layers & Bounded Context Topology](architecture_layers.md)** — The 6-layer, 15-repo DDD topology.
* **[Domain-Driven Design (DDD)](domain_driven_design.md)** — Deep dive into bounded contexts, aggregates, value objects.
* **[Platform Conformance Matrix](../conformance_matrix.md)** — Per-repo implementation status.
