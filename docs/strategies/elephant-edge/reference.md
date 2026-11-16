# Elephant Edge (EE+): Reference & Worked Example

!!! warning "Implementation status"
    The **EE+ strategy engine is planned, not shipped.** This guide documents the
    *designed* behavior of the strategy (strategy spec: `tantra-strategies` plan 0001;
    master plan: `docs/plans/0005`), grounded in the research basis
    `docs/research/elephant-edge-strategy.md` (workspace root). What **is** shipped and
    tested is the SDK surface behind it — `LevelMap`, `Level`, `OptionsSnapshot`,
    `StrategySignal`, `StopProtection`, `StopUpdate` and friends in
    `tantra_strategies/sdk/levels.py` and `tantra_strategies/sdk/stop_protection.py`
    (gap 0006, closed 2026-11-14). The **Strategy Studio** (`tantra-ui` plan 0006) and the
    **`level_map` / `oi_walls` chat tools** (`tantra-agent` plan 0011) are also planned.
    Every code sample in this guide uses only the shipped SDK models; the strategy engine
    itself is described in design/future tense.

## Parameter reference (design)

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

The engine will declare these as Jesse-style `Parameter(default=..., min=..., max=..., step=...)` descriptors, matching the catalog convention.

## Declarative configuration example

```python
from decimal import Decimal

from tantra_strategies.sdk import Bar, Parameter, Strategy


class ElephantEdgeIntraday(Strategy):
    instrument = "NSE:NIFTY-INDEX"

    elephant_support_percentiles = Parameter(default=(25, 35))
    elephant_resistance_percentiles = Parameter(default=(63, 74))
    use_oi_walls = Parameter(default=True)
    use_gamma = Parameter(default=True)
    use_order_blocks = Parameter(default=True)
    use_pdh_pdl = Parameter(default=True)
    use_max_pain = Parameter(default=True)
    min_level_score = Parameter(default=3, min=0, max=4, step=1)
    max_trades_per_day = Parameter(default=3, min=1, max=10, step=1)
    risk_per_trade_pct = Parameter(default=Decimal("0.5"),
                                   min=Decimal("0.1"), max=Decimal("2.0"),
                                   step=Decimal("0.1"))
    max_position_fraction = Parameter(default=Decimal("0.25"),
                                      min=Decimal("0.05"), max=Decimal("1.0"),
                                      step=Decimal("0.05"))
    trail_mode = Parameter(default="atr")
    trail_atr_mult = Parameter(default=Decimal("2.0"),
                               min=Decimal("1.0"), max=Decimal("5.0"),
                               step=Decimal("0.5"))
    activation_after_r = Parameter(default=Decimal("1.0"),
                                   min=Decimal("0.5"), max=Decimal("3.0"),
                                   step=Decimal("0.5"))
    sl_buffer_atr = Parameter(default=Decimal("0.25"),
                              min=Decimal("0.1"), max=Decimal("1.0"),
                              step=Decimal("0.05"))
    min_sl_atr = Parameter(default=Decimal("0.5"),
                           min=Decimal("0.2"), max=Decimal("3.0"),
                           step=Decimal("0.1"))
    volume_mult = Parameter(default=Decimal("1.5"),
                            min=Decimal("1.0"), max=Decimal("5.0"),
                            step=Decimal("0.1"))
    body_ratio_breakout = Parameter(default=Decimal("0.6"),
                                    min=Decimal("0.5"), max=Decimal("0.9"),
                                    step=Decimal("0.05"))
    alternate_mode = Parameter(default=False)
```

The same configuration in the catalog-style `config.toml` format:

```toml
name = "elephant_edge_intraday"
title = "Elephant Edge (EE+) Intraday"
family = "intraday"
version = "1.0.0"
strategy = "tantra_strategies.strategies.elephant_edge:ElephantEdgeIntraday"

[params.instrument]
default = "NSE:NIFTY-INDEX"

[params.elephant_support_percentiles]
default = [25, 35]

[params.elephant_resistance_percentiles]
default = [63, 74]

[params.min_level_score]
default = 3
min = 0
max = 4
step = 1

[params.risk_per_trade_pct]
default = 0.5
min = 0.1
max = 2.0
step = 0.1

[params.trail_mode]
default = "atr"

[params.trail_atr_mult]
default = 2.0
min = 1.0
max = 5.0
step = 0.5
```

Every price, stop, and band in these examples stays a `Decimal`. The `Parameter` descriptors are the shipped `tantra_strategies.sdk.Parameter`, validated on assignment against `min`/`max`/`step`. The engine that consumes these descriptors is planned (see the banner above) — the descriptors themselves are testable today.

## Worked session walk-through (illustrative)

This session is **illustrative — not a real backtest.** It walks a hypothetical `NSE:NIFTY-INDEX` intraday session (2026-11-15, weekly expiry `2026-11-26`) through the designed EE+ workflow, using only the shipped SDK models.

**1. 09:15 anchor** — The first 1-minute bar of the session closes: open 24450, high 24485, low 24432, close 24440. Prior day: high 24560, low 24350, close 24490. ATR(14) on the trade bar ≈ 20, so a 0.25×ATR stop buffer is 5 points and `min_sl_atr × ATR` is 10 points.

**2. Build the LevelMap** — At 09:15 the session's level map is assembled from intraday percentiles, OI walls, order blocks, prior-day levels, dealer gamma, and max pain:

```python
from datetime import datetime
from decimal import Decimal

from tantra_strategies.sdk.levels import Level, LevelKind, LevelMap, LevelSide

nifty_map = LevelMap(
    instrument="NSE:NIFTY-INDEX",
    as_of=datetime(2026, 11, 15, 9, 15),
    levels=(
        Level("ee-els-1", LevelKind.ELEPHANT_SUPPORT_1, LevelSide.SUPPORT,
              Decimal("24430.00"), Decimal("20.00"), 2, "session-percentile-25"),
        Level("ee-els-2", LevelKind.ELEPHANT_SUPPORT_2, LevelSide.SUPPORT,
              Decimal("24410.00"), Decimal("20.00"), 2, "session-percentile-35"),
        Level("ee-oiw-p-1", LevelKind.OI_WALL_PUT, LevelSide.SUPPORT,
              Decimal("24400.00"), Decimal("15.00"), 4, "weekly-expiry-put-oi+building"),
        Level("ee-ob-1", LevelKind.ORDER_BLOCK, LevelSide.SUPPORT,
              Decimal("24395.00"), Decimal("12.00"), 3, "bullish-ob"),
        Level("ee-pdl", LevelKind.PREVIOUS_DAY_OHLC, LevelSide.SUPPORT,
              Decimal("24350.00"), Decimal("10.00"), 1, "prior-day-low"),
        Level("ee-ers-1", LevelKind.ELEPHANT_RESISTANCE_1, LevelSide.RESISTANCE,
              Decimal("24490.00"), Decimal("20.00"), 3, "session-percentile-63"),
        Level("ee-ers-2", LevelKind.ELEPHANT_RESISTANCE_2, LevelSide.RESISTANCE,
              Decimal("24510.00"), Decimal("20.00"), 2, "session-percentile-74"),
        Level("ee-pdh", LevelKind.PREVIOUS_DAY_OHLC, LevelSide.RESISTANCE,
              Decimal("24560.00"), Decimal("10.00"), 1, "prior-day-high"),
        Level("ee-gflip", LevelKind.GAMMA_FLIP, LevelSide.BOTH,
              Decimal("24480.00"), Decimal("10.00"), 1, "dealer-gamma"),
        Level("ee-mxp", LevelKind.MAX_PAIN, LevelSide.BOTH,
              Decimal("24400.00"), Decimal("10.00"), 2, "max-pain"),
    ),
)
```

Note: `ee-oiw-p-1` scores 4 (OI-wall alignment + building ΔOI + PCR tilt + long-gamma regime agreement); `ee-ers-1` scores 3 (overlaps the gamma flip).

**3. Chain snapshot** — The weekly expiry chain is snapshotted for OI walls and max pain:

```python
from tantra_strategies.sdk.levels import OptionLeg, OptionsSnapshot

chain = OptionsSnapshot(
    instrument="NFO:NIFTY-INDEX",
    expiry="2026-11-26",
    underlying_spot=Decimal("24450.00"),
    legs=(
        OptionLeg(Decimal("24400.00"), "PE", open_interest=Decimal("182000"),
                  open_interest_change=Decimal("9800")),
        OptionLeg(Decimal("24450.00"), "PE", open_interest=Decimal("154000")),
        OptionLeg(Decimal("24400.00"), "CE", open_interest=Decimal("169000")),
        OptionLeg(Decimal("24550.00"), "CE", open_interest=Decimal("141000")),
    ),
)

pain = chain.max_pain()
walls_ce = chain.call_walls(n=2)
walls_pe = chain.put_walls(n=2)
```

Max pain resolves to 24400 in this illustrative chain — the same strike as the put wall.

**4. Cluster & stop** — At 09:42 price pulls into the 24400 support cluster; a hammer forms (low 24390, close 24405) on 1.9× volume:

```python
from tantra_strategies.sdk.order import OrderSide

cluster = nifty_map.overlapping(Decimal("24400.00"))
band_low = min(level.band()[0] for level in cluster)
protection = strategy.stop_loss(
    OrderSide.BUY,
    (band_low, Decimal("24415.00")),
    buffer_atr=Decimal("5.00"),
)
```

Here `strategy` is a `Strategy` instance (shipped). `band_low` resolves to 24385 (the OI-wall band), the buffer is 0.25×ATR = 5, so the stop lands at 24380. `stop_loss` raises if the computed stop lands inside the band, and the planned entry 24410 gives `|entry − sl| = 30 ≥ min_sl_atr × ATR = 10`, so the check passes.

**5. Signal** — The level map, chain, and price action combine into a signal:

```python
from tantra_strategies.sdk.levels import SignalKind, StrategySignal

signal = StrategySignal(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    kind=SignalKind.REVERSAL,
    ref_levels=("ee-oiw-p-1", "ee-els-2"),
    confidence=Decimal("80"),
)
```

The filters that gate it: best reference-level score ≥ 3 (`ee-oiw-p-1` scores 4), the long-gamma regime allows `REVERSAL`-kind signals, a hammer at support on 1.9× volume, inside the entry window, and the first touch of the cluster.

**6. Position intent** — Sizing follows the risk budget:

```python
from tantra_strategies.sdk.levels import PositionIntent

intent = PositionIntent(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    quantity=Decimal("150"),
    entry=Decimal("24410.00"),
    stop=Decimal("24380.00"),
    target=Decimal("24490.00"),
    risk_amount=Decimal("6000"),
)
```

Risk = 0.5% of a 12,00,000 book = 6000; 30 points of distance × per-point value 75 → ~2.67 → 2 whole lots × 75 = 150 (illustrative — the planned risk layer applies `max_position_fraction` and basket caps downstream).

**7. Trail & square-off** — The position trails as price runs toward 24500:

```python
from tantra_strategies.sdk.stop_protection import StopUpdate

updated = strategy.trail_stop(
    OrderSide.BUY,
    protection,
    atr=Decimal("20.00"),
    extreme=Decimal("24500.00"),
)
stop_update = StopUpdate(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    old_stop=Decimal("24380.00"),
    new_stop=Decimal("24460.00"),
)
```

The ATR trail moves the stop by 2.0×ATR = 40 → 24460, and the `StopUpdate` flows to the strategy's `on_stop_update` handler. The trade ends at the target 24490, at the trail stop, or at the 15:10 square-off — every exit is a `Decimal`.

This walk-through is illustrative. The *models and helpers* — `LevelMap`, `OptionsSnapshot`, `StrategySignal`, `PositionIntent`, `stop_loss`, `trail_stop`, `StopUpdate` and friends — are shipped and testable today (via `SimulatedContext`), while the engine that auto-builds the map and picks entries is planned (`tantra-strategies` plan 0001). The numbers above show the workflow, not a backtest result.

## Related

- [Guide home](index.md)
- [EE+ overview](overview.md)
- [The Level Map](level-map.md)
- [Signals & Filters](signals.md)
- [Stops & Position Sizing](stops-positioning.md)
- [EE+ Studio & Chat Tools](studio.md)
- [Strategies overview](../index.md)
