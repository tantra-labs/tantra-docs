# Experimental-Analysis Workbench (Novice Trader's Guide)

Trading without statistics is guessing. The **Experimental-Analysis** page lets you look at what a stock, ETF, index, currency, or commodity **actually did in the past**—measured with exact numbers—so you can base every trade on **odds, payoff size, and risk limits** instead of gut feeling.

Every number is computed directly from real historical market bars (Lakehouse v3) and live broker feeds when connected. Whenever 5-minute intraday data, live option quotes, or archived events are missing for a symbol, the page tells you honestly instead of making up fake data.

---

## 1. How to Use Statistics & Probability to Take a Trade

Before looking at individual buttons, keep this **5-step trading checklist** in mind. Everything on this page helps you answer these five questions before you click Buy or Sell:

| Step | Question to Answer | Key Stat / Probability on This Page | Trade Action |
| :--- | :--- | :--- | :--- |
| **1. Odds (Win Rate)** | How often does this trade work? | `Positive / Negative Periods %`, `Markov Next-Streak %`, `Fill Rate %` | Never take a trade blindly—know whether the historical odds are `35%`, `50%`, or `70%`. |
| **2. Size of Wins vs. Losses** | When I'm right vs. wrong, how much do I make or lose? | `Average Return`, `Profit Factor`, `Green vs Red Mean/Median` | A `40%` win rate still makes money if average wins are `2×` bigger than average losses (`Profit Factor > 1.3`). |
| **3. Where to Put Entries, Targets & Stops** | Where does price *rarely* go vs. *usually* go? | `Probability-Based Levels`, `Return Percentiles (P95/P5)`, `H-L Range` | Place **stops** outside normal noise (`75%–90%`), **targets** near `P50–P75`, and **option strikes** where odds are on your side (`80%–90%`). |
| **4. When to Enter** | Is today stretched, calm, or before a big news event? | `Streak Analysis`, `Tab 2 Outliers`, `Tab 3 Peak HOD/LOD`, `Tab 12 Events` | Don't chase a `5+` green streak; wait past `09:15–09:30` whipsaws; don't sell tight options right before Earnings/RBI news. |
| **5. Do Profits Survive Fees?** | After brokerage, STT, GST, and spread, is anything left? | `Net After Spread & Costs` + `Statutory Costs` (`Gross → Net`) | Only trade setups whose **Net** Profit Factor stays well above `1.0` after costs. |

!!! tip "A Simple Example: Turning Probability into a Real Trade"
    Suppose NIFTY is at **`24,000`** and **Tab 1 (`Probability-Based Levels`)** says:

    - **`90% ABOVE` = `23,550`** → In 9 out of 10 past weeks, NIFTY finished **above** `23,550`.
    - **`50% ABOVE` = `24,100`** → Half of past weeks finished above `24,100`.
    - **`10% ABOVE` = `24,550`** → Only 1 out of 10 past weeks climbed above `24,550`.

    Now you immediately know:
    - **Buying shares/futures**: `23,550` is a data-backed floor for a stop-loss, and `24,100–24,550` is a realistic target zone (don't expect `+5%` in one week when only 10% of weeks cross `24,550`).
    - **Selling options**: Selling a `23,550 Put` or `24,550 Call` has an ~90% historical win rate *per leg*—and adding protective wings turns it into a capped-risk **Iron Condor**.

---

## 2. Left Sidebar: Setting Up Your Test

Every control on the left rail changes what gets calculated across all 13 tabs. Always check the top strip (**Instrument · Range · Periods · Source**) first so you know what sample you are looking at.

### Feed & Lakehouse Card
- **Connected / Historical / Offline**: Shows whether live broker quotes are streaming (`Connected`) or you are studying archived Lakehouse bars (`Historical`).
- **Indexed Symbols & F&O Contracts**: How many symbols and F&O contracts are loaded right now.

### Study Family
- **`Period & Expiry Returns`** *(default)*: Unlocks all **13 study tabs** below.
- **`Buyback / Corporate Event Study`**: Replaces the main view with an event timeline showing how a stock moves **20 days before and 20 days after** buybacks/corporate actions.
- **`Earnings / Macro Reaction Study`**: Shows how a stock reacts **20 days before and after** earnings releases or RBI/Fed macro dates (`All`, `IN`, or `US`).

### Asset Class Universe, Instrument & Analysis Period
Pick your market (**Indices**, **F&O Stocks**, **ETFs**, **Equities**, **Forex**, **Commodities**) and how historical bars are sliced into "periods":

| Market | Default Period | Why It Matters for Trading |
| :--- | :--- | :--- |
| **Indices** | `Weekly Expiry` | Matches weekly NIFTY/SENSEX/BANKNIFTY option expiries so stats line up with real option trades. |
| **F&O Stocks** | `Monthly Expiry` | Matches monthly stock F&O expiries. |
| **ETFs / Equities** | `Calendar Monthly` | Groups by calendar month (or switch to `Calendar Weekly` / `Daily` for swing trading). |
| **Forex / Commodities** | `Front-Month / MCX Expiry Cycle` | Follows contract roll dates automatically. |

!!! note "Sep 3, 2025 Expiry Day Switch"
    Indian index weekly expiries changed weekdays on **September 3, 2025** (for example NIFTY moved from Thursday to Tuesday, SENSEX to Thursday). The workbench automatically aligns pre-cutover and post-cutover dates so historical averages aren't corrupted.

### Calculation Type (`OC`, `H-L`, `CC`)
- **`OC` (Open to Close)** *(default)*: Measures return from the **start** of each cycle to the **end** of that cycle (ignores overnight/weekend gaps). Best for asking: *"If I enter at cycle open and exit at expiry close, what happens?"*
- **`CC` (Close to Close)**: Measures return from **last cycle's close** to **this cycle's close** (includes gaps). Best for holding continuous ETFs, delivery trades, or rolling futures.
- **`H-L` (High to Low)**: Measures total swing size (`(High - Low) ÷ Open × 100`). Because `High` is always `≥ Low`, **`H-L` is ALWAYS positive (`0%` or higher)**.

!!! warning "Do Not Misread `H-L`"
    Switching to `H-L` turns every single bar green! That does **not** mean the asset goes up 100% of the time. Use `H-L` purely to measure **how wide price swings** (for stop-loss distance and option wing width)—switch back to `OC` or `CC` to judge up/down direction.

### F&O Spread & Friction (Making Backtests Honest)
Real trading costs money on every order. Always test your idea with friction turned on:
- **`Gross Spot`**: Raw price moves with **zero** fees or slippage.
- **`Include Roll Basis`**: Models futures roll premium/discount (`Roll Basis (bps)` — `100 bps = 1%`).
- **`Net After Spread & Costs`**: Subtracts bid-ask spread (`Spread (bps)`) plus, if **Statutory Costs (STT/Exch/GST)** is checked, actual Indian STT, stamp duty, exchange fees, SEBI turnover charges, and 18% GST.
- **Reconciliation Card**: When friction is enabled, this card compares **Gross → Net Avg**, **Gross → Net Sharpe**, **Gross → Net Profit Factor**, and **Cumulative Net Delta** so you can immediately see if fees kill the strategy.

---

## 3. Section-by-Section Interpretation of Tab 1 (`Returns Analysis`)

Tab 1 has **11 sections** from top to bottom. Here is how to read each one and use it in a trade:

### 3.1 Sub-Cycle Carrying Mode
- **`Current Period`**: Looks at one cycle at a time (e.g., Monday open to Friday close).
- **`Period +1 Carry`**: Looks at holding across **two cycles combined** (this cycle's open through *next* cycle's close). Compare both: if returns double cleanly with better Sharpe, holding slightly longer pays off; if gains shrink or drawdowns jump, exit at the end of one cycle.

### 3.2 The 9 Summary KPIs (3×3 Grid)
- **Average Return**: Mean move per period. If positive and meaningfully larger than your costs (`Spread + STT`), the asset has a natural upward drift.
- **Max Gain / Max Loss**: The biggest winning and losing periods in your sample. Ask yourself: *"If Max Loss happens tomorrow on my position size, can my account survive it?"*
- **Return Std Dev**: How widely returns bounce around the average. Roughly ~68% of normal periods stay within `Average ± 1 × Std Dev`, and ~95% within `Average ± 2 × Std Dev`.
- **Positive Periods / Negative Periods**: Your historical win rate vs. loss rate (`Neutral 0%` periods are excluded from directional win/loss share).
- **Sharpe Ratio**: Average return divided by total volatility (`> 1.0` per cycle is strong; `0.3–0.8` is normal for equities; `< 0` means losing money). Always compare Sharpe under the *same* schedule (`Weekly` vs `Weekly`, not `Weekly` vs `Monthly`).
- **Sortino Ratio**: Like Sharpe, except it only penalizes **losing** periods (ignores big upside surges). When **Sortino > Sharpe**, big surprises tend to be upside wins; when **Sortino < Sharpe**, downside crashes hurt more.
- **Profit Factor**: Total gains divided by total losses. `< 1.0` = loses money overall; `1.0–1.2` = fragile after fees; `1.3–1.8+` after costs = solid statistical edge.

### 3.3 Return Trajectory Chart (Lollipop / Bars + Moving Average)
- **How to read it**: Each green stem going up is a winning cycle; each red stem going down is a losing cycle. Taller stems and bigger circles = larger moves.
- **Moving Average (`MA Window`)**: Toggle **Show Moving Average** (`5–50` periods) to see whether average performance has been drifting up (momentum regime) or oscillating back and forth across `0%` (mean-reverting / range regime).
- **Vertical Sep 3, 2025 Marker**: Shows where SEBI's expiry-day regime cutover happened on Indian derivatives.

### 3.4 Streak Analysis (Consecutive Winning & Losing Runs)
- **Current Streak Banner**: Shows whether the asset is currently in a `Positive` or `Negative` run, how many periods in a row it has lasted, and the total compounded `%` move so far.
- **Diverging Streak Lengths Timeline & Distribution of Streak Lengths**: Shows how long past streaks normally lasted before snapping.
- **Positive / Negative Streak Statistics (`Most Common`, `Median`, `Std Dev`) & Streak Details Table**:
  - **How to trade it**: Compare **Current Streak** against **Median**. If the median green streak is `2` periods and the current green streak is `5` periods, buying *right now* is chasing an overextended rubber band—either tighten trailing stops or check Section 3.5 for a **Contrarian** pullback signal.

### 3.5 Markov Chain Transition Analysis (What Usually Follows Current Streak?)
Markov analysis doesn't guess from theory—it literally counts every streak in history and asks: *"Once a run reaches this length, what happened next?"*

- **6 Streak States**:
  - `Short + (1-2)`, `Med + (3-4)`, `Long + (5+)` (green streaks of 1–2, 3–4, or 5+ periods)
  - `Short - (1-2)`, `Med - (3-4)`, `Long - (5+)` (red streaks of 1–2, 3–4, or 5+ periods)
- **Current Streak Probability Prediction Card**: Summarizes the highlighted row into two numbers—**Next Streak Positive %** vs **Next Streak Negative %**—and displays **Strong Prediction**.
- **6×6 Transition Matrix Table**: Each row (`Current State (Obs)`) gives exact historical probabilities (%) of which state came *next*.
- **Steady-State Equilibrium Distribution**: Shows the long-run balance of states (e.g., if `Short +` + `Med +` + `Long +` total 58%, the asset spends 58% of its long-run life in up-runs).

!!! warning "The #1 Rule for Reading Markov Tables: Check `(Obs)`!"
    `(Obs)` tells you **how many times that situation actually occurred in your date range**. If `Long + (5+)` shows `100%` chance of flipping negative, but `(Obs) = 2`, that only happened twice! Wait for `(Obs) ≥ 10` before treating a cell as reliable probability—or combine it with Tab 2 and Tab 5.

### 3.6 Return Percentiles (`P99` down to `P1`)
Ranks every historical period from best to worst:
- **`P50` (Median)**: Half of all periods finished above this, half below. (Less distorted by one crazy crash than the simple average.)
- **`P75` / `P25`**: The middle 50% of normal moves—if your profit target is inside `P75`, it is realistic; if it's past `P95`, you are betting on a rare outlier.
- **`P95` vs `P5` and `P99` vs `P1`**: Compare the upside tail against the downside tail. If `|P5|` (say `-4.8%`) is much bigger than `P95` (`+3.2%`), crashes hit harder than rallies—size your positions smaller and protect downside with puts/stops.

### 3.7 Return Distribution (`16-Bucket` & `Granular 10-bps`) + Spot Reference Card
- **Spot Reference Card**: Shows the **Current Period Reference Price** so every percentage bucket automatically converts into real **Spot Price Ranges** (`₹` prices).
- **16-Bucket Table**: Shows how many periods fell into each bucket (`> +5%`, `+4% to +5%`, ..., `< -5%`), the exact rupee range, cumulative percentile, and probability `%`. Tall bars near `-1% to +1%` mean most cycles finish quietly (great for range strategies like **Iron Condors**).
- **Granular Distribution (10 Basis Points)**: Expands into `0.1%` slices to spot exact pinning zones and clusters.

### 3.8 Probability-Based Levels (Easy Reference)
This table turns historical statistics directly into **today's rupee price targets** by answering: *"What is the historical probability that price finishes **ABOVE** this price by the end of the cycle?"*

| Table Row (`Prob. ABOVE`) | Price Position vs. Today | How Traders Use It |
| :--- | :--- | :--- |
| **`99%` / `95%` / `90%` ABOVE** | **Below** current price (support zone) | Only `1% / 5% / 10%` of past cycles finished *below* here → natural zone for **stop-losses** on longs or **Short Put** strikes. |
| **`75%` / `80%` ABOVE** | Modestly **below** current price | `75%–80%` odds of finishing above → popular **Short Put** / put credit spread strike level. |
| **`50%` ABOVE** | Near current price (median finish) | Historical 50/50 dividing line. |
| **`25%` / `20%` ABOVE** | Modestly **above** current price | Only `20%–25%` of cycles closed higher → realistic **bullish profit target** or **Short Call** strike level. |
| **`10%` / `5%` / `1%` ABOVE** | Far **above** current price (resistance zone) | Only `1%–10%` of cycles surged past here → extreme upside target or protective **Long Call Wing**. |

### 3.9 Green vs Red Periods Comparison & Magnitude Empirical PDF
- Places all winning (`Green`) periods side-by-side against losing (`Red`) periods: count, `%` share, average, median, std dev, extreme move, and a magnitude histogram (`0–1%`, `1–2%`, ..., `> 5%`).
- **How to use it**: Even if an asset wins `55%` of the time, check **Red Mean/Median** vs **Green Mean/Median**. If red drops average `-2.4%` while green gains average `+1.2%`, one red cycle erases two green cycles unless you use a stop-loss.

### 3.10 Conditional Forward Accordions (`After Large Move`)
Shows what happened in the **next period** (and `Period +1 Carry`) immediately after an unusually big jump (`r ≥ +threshold`) or big selloff (`r ≤ -threshold`):
- If **After Large Negative Period** has positive average/median return and `Pos Win Rate > 55%`, selloffs tend to **bounce back** (supports buying fear / Contrarian longs).
- If **After Large Positive Period** turns negative or flat, big rallies tend to **cool off** (take profits instead of chasing).

### 3.11 Period Returns Ledger & Daily OHLC Analysis
- **Period Returns Table**: Filterable (`All`, `Positive`, `Negative`) ledger of every single cycle (`Start Date`, `End Date`, `Entry`, `Exit`, `Return %`, `Regime`) so you can verify the numbers yourself—zero black box.
- **Daily OHLC Analysis**: Displays the 7 daily summary cards (`Current Close`, `Period High`, `Period Low`, `Trading Days`, `Avg Daily Ret`, `Daily Ret Std`, `Avg Volume`), an interactive candlestick chart with full left-rail drawing tools (Trend Line, Ray, Horizontal/Vertical Line, Fib Retracement, etc.), and a paginated table of daily bars with **Dividends** and **Splits**.

---

## 4. Section-by-Section Interpretation of Tabs 2–13

### Tab 2 — Outliers & Global Events
- **Probability Boundary Coverage Slider (`50%–99%`, default `90%`)**: Draws upper and lower dashed boundary lines on the **Abraham Wald Survivability Scatter Plot**. Dots inside the lines are normal day-to-day noise; green/red dots outside the lines are **rare extreme shocks** (for `90%`, the top 5% rallies and bottom 5% crashes).
- **Outlier Periods Table + Historical Global News & Events**: Click any outlier dot or table row to pull up real news/filings from that exact week (`[start - 2d, end + 1d]`).
- **How to trade it**: Distinguish **emotional overreactions** (good candidates to fade back toward normal) from **fundamental shocks** (earnings disasters, fraud, RBI/Fed rate pivots—do **not** fade these).

### Tab 3 — Intraday Movement
- **Clock-Slot Table & Bar Profile Chart**: Splits `5m` intraday bars into **15-minute** or **Hourly** buckets (`09:15`, `09:30`, ..., `15:15`).
- **Avg Range % / Max Range % / Avg |O-C| % / Avg Volume**: Shows when the market moves the most and has the tightest liquidity.
- **Peak HOD Clock & Peak LOD Clock**: Tells you which 15-minute slots most frequently print the **High of the Day** and **Low of the Day**.
- **How to trade it**: Many day traders lose money in the noisy `09:15–09:30` opening spike. If HOD/LOD clusters around `09:30–10:00` and quietens mid-day, waiting until after the opening burst improves fill prices and stops fewer whipsaws.

### Tab 4 — Gap Up / Gap Down
- **Overnight Gap Buckets & Fill Expectancy Table**: Splits overnight gaps (`< -2.0%` through `> +2.0%`) into 8 buckets and reports **Fill Rate %** (did price return to yesterday's close?) and **Avg Intraday O→C** (after the open, did it continue or reverse?).
- **Recent Overnight Gap Events Table**: Lists the latest actual gap days so you can inspect recent behavior.
- **How to trade it**:
  - **High `Fill Rate %` (`≥ 65–70%`) + opposite `Avg Intraday O→C`** = **Fade/Fill setup** (e.g., small gap-ups that routinely sell back down to yesterday's close).
  - **Low `Fill Rate %` + same-direction `Avg Intraday O→C`** = **Breakaway gap** (trend continuation—do **not** short a breakaway gap-up!).

### Tab 5 — 5-Day Move Analysis
- **Rolling 5-Day Return Trajectory + Percentiles + Win Rate**: Measures how much the asset typically moves over any 5-trading-day sprint.
- **Post-Surge Next 5D Expectancy & Post-Selloff Next 5D Expectancy**: Checks what happened in the **following 5 days** after a huge 5-day surge or 5-day crash.
- **How to trade it**: If `Post-Surge Next 5D` turns negative while `Post-Selloff Next 5D` is strongly positive, 5-day extremes consistently mean-revert.

### Tab 6 — Cycle Progress (0–100%)
- **Normalized Path Fan Chart (`0%` Start → `100%` Expiry)**: Compares `P10–P90` (outer band), `P25–P75` (typical band), `Median (P50)`, and `Mean` across every 10% slice of a cycle.
- **How to trade it**: Tells you *when* during a week or month moves happen. If most upward drift happens in the first `20–40%` of the cycle and stalls in `60–100%`, long buyers should take profits early while option sellers benefit from flat late-cycle theta decay.

### Tab 7 — Cross-Asset Correlation
- **Instrument Selector (`2–12` symbols) + Benchmark + Rolling Window (`5–250` days)**:
  - **Pearson vs. Spearman Correlation Matrices**: Numbers run from `-1.0` (exact opposite) to `+1.0` (locked together). Check **Spearman** alongside Pearson—if Pearson is high only because of one crash day, Spearman exposes it.
  - **Pair Beta, Latest Raw Spread & Relative Perf Spread**: Dual chart tracks rolling correlation and normalized spread divergence.
- **How to trade it**: Avoid taking 3 "separate" trades that have `0.90` correlation (that's really 3× risk on the same bet!), or spot when two normally correlated peers diverge for a mean-reverting pair trade.

### Tab 8 — Options Overlay & Spreads
- **Strategy Picker (`Covered Call`, `Bull Call Spread`, `Bear Put Spread`, `Iron Condor`, `Calendar Spread`) + `Short Prob %` (`55–98%`) + `Wing Width %` (`0.5–15%`)**:
  - **Data Mode Banner**: Clearly displays **Live Chain** (using real option Bid/Ask quotes) vs. **Empirical Unquoted Mode** (no fabricated quotes when disconnected).
  - **Headline Metrics**: **Net Cycle Credit**, **Probability of Profit (PoP)**, **Friction Drag / Cycle**, **Cycle Max Profit / Max Loss**, and **Overlay Net Cum / Max Drawdown** vs. **Buy & Hold**.
- **How to trade it**: Never look at PoP alone! A trade with `85%` win rate can still lose money over time if the `15%` losses are giant or if 4-leg fees eat the credit. Check that the **Equity Curve (`Overlay Net Cum`)** rises steadily with smaller drawdown (`Overlay DD`) than Buy & Hold. See [Section 6](#6-iron-condor-condor-wings-guide) for full Iron Condor details.

### Tab 9 — Expiry Strike Lab
- **Vol Risk Premium Card (`IV − RV`)**: Compares **Realized Vol (RV)** (how much price actually moves) against **Quoted IV Proxy (ATM)** (how expensive options are priced):
  - **`IV − RV > 0`**: Options are **overpriced** compared to real movement → option sellers have a statistical tailwind.
  - **`IV − RV < 0`**: Options are **cheap** → don't sell underpriced options; favor debit spreads or wait.
- **Strike Ladder Table**: Shows every `CE` and `PE` strike, `Moneyness %`, historical **`Exceed Prob %`** (how often that strike gets reached), live `Bid`/`Ask`/`Mid`, `Spread bps`, **`Liquidity` badge** (`tight ≤ 40 bps`, `moderate ≤ 120 bps`, `wide > 120 bps`, `unquoted`), and `OI`.
- **How to trade it**: Choose strikes whose `Exceed Prob %` matches your risk comfort (`10–20%`) **and** whose Liquidity badge is **`tight`** or **`moderate`** (avoid `wide` spreads where slippage kills you).

### Tab 10 — 15m ORB Flip Backtest
- **Opening Range Breakout (`OR (m)` `5–60`, `Max Flips` `0–10`, `SL %`, `Target %`)**: Simulates buying breakouts above the opening range or selling breakdowns below it, optionally flipping direction when stopped out.
- **KPI Strip + Simulated ORB Trade Legs Table**: Always compare **Gross Sum** vs. **Spread+Fee Drag** vs. **Net Sum**, and inspect `exit_reason` (`target`, `stop_flip`, `stop_max_flips`, `eod`).
- **How to trade it**: Notice how high `Max Flips` on choppy days often looks profitable Gross while bleeding Net from repeated whipsaw fees—use this tab to tune `Max Flips` down (`0–2`) and pick symbols that actually trend cleanly after the open.

### Tab 11 — Forecasting
- **Conditioning Header (`Current Markov State` + `Volatility Regime`: `Low`, `Normal`, `Elevated`) & `Conditioning Tier`**: Finds historical episodes that looked like *today* and tracks what happened over the next `T+1` to `T+N` periods (`2–12`).
- **Forward Fan Chart, Quantile Target Price Ladder (`P10`, `P50`, `P90`, `Win %`), & Closest Historical Analog Episodes**:
  - **How to trade it**: Use `P10` as your realistic **downside risk check**, `P50` as your **base-case target**, and `P90` as your **stretch target**. Always check **Analog Sample Size**: if `< 5` exact matches existed, the page warns you that it fell back to a broader pool.

### Tab 12 — F&O / Index Rebalance & Event Modes
- **Event Alignment Chart (`CAR[-20d, +20d]` gold curve + `AAR` bars + `Avg Vol Surge Ratio`) + Event Study Ledger**: Measures abnormal performance around `T=0` (`F&O Inclusion/Exclusion`, `Buybacks`, `Earnings`, or `Macro Calendar`), with optional **Benchmark AR** (strips out broad market movement).
- **How to trade it**: If the gold curve runs up strongly *before* `T=0` (`-20d` to `-1d`) and drops afterward, insiders/funds already bought the rumor and sold the news. If it surges cleanly *after* `T=0`, post-event momentum is real.

### Tab 13 — AI Study Assistant
- Captures a live snapshot of your active KPIs, strongest Markov transition, and outlier fences, giving you one-click prompts to send directly to **Quant Copilot** for plain-English second opinions and trade sizing ideas.

---

## 5. Contrarian Strategy Playbook (Using Stats to Fade Extremes)

Beginners often buy *after* a huge rally (fear of missing out) and sell *after* a huge crash (panic)—buying the top and selling the bottom. A **Contrarian (Mean-Reversion)** strategy uses probability to do the disciplined opposite: **wait for a statistically extreme stretch, verify that history snaps back, and protect your downside.**

```text
1. Spot the Stretch           2. Check the Odds              3. Verify Risk & Costs
───────────────────           ─────────────────              ────────────────────
• Tab 1: Long streak (5+) ──▶ • Markov Next Opposite >55% ─▶ • Tab 11 P10 downside risk
• Tab 2: Outside 90/95%   ──▶ • News isn't fatal shock    ─▶ • Tab 1 Conditional Forward
• Tab 5: Huge 5D move     ──▶ • Next-5D reverses          ─▶ • Left Rail: Net After Costs
• Tab 4: Extended Gap     ──▶ • Fill Rate ≥ 65–70%        ─▶ • Tab 3: Wait past 09:30 AM
```

### Trade Setup 1: Fading an Exhausted Streak (`Tab 1` + `Tab 11`)
1. Check **Current Streak** vs. **Median Streak Length**: look for a streak that has reached `Med (3-4)` or `Long (5+)`.
2. Check that exact row in the **6×6 Markov Matrix** (make sure `(Obs)` is meaningful, ideally `≥ 10`):
   - **Take the trade** if **Next Streak Opposite** is clearly above `50%` (e.g., `60%+`) and **Strong Prediction** points to reversal.
   - **Skip the trade** if the matrix shows momentum persistence (streaks frequently extend into `5+`) and **Steady-State** is heavily skewed in the trend direction.
3. Open **Tab 11 (`Forecasting`)**: check `T+1` `P10` (worst-case risk if you're early) vs. `P50` (expected snap-back target) to place your stop-loss and target.

### Trade Setup 2: Fading a Shock Outlier (`Tab 1` + `Tab 2` + `Tab 5`)
1. In **Tab 2 (`Outliers & Global Events`)**, set **Probability Boundary Coverage** to **`90%`** or **`95%`** and check if the current period sits outside the dashed fence.
2. **Click the outlier dot** and read **Historical Global News & Events**: only fade positioning/panic overshoots—never step in front of structural bad news (earnings collapse, governance shock, surprise rate hike).
3. Double-check **Tab 1 (`Conditional Forward: After Large Move`)** and **Tab 5 (`Post-Surge / Post-Selloff Expectancy`)** to confirm that past shocks on this specific symbol actually bounced back on average.

### Trade Setup 3: Fading an Overnight Gap (`Tab 3` + `Tab 4`)
1. In **Tab 4**, locate today's gap size inside the **8 Gap Buckets**.
2. Enter a contrarian gap-fade **only** when **both** hold historically:
   - **`Fill Rate % ≥ 65–70%`**, and
   - **`Avg Intraday O→C`** has the opposite sign (negative after gap-ups, positive after gap-downs).
3. Use **Tab 3 (`Peak HOD / LOD Clock`)** to wait past the first `15–30 minutes` (`09:15–09:45`) before entering so initial market orders don't stop you out.

### Always Run the Friction Check Before Clicking Trade
Enable **`Net After Spread & Costs`** + **`Statutory Costs`** in the left sidebar. High-frequency contrarian trades (especially daily or gap fades) fail quickly if bid-ask spread and STT/GST exceed `Average Return`.

---

## 6. Iron Condor & Condor Wings Guide

An **Iron Condor** (`Tab 8 → Strategy: Iron Condor`) is a defined-risk options strategy that earns money when price stays **calm inside a range**—it can profit whether the market goes slightly up, flat, or slightly down.

Think of it like building a **profit zone with safety fences** around today's price:

```text
   Safety Fence         Danger Line       Today's Price       Danger Line         Safety Fence
   (Long Put)           (Short Put)          (Spot)          (Short Call)         (Long Call)
     BUY PE               SELL PE              ●               SELL CE              BUY CE
  ◀───── Wing Width % ─────▶◀─────── Profit Zone (collect credit) ───────▶◀───── Wing Width % ─────▶
   Caps worst-case                                                          Caps worst-case
   crash loss                                                               rally loss
```

- **Inner Short Strikes (`SELL PE` + `SELL CE`)**: You collect upfront cash (**Net Cycle Credit**). If price stays between these two lines at expiry, you keep the credit.
- **Outer Condor Wings (`BUY PE` + `BUY CE`)**: You spend a smaller amount of that cash to buy far-out insurance. If a huge crash or rally hits, your loss **stops completely at the Wing**—no unlimited losses.

### How the Workbench Places Short Strikes & Wings
1. **`Short Prob %` (`55%–98%`, default `80%`)**: Uses Tab 1's actual historical return distribution to position your inner `SELL PE` and `SELL CE` strikes:
   - At `80%`, `SELL CE` sits near Tab 1's **`20% ABOVE`** level and `SELL PE` sits near **`80% ABOVE`**. Roughly `60%` of historical cycles finished completely inside `[Short Put, Short Call]`, while each wing individually had only an `~20%` chance of being breached.
   - Raising `Short Prob %` to `90%` increases your win rate (`Probability of Profit`), but collects smaller credit per cycle.
2. **`Wing Width %` (`0.5%–15.0%`)**: Sets the distance from each short strike out to its protective **Long Wing** (`BUY PE` / `BUY CE`), snapped to real exchange strike steps (`50` pts for NIFTY, `100` pts for BANKNIFTY/SENSEX).
   - **Example**: With NIFTY at `24,000`, `Short Call = 24,500`, and `Wing Width % = 2%` (`~480 pts` → `500 pts`), your **Long Call Wing** sits at `25,000`. Maximum possible loss on either side is capped at `Wing Width − Net Credit`.

### Using the Rest of the Workbench to Size Your Condor

| Trading Question | Where to Look | What Good Numbers Look Like |
| :--- | :--- | :--- |
| **1. Should I run a Condor this cycle?** | **Tab 9 (`Vol Risk Premium`)** & **Tab 12 (`Events`)** | **`IV − RV > 0`** (options are priced richer than realized movement) and **no** major Earnings/RBI catalyst ahead in Tab 12. |
| **2. Are my short strikes balanced?** | **Tab 1 (`Probability Levels` & `Green vs Red`)** & **Tab 9 (`Strike Ladder`)** | If **Red** periods fall sharper than **Green** periods rally (`|P5| > P95`), give your Put side extra room (`Short Prob %` `85–90%`). On Tab 9, confirm both short strikes are **`tight`** or **`moderate`** liquidity. |
| **3. How wide should my Wings be?** | **Tab 1 (`H-L` mode & `P99/P1`)** & **Tab 2 (`Outliers`)** | Pick **Narrow Wings (`0.5%–1.5%`)** for tight max loss & lower margin, or **Wide Wings (`2.5%–6.0%`)** for larger credit & lower percentage fee drag (verify `Overlay DD` in Tab 8 stays within your risk limit). |
| **4. Do the 4 legs survive real costs?** | **Tab 8 (`Friction Drag / Cycle` & `Equity Curve`)** | Check that **Net Cycle Credit** comfortably beats **Friction Drag / Cycle** across all 4 legs (`SELL CE`, `BUY CE`, `SELL PE`, `BUY PE`) and **Overlay Net Cum** trends up cleanly. |

### Narrow Wings vs. Wide Wings at a Glance
- **Tight Wings (`0.5% – 1.5%`)**: Smallest worst-case loss per trade and lowest margin, **but** paying spread + Indian taxes (sell-side STT, stamp, exchange, SEBI + 18% GST) on all 4 legs can eat `30–60%+` of a small credit and turn `Overlay Net Cum` negative.
- **Wide Wings (`2.5% – 6.0%+`)**: Larger net credit, faster time decay, and fees become a tiny slice of credit—**but** a rare `Tab 2` tail shock (`> P95`) produces a bigger single-cycle drawdown (`Overlay DD`).
- **Pro Combination (`Contrarian + Iron Condor`)**: After a **Tab 2** panic outlier or **Tab 1** `Long (5+)` streak exhausts and spikes option prices (`IV − RV > 0` on Tab 9), markets often cool off into sideways consolidation (**Tab 6 `Cycle Progress`**). Selling an Iron Condor *after* the initial shock harvests elevated option premium while your **Condor Wings** protect you in case the trend keeps running.

---

## 7. Quick Recap: 5 Beginner Mistakes to Avoid

1. **Treating `H-L` green bars as bullish bias**: `H-L` only measures swing magnitude (`≥ 0%`). Always switch back to `OC` or `CC` before judging up/down win rates.
2. **Reading `Probability-Based Levels` upside-down**: `90% ABOVE` is a **lower** support floor; `10% ABOVE` is a **higher** resistance ceiling.
3. **Trusting `100%` rows with tiny `(Obs)`**: A Markov row or Tab 11 forecast built from `2–4` historical cases is noise, not statistical certainty.
4. **Ignoring 4-leg friction on tight Condors or high-flip ORB**: Always turn on **Net After Spread & Costs** + **Statutory Costs** in the left rail before risking real capital.
5. **Fading real fundamental shocks**: Always click **Tab 2** outliers to check **Historical Global News & Events** before taking a Contrarian trade.
