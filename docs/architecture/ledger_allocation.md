# Ledger Allocation — Portfolio Allocation & Optimization Engine

> **[STATUS: IMPLEMENTED]** — `tantra-ledger-allocation` crate, Phase 1. See [Platform Conformance Matrix](../conformance_matrix.md).
>
> `tantra-ledger-allocation` (Tier 1B, plan 0001) is the **pure portfolio allocation & optimization engine**. It computes target weights (`TargetWeights`) for a universe of instruments given expected returns, a covariance matrix, and weight bounds — all in exact `rust_decimal::Decimal`, zero-I/O, zero-floats.

---

## 1. Bounded Context & Responsibility

`tantra-ledger-allocation` sits inside `tantra-ledger` (Tier 1B, Zero-I/O domain heart). It is a **read-only optimizer**: it never mutates portfolio state, never touches the network or disk, and never calls the wall clock. It takes a `PortfolioState` (built from `tantra-ledger-portfolio`) plus return/covariance estimates and produces `TargetWeights`.

**Key design invariants:**

| Invariant | How it's enforced |
|-----------|-------------------|
| **Zero-I/O** | Pure synchronous functions; no `tokio`, no filesystem, no database, no wall-clock. |
| **Zero floats** | All weights, bounds, returns, covariance entries are `rust_decimal::Decimal`. Matrix inversion via Gaussian elimination in `Decimal`. |
| **Read-adapter over portfolio** | `PortfolioState::from_portfolio(portfolio, marks, as_of)` builds optimization input from the portfolio aggregate. |
| **Deterministic `optimize()`** | Same inputs → same outputs, byte-for-byte. |

---

## 2. Phase 1 — Implemented Capabilities

### `AllocationObjective`

| Variant | Formula | Meaning |
|---------|---------|---------|
| `MeanVariance` | Maximize `(μᵀw − r_f) / √(wᵀΣw)` | Markowitz tangency portfolio (max Sharpe); box constraints enforced by projected-gradient Sharpe ascent |
| `RiskParity` | Equal risk contribution `wᵢ(Σw)ᵢ` across instruments | Equal risk (damped fixed point with per-iterate exact projection) |
| `Hrp` | Hierarchical Risk Parity | Correlation-distance single-linkage dendrogram → quasi-diagonalization → recursive-bisection risk allocation (pure `Decimal`) |
| `BlackLitterman` | `((τΣ)⁻¹ + PᵀΩ⁻¹P)⁻¹·((τΣ)⁻¹π + PᵀΩ⁻¹q)` | View-blended posterior; prior `π = τ·Σ·w_mkt` reverse-optimized from benchmark weights |

Phases 2–4 (Hrp, Black-Litterman, discrete/whole-share allocation) were
declared-but-`NotImplemented` after Phase 1 and are **implemented** since plan
0003 (`tantra-ledger` commit `9f8ec22`, 2026-11-13).

### `Constraint::WeightBounds`

| Field | Type | Meaning |
|-------|------|---------|
| `instrument` | `InstrumentId` | Target instrument |
| `min` | `Decimal` | Minimum weight |
| `max` | `Decimal` | Maximum weight |

Box bounds are enforced by exact projection onto the bounded simplex
(`project_box_simplex` water-fills `{min ≤ w ≤ max, Σw = 1}`), replacing the
Phase 1 clip-and-renormalize heuristic.

### `PortfolioState` — read-adapter

| Method | Meaning |
|--------|---------|
| `from_portfolio(portfolio, marks, as_of)` | Build from `tantra-ledger-portfolio` aggregate; universe = union of held positions |
| `current_weights` | Market-value-normalized weights |
| `with_expected_returns(returns)` | Attach expected return estimates |
| `with_covariance(cov)` | Attach covariance matrix |

### `TargetWeights` — auditable output

| Field | Type | Meaning |
|-------|------|---------|
| `as_of` | `DateTime<Utc>` | Optimization timestamp |
| `objective` | `AllocationObjective` | Objective used |
| `weights` | `BTreeMap<InstrumentId, Decimal>` | Target weights (sum to 1 within decimal tolerance) |

Custom JSON serialization as a sorted array of `{instrument, weight}` entries.

### `optimize()` — pure entry point

Solves each objective in exact `Decimal` and enforces the box by exact
projection onto the bounded simplex (see above). `allocate_discrete(target,
equity, prices, lot_sizes)` additionally maps the continuous `TargetWeights`
onto whole-lot `Quantity`s via iterative largest-remainder rounding.

---

## 3. Usage Example

```rust
use tantra_ledger_allocation::{optimize, AllocationObjective, Constraint, PortfolioState};
use tantra_ledger_portfolio::{AccountState, Price, Money};
use rust_decimal::Decimal;

// 1. Build PortfolioState from the portfolio aggregate
let state = PortfolioState::from_portfolio(&account_state, &marks, as_of)
    .with_expected_returns(&expected_returns)
    .with_covariance(&covariance);

// 2. Define constraints
let constraints = vec![
    Constraint::WeightBounds { instrument: "RELIANCE.NSE".parse().unwrap(), min: dec!("0.05"), max: dec!("0.25") },
    Constraint::WeightBounds { instrument: "TCS.NSE".parse().unwrap(), min: dec!("0.10"), max: dec!("0.30") },
];

// 3. Optimize
let target_weights = optimize(&state, AllocationObjective::MeanVariance, &constraints)?;

for (instrument, weight) in &target_weights.weights {
    println!("{}: {}", instrument, weight);
}
```

---

## 4. Tests

32 tests in `tests/optimize_tests.rs` cover: mean-variance tangency (exact and
box-constrained), risk-parity equal risk contribution, HRP inverse-variance
goldens (2- and 3-asset diagonals, correlated 2-asset), Black-Litterman
no-views → market weights + view-blend golden + serde round-trip, exact
bounded-simplex projection, discrete whole-lot allocation, `PortfolioState`
construction, `TargetWeights` JSON serialization, and decimal-exactness
invariants.

`cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, and
`cargo test --workspace` all pass.

---

## 5. Objectives (all phases implemented)

| Phase | Objective | Status |
|-------|-----------|--------|
| Phase 1 | MeanVariance, RiskParity | ✅ Implemented |
| Phase 2 | Hrp (Hierarchical Risk Parity) | ✅ Implemented (plan 0003) |
| Phase 3 | BlackLitterman | ✅ Implemented (plan 0003) |
| Phase 4 | Discrete / whole-share allocation | ✅ Implemented (plan 0003) |

---

## 6. Related Documents

* **[Architecture Layers & Topology](architecture_layers.md)** — Full `tantra-ledger` bounded context: OMS, portfolio, journal, allocation, performance.
* **[Ledger Performance](ledger_performance.md)** — Trade-performance journal (sibling crate).
* **[Platform Conformance Matrix](../conformance_matrix.md)** — Implementation status badge.
