# Indian Cost Model & Statutory Charges

Trading costs in Indian markets represent a critical performance factor in quantitative strategy development. A delivery equity round-trip costs approximately **0.14% per side** once Securities Transaction Tax (STT), stamp duty, exchange transaction fees, SEBI turnover fees, GST, and brokerage are accounted for. At that level, a strategy trading frequently requires a significant gross alpha edge just to break even after statutory frictions.

`vyapaar-market` (and Python `vyapaar.markets.india.costs`) models every statutory and exchange cost component separately so that strategy sensitivity and tax drag can be measured with microsecond determinism.

*Last verified: Rates reflect the Finance Act 2026 statutory updates, effective 1 April 2026.*

---

## 1. The Six Cost Components

| Component | Rate | Charged on | Side |
| :--- | :--- | :--- | :--- |
| **STT** | Varies by market segment (see schedule below) | Transaction turnover | Buy & Sell (Delivery), Sell-only (Intraday & F&O) |
| **Exchange Transaction Charges** | ~0.00325% (NSE equity turnover) | Total turnover | Both sides (Buy & Sell) |
| **SEBI Turnover Fee** | ₹10 per crore (0.0001%) | Total turnover | Both sides (Buy & Sell) |
| **Stamp Duty** | 0.003% (₹300 per crore, state-apportioned) | Turnover value | Buy side only |
| **GST** | 18% | Brokerage + Exchange fees + SEBI fee | Both sides |
| **Brokerage** | Broker-defined (e.g. ₹20 flat or bps) | Per order or % of turnover | Both sides |

---

## 2. STT — Rates Schedule (Finance Act 2026)

The Finance Act 2026 raised STT on futures and options contracts:

| Transaction Segment | STT Rate | Charged Side |
| :--- | :--- | :--- |
| **Equity Delivery (CNC)** | 0.10% (10 bps) | Buy **and** Sell |
| **Equity Intraday (MIS)** | 0.025% (2.5 bps) | Sell side only |
| **Equity / Index Futures** | 0.05% (5 bps) | Sell side only |
| **Equity / Index Options (Premium)** | 0.15% (15 bps) | Sell side only (option writer) |
| **Equity / Index Options (Exercised)** | 0.15% of intrinsic settlement value | Buy side only (exerciser) |
| **Sale of Equity Mutual Fund Units** | 0.001% (0.1 bps) | Sell side only |

---

## 3. Detailed Statutory Fee Rules

### Exchange Transaction Charges
- **NSE Cash Equity**: 0.00325% of turnover.
- **NSE Equity Options**: 0.035% of premium turnover.
- **NSE Equity Futures**: 0.0019% of contract turnover.
- **BSE Rates**: Slight differences per liquidity schedule.
Charged symmetrically on **both** sides of execution.

### SEBI Turnover Fee
SEBI levies a turnover fee of **₹10 per crore** (0.0001%) on non-debt market transactions and ₹2.5 per crore on debt instruments. This fee attracts 18% GST.

### Stamp Duty
Stamp duty is an Indian state-level revenue duty charged on the **buy side only**:
- Delivery: 0.003% (₹300 per crore).
- Intraday & F&O: 0.002% (₹200 per crore).
- Transferred directly to state governments; **no GST** is levied on stamp duty.

### Goods & Services Tax (GST)
GST is applied at **18%** strictly to the taxable financial services stack:
$$\text{GST} = 18\% \times (\text{Brokerage} + \text{Exchange Charges} + \text{SEBI Fee})$$
GST is **never** applied to STT or Stamp Duty.

---

## 4. Rust Engine API (`vyapaar-market`)

`vyapaar-market` separates *rates* configuration from deterministic *application*:

```rust
use vyapaar_market::{CostModel, SttRates, Segment, Side};
use rust_decimal_macros::dec;

// 1. Initialize statutory STT rates (in basis points)
let stt = SttRates::new(
    /* delivery_buy_bps  */ 10.0,
    /* delivery_sell_bps */ 10.0,
    /* intraday_sell_bps */ 2.5,
    /* options_sell_bps  */ 15.0,
);

// 2. Configure comprehensive cost model
let model = CostModel::new(
    stt,
    /* brokerage_bps  */ 3.0,
    /* exchange_bps   */ 0.325,
    /* gst_pct        */ 18.0,
    /* stamp_bps      */ 0.3,
    /* sebi_bps       */ 0.01,
);

// 3. Compute deterministic fill breakdown
let breakdown = model.compute(
    /* price   */ 2450.50,
    /* qty     */ 100.0,
    /* side    */ Side::Buy,
    /* segment */ Segment::EquityDelivery,
);

println!("Total transaction fees: ₹{}", breakdown.total());
```

---

## 5. Python Statutory Costs (`vyapaar`)

In Python backtests, statutory costs are calculated using the built-in NSE cost model:

```python
from vyapaar.markets.india.costs import nse_equity_delivery_fill_cost
from vyapaar.domain.order import OrderSide

cost = nse_equity_delivery_fill_cost(OrderSide.BUY, quantity=100.0, price=2500.0)
print(f"STT: ₹{cost.stt:.2f}, Stamp Duty: ₹{cost.stamp_duty:.2f}, GST: ₹{cost.gst:.2f}")
```

---

## 6. Cost Sensitivity Analysis

Because friction can turn a backtest with nominal edge into a losing strategy, Vyapaar supports parameter sweep sensitivity analysis:

```python
from vyapaar.backtest import cost_sensitivity

sweep = cost_sensitivity(
    strategy=NiftyMomentumStrategy(),
    universe="nifty50",
    brokerage_range=(0.0, 50.0, 10), # ₹0 to ₹50 per executed order
)
```

If a strategy's Sharpe ratio crosses below zero before ₹20/order, it lacks execution viability in retail broker accounts.
