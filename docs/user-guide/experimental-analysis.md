# Experimental-Analysis Workbench

The **Experimental-Analysis** tab in `tantra-ui-web` is a multi-asset quantitative
research workbench (`NSE`, `NFO`, `BSE`, `MCX`, `CDS`, equities, ETFs, FX, and
commodities). Every calculation runs in exact `rust_decimal::Decimal` arithmetic
via `tantra-market-finance` (`/api/v2/experimental-analysis/*`) with **zero
fabrication**: when 5-minute bars, live option quotes, or archived events are
absent for a symbol/date window, the page states so explicitly rather than
synthesizing data.

This guide explains how to read every control, KPI, chart, and study tab—plus
dedicated playbooks for the **Contrarian (Mean-Reversion) Strategy** and
structuring **Iron Condors & Condor Wings**.

---

## 1. Left Control Rail: How Inputs Shape Every Number

Always check the header strip (`Instrument`, `Range`, `Periods`, `Source`) and
the left control rail before interpreting any metric. Changing any setting
recomputes the active study cleanly.

### Feed & Lakehouse Card

- **Connected / Historical / Offline**: Shows whether a live broker adapter is
  streaming (`Live Feed`) or the workbench is evaluating archived Lakehouse v3
  bars (`Historical`).
- **Indexed Symbols & F&O Contracts**: Total instruments and derivative
  contracts loaded by `tantra-runtime`.

### Study Family (`Application Mode`)

1. **`Period & Expiry Returns`** *(default)* — Unlocks all 13 horizontal study
   tabs (Returns, Outliers, Intraday, Gaps, 5-Day, Cycle Progress, Correlation,
   Options Overlay, Strike Lab, ORB, Forecasting, Rebalance, AI Assistant).
2. **`Buyback / Corporate Event Study`** — Switches the canvas to an aligned
   `[-20d, +20d]` Cumulative Abnormal Return (`CAR`) study around corporate
   actions and buybacks.
3. **`Earnings / Macro Reaction Study`** — Switches to a `[-20d, +20d]`
   event-window study with a toggle between **Earnings / Filings** and
   **Macro Calendar** (filterable by `All`, `IN`, or `US`).

### Asset Class Universe & Analysis Period Schedule

| Asset Class | Default Period | Other Supported Schedules |
| :--- | :--- | :--- |
| **Indices** | `Weekly Expiry` | `Week +1 Carry`, `Monthly Expiry`, `Daily` |
| **F&O Stocks** | `Monthly Expiry` | `Weekly Expiry`, `Calendar Monthly`, `Daily` |
| **ETFs / Equities** | `Calendar Monthly` | `Calendar Weekly` (Mon–Fri), `Daily` |
| **Forex** | `Front-Month Cycle` | `Calendar Weekly`, `Daily` |
| **Commodities** | `MCX Expiry Cycle` (rolls on the 20th, holiday-adjusted backward) | `Calendar Monthly`, `Daily` |

!!! note "NSE/SEBI September 3, 2025 Weekly-Expiry Regime Cutover"
    When studying Indian `Indices` or `F&O Stocks` on `Weekly Expiry` or
    `Monthly Expiry` across `2025-09-03`, the period slicer automatically aligns
    historical boundaries to the exchange calendar in effect on each date:

    - **NIFTY 50 / Generic NSE**: `Fri→Thu` before `2025-09-03`, bridged by
      `Fri Aug 29 → Tue Sep 2, 2025`, then `Wed→Tue` from `2025-09-03` onward.
    - **SENSEX**: `Mon→Fri` (pre-2025), `Wed→Tue` (`2025-01-01` to `2025-09-02`),
      `Fri→Thu` from `2025-09-03` onward.
    - **BANKNIFTY / FINNIFTY / MIDCPNIFTY**: Respects each index's historical
      weekday switches and trading-holiday backward adjustments.

### Calculation Type

| Mode | Formula | What it measures |
| :--- | :--- | :--- |
| **`OC` (Open to Close)** | `(C_end - O_start) / O_start × 100` | Pure intra-cycle directional move from cycle open to cycle close; excludes gaps between cycles. |
| **`H-L` (High to Low)** | `(max(H) - min(L)) / O_start × 100` | Total period trading range magnitude (`≥ 0%`). Use for volatility sizing, straddle/wing width calibration, and range expectations—**not** directional bias. |
| **`CC` (Close to Close)** | `(C_end - C_prev) / C_prev × 100` | Gap-inclusive holding return from prior cycle close to current cycle close. Best for continuous futures/spot carry, ETFs, and FX. |

### F&O Spread, Roll-Basis & Statutory Friction

- **`Gross Spot`** *(default)*: Unadjusted underlying bar returns.
- **`Include Roll Basis`**: Adds `Roll Basis (bps)` per period (`OC`/`CC`) to model
  positive futures contango carry or backwardation drag.
- **`Net After Spread & Costs`**: Applies `Roll Basis (bps)` **and** deducts
  `Spread (bps)` plus (when **Statutory Costs (STT/Exch/GST)** is toggled on)
  segment-exact Indian round-trip charges (`NFO` futures STT/stamp/exchange/SEBI
  + 18% GST, `MCX` CTT, `CDS`, or cash equity delivery).

When friction is active, the **F&O Spread & Roll-Basis Friction Reconciliation**
card compares **Gross → Net Avg**, **Gross → Net Sharpe**, **Gross → Net Profit
Factor**, per-cycle basis/fee bps, and **Cumulative Net Delta**. Downstream
streaks, Markov transitions, percentiles, and outliers automatically recompute on
the net series so you can spot strategies whose apparent edge disappears under
real execution friction.

---

## 2. Tab-by-Tab Interpretation Guide

### Tab 1 — Returns Analysis

1. **Sub-Cycle Carrying Mode**
   - `Current Period`: Evaluates each single cycle `P_k`.
   - `Period +1 Carry`: Evaluates overlapping two-cycle carry
     (`P_k.open → P_{k+1}.close`), showing whether holding one
     extra cycle improves or dilutes risk-adjusted payoff.
2. **3×3 Return KPI Grid**
   - **Average Return, Max Gain, Max Loss, Return Std Dev**: Arithmetic mean,
     best/worst single cycle, and sample standard deviation (`n - 1`).
   - **Positive / Negative Periods**: Directional win rate and inverse share
     (exact `0%` neutral cycles are reported separately).
   - **Sharpe Ratio & Sortino Ratio**: Computed per evaluated period as
     `μ / σ` and `μ / σ_downside` (MAR = `0%`). Because
     these are per-period ratios, compare Sharpe/Sortino across symbols under the
     *same* schedule (`Weekly` vs `Weekly`, not `Weekly` vs `Monthly`). When
     **Sortino > Sharpe**, gains come with positive right-tail skew; when
     **Sortino < Sharpe**, downside tails dominate.
   - **Profit Factor**: `Σ r+ / |Σ r-|`. Values `< 1.0` indicate net
     expectancy loss; `1.3–1.8+` after friction indicates a durable positive
     distribution.
3. **Return Trajectory Chart (Lollipop / Bars + SMA)**
   - Green upward stems/bars mark positive cycles, red downward mark negative
     cycles, with terminal circles scaled by move magnitude.
   - Toggle **Show Moving Average** (`MA Window` `5–50`, default `20`) to see
     whether recent period returns are trending above/below their rolling mean or
     mean-reverting around `0%`.
   - When the date window crosses `2025-09-03` on Indian derivatives, a vertical
     dashed marker highlights the **Sep 3, 2025** expiry regime cutover.
4. **Streak Analysis (Consecutive Directional Runs)**
   - Exact `0%` neutral periods are excluded before grouping contiguous `r > 0`
     (`Positive`) and `r < 0` (`Negative`) runs.
   - **Current Streak Banner** shows the active direction, consecutive run
     length, and compounded cumulative return so far.
   - **Diverging Streak Lengths Timeline**, **Distribution of Streak Lengths**,
     **Positive/Negative Streak Statistics** (`Most Common`, `Median`, `Std Dev`),
     and the sortable **Streak Details** table let you see immediately when the
     current run is stretched well beyond normal length (e.g., a 5-period run
     when the median streak is 1–2 periods).
5. **Markov Chain Transition Analysis (6-State Streak Engine)**
   - Streaks are bucketed into six states:
     `Short + (1-2)`, `Med + (3-4)`, `Long + (5+)`,
     `Short - (1-2)`, `Med - (3-4)`, `Long - (5+)`.
   - **6×6 Transition Matrix**: Each row (`Current State (Obs)`) gives the
     empirical probability (%) of the *next completed streak* landing in each
     column. The highlighted row matches the currently active streak state.
   - **Current Streak Probability Prediction**: Aggregates row probabilities into
     **Next Streak Positive** vs **Next Streak Negative** and highlights the
     single **Strong Prediction**.
   - **Steady-State Equilibrium Distribution**: Long-run stationary state
     frequencies (`π = π P`) after repeated transitions.

   !!! warning "Watch Observation Counts `(Obs)`"
       Rare rows such as `Long + (5+)` or `Long - (5+)` may only have `2–6`
       historical observations in a 3-year sample. Always check `(Obs)` before
       treating an 80% or 100% matrix cell as law-of-large-numbers certainty.

6. **Return Percentiles (`P99` down to `P1`)**
   - Displays linear-interpolated empirical quantiles (`99th`, `95th`, `75th`,
     `50th`, `25th`, `5th`, `1st`). Compare `|P5|` vs `P95` and `|P1|` vs `P99`
     for tail asymmetry (crash risk vs melt-up skew).
7. **Return Distribution (`16-Bucket` & `Granular 10-bps`) + Spot Reference Card**
   - Anchors every return bucket (`> +5%` down to `< -5%`) to **Current Period
     Reference Price**, showing exact **Spot Price Ranges** (`ref_price × (1 + r/100)`),
     cumulative **Percentile Range**, and **Probability** band.
   - Expand **Granular Distribution (10 Basis Points)** to inspect exact `0.1%`
     modes and pinning zones.
8. **Probability-Based Levels (Easy Reference)**
   - Answers: *"What is the empirical probability that price finishes **ABOVE**
     this target by period end?"*
   - Read carefully:
     - **`90%` / `95%` / `99%` ABOVE** = low **downside** prices (only `10% / 5% / 1%`
       of historical periods closed *below* them) → **support / short-Put wing zone**.
     - **`50%` ABOVE** = historical **median** finish.
     - **`20%` / `10%` ABOVE** = high **upside** prices (only `20% / 10%` of
       historical periods closed *above* them) → **resistance / short-Call wing zone**.
9. **Green vs Red Periods Comparison**
   - Side-by-side count, share, mean, median, std dev, extreme move, and
     **Magnitude Empirical PDF** (`0–1%`, `1–2%`, ..., `> 5%`) comparing whether
     down periods are sharper/wider than up periods.
10. **Conditional Forward Accordions (`|Return| ≥ threshold`)**
    - Shows average/median next-period return and **Pos Win Rate** immediately
      following large positive surges (`r ≥ +τ`) vs large negative selloffs
      (`r ≤ -τ`), for both the active cycle and `Period +1 Carry`.
11. **Period Returns Table & Daily OHLC Analysis**
    - Filterable period ledger (`Start Date`, `End Date`, `Entry`, `Exit`,
      `Return %`, `Regime`), 7-KPI daily strip, embedded candlestick `ChartCanvas`,
      and paginated `Daily OHLC Data` with `Dividends` and `Splits`.

---

### Tab 2 — Outliers & Global Events

- **Probability Boundary Coverage (`50%–99%`, default `90%`)**: Sets symmetric
  empirical fences at the `(100 - C)/2` and `(100 + C)/2` percentiles (for `90%`
  coverage, outside `[P5, P95]`).
- **Abraham Wald Survivability Scatter Plot**: Muted dots inside the dashed
  boundaries are routine noise; highlighted green/red circles outside the fences
  are structural outliers. Click any dot or any row in the **Outlier Periods
  Table** (sorted by `|Return %|` descending) to populate **Historical Global
  News & Events** and query archived macro/news/filings across `[start - 2d,
  end + 1d]`.

---

### Tab 3 — Intraday Movement

- Slices `5m` bars into **15-minute** or **Hourly** IST clock buckets (`09:15`,
  `09:30`, ...).
- **Avg Range % / Max Range % / Avg |O-C| % / Avg Volume**: Identifies peak
  liquidity/volatility windows (typically opening `09:15–09:45` and closing
  `14:45–15:15`).
- **HOD Hits / LOD Hits**: Counts how often the session High-of-Day (`Peak HOD
  Clock`) and Low-of-Day (`Peak LOD Clock`) printed in each slot—critical for
  timing entries after morning whipsaws settle.

---

### Tab 4 — Gap Up / Gap Down

- Compares overnight gap `Gap = (O_t - C_{t-1}) / C_{t-1}` against
  intraday open-to-close move `(C_t - O_t) / O_t` and **Fill Rate %** (did the
  session's High/Low touch prior close `C_{t-1}`?).
- Inspect the **8 Gap Buckets** (`< -2.0%` to `> +2.0%`):
  - **High `Fill Rate %` + opposite-sign `Avg Intraday O→C`** (e.g., `+0.5% to +1.0%`
    gap with `70%` fill rate and negative `O→C`) signals a **fade/mean-reversion**
    gap.
  - **Low `Fill Rate %` + same-sign `Avg Intraday O→C`** signals a **breakaway**
    gap where fading is dangerous.

---

### Tab 5 — 5-Day Move Analysis

- Tracks rolling 5-trading-day returns (`P99..P1`, `Win Rate`, `σ`) alongside two
  non-overlapping exhaustion cards:
  - **Post-Surge Next 5D Expectancy** (after 5-day gain `≥ +τ`)
  - **Post-Selloff Next 5D Expectancy** (after 5-day drop `≤ -τ`)
- Negative post-surge or positive post-selloff expectancy flags multi-day
  overshoot exhaustion.

---

### Tab 6 — Cycle Progress (0–100%)

- Normalizes every multi-bar cycle onto `0% → 100%` progress in 10% deciles,
  plotting `P10–P90`, `P25–P75` (IQR), `Median (P50)`, and `Mean`.
- Reveals *intra-cycle timing*: e.g. whether drift arrives in the first `20–40%`
  of the expiry and stalls (`60–100%`), or sells off mid-cycle and pins/reverses
  into `100%` expiry.

---

### Tab 7 — Cross-Asset Correlation

- Pick `2–12` instruments and a **Benchmark** plus **Rolling Window** (`5–250`
  sessions).
- **Pearson vs Spearman Rank Matrix**: Use **Spearman** to verify whether
  co-movement holds without single-day crash outliers skewing Pearson.
- **Pair Beta**, **Latest Raw Spread**, and **Relative Perf Spread (% pts)** with
  the dual **Rolling Correlation & Relative Spread** chart identify correlation
  breakdowns and pair-spread divergences.

---

### Tab 8 — Options Overlay & Spreads

- Simulates five strategies anchored by `Short Prob %` (`55–98%`) and `Wing Width %`
  (`0.5–15%`): **Covered Call**, **Bull Call Spread**, **Bear Put Spread**,
  **Iron Condor**, and **Calendar Spread**.
- Shows whether pricing comes from **Live Chain** bid/ask depth or **Empirical
  Unquoted Mode** (`Bid/Ask = —` when offline; zero fabricated quotes).
- Compare **Net Cycle Credit** vs **Friction Drag / Cycle** (bid-ask spread +
  statutory taxes), **Probability of Profit (PoP)**, **Cycle Bounds (Max P/L)**,
  and **Overlay Net Cum / Max Drawdown** against **Buy & Hold**. See
  [Section 4](#4-iron-condor-condor-wings-guide) for full Iron Condor & wing
  sizing guidance.

---

### Tab 9 — Expiry Strike Lab

- Compares **Empirical Realized Vol (RV)** (annualized from historical period
  returns) against **Quoted IV Proxy (ATM)** (from live option mid-prices when
  connected) to report **Vol Risk Premium (`IV − RV`)**:
  - **`IV − RV > 0`**: Option sellers collect an empirical volatility risk
    premium (favors Iron Condors / Covered Calls / Credit Spreads).
  - **`IV − RV < 0`**: Options are cheap relative to realized moves (favors
    defined-risk debit spreads or staying flat).
- **Strike Ladder**: Lists `CE`/`PE` strikes, `Moneyness %`, empirical
  `Exceed Prob %`, live `Bid`/`Ask`/`Mid`, `Spread bps`, `Liquidity` badge
  (`tight ≤ 40 bps`, `moderate ≤ 120 bps`, `wide > 120 bps`, `unquoted`), and
  `OI`.

---

### Tab 10 — 15m ORB Flip Backtest

- Simulates Opening Range Breakout (`OR (m)` `5–60`, `Max Flips` `0–10`, `SL %`,
  `Target %`) over `5m` intraday bars with left-rail spread + statutory fee
  deductions per leg.
- Always compare **Gross Sum** vs **Spread+Fee Drag** vs **Net Sum** and inspect
  `exit_reason` (`target`, `stop_flip`, `stop_max_flips`, `eod`) in the trade
  ledger. Tight `OR` windows with high `Max Flips` frequently look profitable
  gross while bleeding negative net due to flip friction.

---

### Tab 11 — Forecasting

- Conditions historical forward paths (`T+1` through `T+N`, `2–12` periods) on
  the current **Markov Streak State** and trailing 5-period **Volatility Regime**
  (`Low ≤ P33`, `Normal`, `Elevated ≥ P67`).
- Automatically discloses its **Conditioning Tier** (`Exact Markov + Vol Regime`,
  or graceful fallback to `Markov State Match` → `Direction Fallback` →
  `Unconditional Pool` when `< 5` analogs exist).
- Read the **Quantile Target Price Ladder** (`P10` downside risk, `P50` median
  target, `P90` upside tail, `Win %`) alongside the **Closest Historical Analog
  Episodes** before sizing any directional or contrarian trade.

---

### Tab 12 — F&O / Index Rebalance & Event Modes

- Aligns historical events (`F&O Inclusion / Exclusion`, `Buyback / Corporate
  Actions`, `Earnings / Filings`, or `Macro Calendar`) on `T=0` across a
  `[-20d, +20d]` trading-day window.
- **Gold `CAR[-20d, +20d]` curve + `AAR` daily bars + `Avg Vol Surge Ratio`**:
  - Rising `Pre-Drift [-20d, -1d]` followed by flat/negative `Post +5d/+20d`
    flags classic *"buy the rumor, sell the news"* pre-positioning.
  - Persistent drift in `Post +5d` and `Post +20d` flags post-event
    re-rating/continuation.
  - Use **Benchmark AR** to strip broad market beta (`raw_return - benchmark`).

---

### Tab 13 — AI Study Assistant

- Snapshots your active KPIs, strongest Markov transition, and outlier bounds and
  provides one-click prompts into `ChatRail` backed by the
  `experimental_study_summary` and `historical_outlier_news` tools.

---

## 3. Contrarian (Mean-Reversion) Strategy Playbook

The original demo highlighted a **Contrarian (mean-reversion / fade-the-extreme)**
workflow—fading stretched streaks, `>2σ` tail shocks, and overextended overnight
gaps instead of chasing breakouts. Every signal needed to validate and size that
strategy is built directly into this page.

```
1. Detect Stretch          2. Verify Edge Historically       3. Structure & Size Risk
──────────────────         ──────────────────────────       ────────────────────────
• Long streak (5+)   ──▶   • 6×6 Markov Matrix         ──▶  • Prob Levels (80–90%)
• Outlier (>90–95%)  ──▶   • Forward Conditional |r|≥τ ──▶  • Options Overlay / Condor
• Exhausted 5D move  ──▶   • 5D Post-Surge / Drop Exp. ──▶  • Strike Lab (IV − RV)
• Extended Gap Open  ──▶   • Gap Fill % & HOD/LOD Slot ──▶  • Net-of-Friction Check
```

### Signal 1: Streak Exhaustion Fade (Tab 1 — Streaks + Markov)

1. Check the **Current Streak** banner and **Distribution of Streak Lengths**. A
   streak becomes a contrarian candidate once its length exceeds the instrument's
   **Median Length** and approaches **`Med (3-4)`** or **`Long (5+)`**.
2. Look up that exact row in the **6×6 Markov Transition Matrix** (checking
   `(Obs)` is meaningful, e.g. `≥ 10`):
   - **Contrarian signal**: `Next Streak Opposite` is significantly above `50%`
     (e.g., after `Long + (5+)` or `Med - (3-4)`, opposite-side probability is
     `60%+` and `Strong Prediction` points to reversal).
   - **Do NOT fade**: If the current `Short/Med` row shows high persistence into
     longer streaks and **Steady-State** strongly skews to one trend direction,
     wait for exhaustion rather than stepping in front of trend momentum.

### Signal 2: Tail Shock & 5-Day Overshoot Fade (Tabs 1, 2 & 5)

1. In **Tab 2 (`Outliers & Global Events`)**, set **Probability Boundary Coverage**
   to **`90%`** or **`95%`** (rough `~1.65σ–2σ` empirical tail). Confirm whether
   the latest period is a tagged `Upside Outlier` or `Downside Outlier`.
2. Click the outlier point and fetch **Historical Global News & Events**.
   Contrarian fades work best on *positioning/liquidity overshoots*; be cautious
   fading structural regime breaks (e.g., major central-bank pivots or earnings
   guidance shocks).
3. Verify empirical mean-reversion in two places:
   - **Tab 1 → Conditional Forward (`|Return| ≥ τ`)**: Look at `After Large
     Positive Period` (`Mean/Median Next < 0`, low `Pos Win Rate`) or `After
     Large Negative Period` (`Mean/Median Next > 0`, high `Pos Win Rate`). Check
     both `Current Period` and `Period +1 Carry` to see whether reversion happens
     immediately or over a two-cycle horizon.
   - **Tab 5 → 5-Day Move Analysis**: Confirm `Post-Surge Next 5D Expectancy` is
     negative (for fading rallies) or `Post-Selloff Next 5D Expectancy` is
     positive (for buying washouts).

### Signal 3: Gap-Fill Contrarian Fade (Tabs 3 & 4)

1. In **Tab 4 (`Gap Up / Gap Down`)**, locate today's gap size inside the **8 Gap
   Buckets**.
2. A contrarian gap-fade setup requires **both**:
   - High **`Fill Rate %`** (historically `≥ 65–70%`), and
   - Opposite-sign **`Avg Intraday O→C`** (negative after gap-ups, positive after
     gap-downs).
3. Cross-check **Tab 3 (`Intraday Movement`)** for `Peak HOD Clock` / `Peak LOD
   Clock` and opening `15m` range volatility so your fade entry waits for the
   initial `09:15–09:30` spike to exhaust rather than getting stopped out in the
   first 5 minutes.

### Executing & Stress-Testing the Contrarian Trade (Tabs 8, 9, 11 & Rail)

- **Spot / Futures vs Options Expression**:
  - Check **Tab 11 (`Forecasting`)** under the active `Markov + Vol Regime` to
    read the `T+1` `P10` tail risk against the `P50` median bounce target.
  - When **Tab 9 (`Expiry Strike Lab`)** shows **`IV − RV > 0`**, contrarian
    traders often harvest overpriced panic/euphoria via defined-risk credit
    spreads or **Iron Condors** (**Tab 8**) placed at the `80%–90%` levels from
    **Probability-Based Levels** (`tight` or `moderate` liquidity tiers only).
- **Mandatory Friction Check**: Enable **Net After Spread & Costs** + **Statutory
  Costs** in the left rail before trusting any contrarian edge—high-frequency
  fades (especially daily or gap fades) lose rapidly when `Spread (bps)` and
  STT/GST exceed `Average Return`.

---

## 4. Iron Condor & Condor Wings Guide

An **Iron Condor** (`Tab 8 → Strategy: Iron Condor`) is a defined-risk, 4-leg
range-bound credit structure: you sell an OTM Call and an OTM Put around spot
to collect premium, and simultaneously buy further-OTM **protective wings** to cap
tail loss.

### How the Workbench Places Short Strikes & Wings

```
  Long Put Wing         Short OTM Put          Spot          Short OTM Call         Long Call Wing
     BUY PE                SELL PE              ●               SELL CE                BUY CE
 ◀────────────── Wing Width % ──────────────▶◀── Short Prob % ──▶◀─── Wing Width % ──────────▶
  Caps downside       Empirical Q(100-p)                    Empirical Q(p)         Caps upside
   crash loss         (e.g. 20% = P20)                      (e.g. 80% = P80)        melt-up loss
```

1. **Short Strikes (`Short Prob %`, range `55–98%`)**
   - `Short OTM Call` (`SELL CE`) is anchored at the `p`-th empirical return
     quantile (`Q(p)`, floored at `+0.5%`), snapped to the exchange strike step
     (e.g., `50` pts for NIFTY, `100` pts for BANKNIFTY/SENSEX).
   - `Short OTM Put` (`SELL PE`) is anchored symmetrically at the `(100 - p)`-th
     empirical return quantile (`Q(100 - p)`, capped at `-0.5%`).
   - Example: `Short Prob % = 80` places the short Call near Tab 1's **`20%
     ABOVE`** level and the short Put near **`80% ABOVE`**—meaning roughly `60%`
     of historical cycles stayed inside `[short_put, short_call]` at expiry,
     while each individual short strike had only a `~20%` historical touch/breach
     rate.
2. **Condor Wings (`Wing Width %`, range `0.5–15.0%`)**
   - `Long Call Wing` (`BUY CE`) sits at `short_call_strike + max(spot × wing_width / 100, strike_step)`.
   - `Long Put Wing` (`BUY PE`) sits at `short_put_strike - max(spot × wing_width / 100, strike_step)`.
   - Wings turn an unlimited-risk short strangle into a **bounded-loss** structure:
     - **Max Profit / Cycle**: `Net Cycle Credit` after 4-leg spread & statutory
       fees (`net_after_friction_pct`).
     - **Max Loss / Cycle**: `net_after_friction_pct - max(call_wing_width_pct, put_wing_width_pct)`.
     - **Cycle Gross P/L**: `net_premium_pct - call_loss - put_loss`, where each
       side's intrinsic loss is capped once spot moves past its protective wing.

### Tuning Condor Wings Using the Rest of the Workbench

| Decision | Where to Look on the Page | What to Check |
| :--- | :--- | :--- |
| **1. Should I sell a Condor at all?** | **Tab 9 (`Expiry Strike Lab`)** | Check **Vol Risk Premium (`IV − RV`)**. Run Iron Condors primarily when **`IV − RV > 0`** (options overprice realized moves). Avoid when `IV − RV < 0` or ahead of a high-`Vol Surge Ratio` catalyst in **Tab 12**. |
| **2. Where to place Short Strikes?** | **Tab 1 (`Probability-Based Levels` + `Green vs Red`)** & **Tab 9 (`Strike Lab`)** | Compare `P80/P90` upside vs `P20/P10` downside. If **Red** periods have fatter left tails (`|P5| > P95`), widen your put buffer (`Short Prob %` `80–90%`). On live chains, verify both short strikes sit in **`tight` (`≤ 40 bps`)** or **`moderate` (`≤ 120 bps`)** liquidity tiers. |
| **3. How wide should Condor Wings be?** | **Tab 1 (`H-L` mode & `P99/P1`)** & **Tab 2 (`Outliers`)** | Compare `P95` / `P99` tail moves and `H-L` range against `Wing Width %` so protective wings cap worst-case drawdown within risk limits (see narrow vs wide tradeoff below). |
| **4. Can the 4 legs survive real fees?** | **Tab 8 (`Friction Drag / Cycle` + `Equity Curve`)** | Statutory Indian options charges include sell-side STT (`0.1%` on premium), buy-side stamp (`0.003%`), exchange + SEBI + 18% GST, plus a 4-leg execution drag. Always verify **Overlay Net Cum** beats zero with tolerable **Overlay DD** vs **B&H DD**. |

### Narrow Wings vs Wide Wings Tradeoff

- **Tight Wings (`0.5% – 1.5%`)**:
  - **Pros**: Smallest `Max Loss` per breached cycle, lowest margin footprint,
    protects tightly against `Tab 2` crash/gap outliers.
  - **Cons**: You pay 4× leg spread + statutory taxes on a *small* **Net Cycle
    Credit**, so `Friction Drag / Cycle` can eat `30–60%+` of gross credit and
    turn **Overlay Net Cum** negative even with a high `Probability of Profit`.
- **Wide Wings (`2.5% – 6.0%+`)**:
  - **Pros**: Larger **Net Cycle Credit**, faster theta decay (because long
    wings cost much less relative to short strikes), and far lower friction
    ratio per rupee of credit.
  - **Cons**: Larger `Max Loss` when a `Tab 2` tail outlier (`> 95%`) slices
    through the wing—watch **Overlay DD** on the cumulative equity curve before
    widening further.
- **Combining Contrarian + Iron Condor**: After a **Contrarian Signal** (e.g., a
  `Long (5+)` streak exhausts or an `> 90%` outlier triggers an `IV − RV > 0`
  volatility spike), **Tab 6 (`Cycle Progress`)** often shifts toward mean
  consolidation. Entering an Iron Condor after the initial shock lets you
  harvest elevated implied volatility inside the `[short_put, short_call]` tent
  while keeping hard **Condor Wings** in place in case trend continuation runs
  further.

---

## 5. Common Interpretation Pitfalls

- **Confusing `H-L` with directional return**: `H-L` is `(High - Low) / Open`
  and is always `≥ 0%`. Switching to `H-L` makes every period green—use it for
  range/volatility budgets and wing sizing, then switch back to `OC` or `CC` for
  win rates, streaks, and directional levels.
- **Misreading `Probability-Based Levels` polarity**: `90%` in `Probability ABOVE
  Level` corresponds to a **lower** price (90% chance spot finishes *above* it),
  whereas `10%` corresponds to an **upper** price (10% chance spot finishes
  *above* it).
- **Over-tightening Condor Wings under real friction**: A `0.5%`-wide Iron
  Condor pays spread and statutory fees across **all four legs** (`SELL CE`,
  `BUY CE`, `SELL PE`, `BUY PE`). Check **Friction Drag / Cycle** against **Net
  Cycle Credit** so transaction costs do not consume your theta edge.
- **Small-sample Markov / Analog confidence**: Always check `(Obs)` in the 6×6
  Markov table and `Analog Sample Size` + `Conditioning Tier` in Tab 11.
- **Ignoring Net vs Gross drag**: A positive `Gross Avg` or `Gross Sum` (in
  Returns or ORB) with negative `Net Avg` / `Net Sum` means the signal does not
  clear real bid-ask spread and Indian statutory turnover taxes.
