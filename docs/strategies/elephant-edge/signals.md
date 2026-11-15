# Elephant Edge Signals

!!! warning "Implementation status"
    The **EE+ signal engine is planned, not shipped** (strategy spec: `tantra-strategies`
    plan 0001; master plan: `docs/plans/0005`), grounded in the research basis
    `docs/research/elephant-edge-strategy.md` (workspace root). The rules below describe the
    **designed** behavior in future tense. The `StrategySignal` and `SignalKind` models in
    the snippet **are shipped and tested** (gap 0006, closed 2026-11-14).

## Signal kinds

`SignalKind` (from `tantra_strategies.sdk.levels`) defines three signal types:

| Kind | Meaning |
| :--- | :--- |
| `BREAKOUT` | price closes beyond a level band — the escape |
| `REVERSAL` | price rejects inside a level band — the reaction |
| `RETEST` | after a break, the first pullback to the band — role reversal |

## When a signal fires

A `StrategySignal` is emitted only when **all** of the following hold on the same bar:

1. **Level reach** — price trades into (or breaks) a level band with `score ≥ 3`.
   Levels with `score < 3` are not tradeable (see [The Level Map](level-map.md)).
2. **Regime permission** — the signal kind is allowed by the dealer-gamma regime and the
   PCR tilt: long-gamma favours Reversal, short-gamma favours Breakout; the PCR tilt comes
   from the confluence score.
3. **Trigger candle** — the bar shape matches the signal kind (below).
4. **Volume participation** — at least `volume_mult` × the 20-bar average volume
   (default `1.5`).
5. **Discipline** — the entry window is open (default 09:20–14:30), the daily trade count
   (default 3) is not exhausted, the same level has not already produced a signal today,
   and the session is not within the last 30 minutes.
6. **No open opposing position** — one position per instrument intraday.

## Trigger candles

| Signal kind | Trigger candles | Filters |
| :--- | :--- | :--- |
| `REVERSAL` | hammer / bullish-engulfing at support; shooting-star / bearish-engulfing at resistance | wick:body filter — body ≤ 45% for hammers; candle-size filter excludes < 0.2×ATR noise and > 4×ATR outliers |
| `BREAKOUT` | marubozu-style close beyond the band | body ≥ `body_ratio_breakout` (default 0.6) of the range; the band must be *pierced* (touch filter), not just wick-poked |
| `RETEST` | after a break, the first pullback to the band with a hold candle | role reversal — old resistance holds as support and vice versa |

Candle filters are applied in design as:

- body ≤ 45% for hammers / shooting-stars (long wick against the band);
- body ≥ 60% of the range for marubozu-style breakouts;
- range < 0.2×ATR → noise, skip; range > 4×ATR → outlier, skip.

## Volume participation

The trigger bar must trade at or above `volume_mult` × the 20-bar average volume (default
`1.5`). A quiet hammer in a dead tape is not a signal — market makers only defend levels
that are actually being attacked.

## Time window and trade-count discipline

- Entry window: 09:20–14:30 (`entry_window`). Signals before 09:20 are disallowed even if
  the anchor bar broke a level — the session needs its first real bars.
- Max `max_trades_per_day` (default 3); no duplicate signal at the same level; no new
  entries in the last 30 minutes of the window.
- `alternate_mode` (default `False`): when on, the next signal is forced to the opposite
  side of the last fill, preventing both-side churn at the same level.

## Shipped SDK: `StrategySignal`

```python
from decimal import Decimal

from tantra_strategies.sdk.levels import (
    LevelKind,
    SignalKind,
    StrategySignal,
)
from tantra_strategies.sdk.order import OrderSide

signal = StrategySignal(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    kind=SignalKind.REVERSAL,
    ref_levels=("ee-els-1", "ee-oiw-p-1"),
    confidence=Decimal("78"),
)
```

The `confidence` field is a `Decimal` validated to `0 <= confidence <= 100` at
construction. Under the design, the engine will set it from level-score alignment and the
volume ratio; the `ref_levels` tuple records exactly which levels were hit so the stop
placement (see [Stops & Positioning](stops-positioning.md)) can be built from the same
cluster.

## Continue reading

- [The Level Map](level-map.md) — where the bands and scores come from
- [Stops & Positioning](stops-positioning.md) — what happens after the signal
- [EE+ overview](overview.md)
- [Strategies overview](../index.md)
