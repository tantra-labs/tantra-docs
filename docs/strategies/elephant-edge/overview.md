# Elephant Edge (EE+): Overview

!!! warning "Implementation status"
    The **EE+ strategy engine is planned, not shipped** (strategy spec: `tantra-strategies`
    plan 0001; master plan: `docs/plans/0005`), grounded in the research basis
    `docs/research/elephant-edge-strategy.md` (workspace root). This page describes the
    strategy concept in design/future tense. The SDK primitives behind it — the level map,
    option-chain snapshot and stop-protection models — **are shipped and tested** (gap 0006,
    closed 2026-11-14) and are the only surface used in code samples on this guide.

## The core idea

Elephant Edge (EE+) is an intraday playbook for NSE index products (index futures and
liquid index options) that reads the market as a tug-of-war between two forces:

- **Price action** — where the session has actually traded: the open anchor, the
  first-bar extremes, the prior-session high/low/close, and displacement candles.
- **Smart money** — where the market makers and institutional desks have parked their
  positions: option open-interest walls, dealer-gamma concentrations, max pain, and
  Order Block footprints.

The strategy does not chase direction. It waits for price to arrive **at a level where
both stories agree**, then trades the reaction (reversal) or the escape (breakout) with a
stop that sits beyond the entire level cluster.

## The Elephant zones: two supports, two resistances

The signature EE+ construct is the **Elephant percentile zone**. The session range is
normalized into percentiles and four zones are carved out as the two supports and the
two resistances:

| Zone | Percentile default | Role |
| :--- | :--- | :--- |
| `ElephantSupport1` | 25 | inner support — first reaction zone |
| `ElephantSupport2` | 35 | outer support — where support *breaks* decisively |
| `ElephantResistance1` | 63 | inner resistance — first rejection zone |
| `ElephantResistance2` | 74 | outer resistance — where resistance *breaks* decisively |

Elephant zones are **bands, not lines** — a `Level` carries a `band_half_width`, and the
band (`price ± half_width`) is the tradable region. The strategy trades only the *edge* of
the zone — the outer band boundary — never inside it; that is where the "Elephant Edge"
name comes from.

## The 09:15 anchor

Every session starts with a single anchor: the **first 1-minute bar** (09:15 IST). The
level map is built **once at the anchor** from the overnight and prior-session footprint
plus the opening option chain, then **re-scored every N bars (default 5)** as the chain
and the session evolve. The anchor bar itself doubles as a displacement tell — an opening
marubozu that breaks a level is the earliest breakout candidate of the day.

## The intraday lifecycle

1. **Anchor** (09:15 IST) — build the initial `LevelMap` from the Elephant zones, PDH/PDL,
   OI walls, gamma levels, max pain, strike rounds and Order Blocks.
2. **Re-score** (every 5 bars) — recompute the 0–4 confluence score per level.
3. **Signal** — when price reaches a score ≥ 3 band and the trigger candle, volume,
   regime and discipline filters all agree, emit a `StrategySignal`.
4. **Stops** — attach a `StopProtection` (initial SL + ATR/swing trail); trail updates
   flow as `StopUpdate` events to `on_stop_update`.
5. **Sizing** — size to whole lots from the per-trade risk budget.
6. **Square-off** — flatten at the end-of-window exit (default 15:10) or on `on_stop`.

## Shipped SDK vs. designed engine

The engine that executes steps 3–6 is a **future slice**. What you can use today lives in
`tantra_strategies/sdk/`:

| Piece | Status |
| :--- | :--- |
| `Level`, `LevelMap`, `LevelKind`, `LevelSide` | shipped + tested |
| `OptionsSnapshot`, `OptionLeg` (`max_pain()`, `call_walls()`, `put_walls()`) | shipped + tested |
| `StrategySignal`, `SignalKind`, `PositionIntent` | shipped + tested |
| `StopProtection`, `TrailMode`, `StopUpdate` | shipped + tested |
| `StrategyContext.level_map()` / `options_snapshot()`; `Strategy.stop_loss()` / `trail_stop()`; lifecycle hook `on_stop_update` | shipped + tested (gap 0006) |
| EE+ engine rules (trigger candles, scoring, regime gating, sizing, square-off) | **planned** — `tantra-strategies` plan 0001 |

## Parameter reference (design)

The engine is intended to be declarative. These are the planned defaults and bounds,
mirrored in the [Level Map](level-map.md), [Signals](signals.md) and
[Stops & Positioning](stops-positioning.md) pages:

| Parameter | Default | Min | Max | Step |
| :--- | :--- | :--- | :--- | :--- |
| `elephant_support_percentiles` | `(25, 35)` | — | — | — |
| `elephant_resistance_percentiles` | `(63, 74)` | — | — | — |
| `use_oi_walls` | `True` | — | — | — |
| `use_gamma` | `True` | — | — | — |
| `use_order_blocks` | `True` | — | — | — |
| `use_pdh_pdl` | `True` | — | — | — |
| `use_max_pain` | `True` | — | — | — |
| `min_level_score` | `3` | 0 | 4 | 1 |
| `entry_window` | `(09:20, 14:30)` | — | — | — |
| `square_off_time` | `15:10` | — | — | — |
| `max_trades_per_day` | `3` | 1 | 10 | 1 |
| `risk_per_trade_pct` | `0.5` | 0.1 | 2.0 | 0.1 |
| `max_position_fraction` | `0.25` | 0.05 | 1.0 | 0.05 |
| `trail_mode` | `"atr"` | off / atr / swing | — | — |
| `trail_atr_mult` | `2.0` | 1.0 | 5.0 | 0.5 |
| `activation_after_r` | `1.0` | 0.5 | 3.0 | 0.5 |
| `sl_buffer_atr` | `0.25` | 0.1 | 1.0 | 0.05 |
| `min_sl_atr` | `0.5` | 0.2 | 3.0 | 0.1 |
| `volume_mult` | `1.5` | 1.0 | 5.0 | 0.1 |
| `body_ratio_breakout` | `0.6` | 0.5 | 0.9 | 0.05 |
| `alternate_mode` | `False` | — | — | — |

## Continue reading

- [The Level Map](level-map.md)
- [Signals](signals.md)
- [Stops & Positioning](stops-positioning.md)
- [EE+ Studio & Chat Tools](studio.md)
- [Reference & Worked Example](reference.md)
- [Strategies overview](../index.md)
