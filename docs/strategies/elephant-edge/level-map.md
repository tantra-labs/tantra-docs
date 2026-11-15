# The Elephant Edge Level Map

!!! warning "Implementation status"
    The **EE+ level-map engine is planned, not shipped** (strategy spec: `tantra-strategies`
    plan 0001; master plan: `docs/plans/0005`), grounded in the research basis
    `docs/research/elephant-edge-strategy.md` (workspace root). This page describes the
    **designed** scoring and level construction in design/future tense. The `Level`,
    `LevelMap`, `LevelKind`, `LevelSide`, `OptionsSnapshot` and `OptionLeg` models below
    **are shipped and tested** (gap 0006, closed 2026-11-14) — the snippets are real SDK
    surface.

## What the level map is

A `LevelMap` is the strategy's single page of truth for where the smart money is parked.
It is built **once at the open anchor** — the first 1-minute bar, 09:15 IST — and
**re-scored every N bars (default 5)**. Every tradable level is a **band**
(`price ± band_half_width`), never a single line; a wick that pokes a line is noise, a
price that trades inside a band is a reaction candidate.

## Legend

| Kind (SDK) | Human name | Source | Side | Notes |
| :--- | :--- | :--- | :--- | :--- |
| `ELEPHANT_SUPPORT_1` / `ELEPHANT_SUPPORT_2` | Elephant Support 1 / 2 | session-range percentile zones (defaults 25 / 35) | support | the "two supports" — bands, not lines |
| `ELEPHANT_RESISTANCE_1` / `ELEPHANT_RESISTANCE_2` | Elephant Resistance 1 / 2 | session-range percentile zones (defaults 63 / 74) | resistance | the "two resistances" — bands, not lines |
| `PREVIOUS_DAY_OHLC` | PDH / PDL / PDC | prior session O/H/L/C | both | stop-cluster and breakout levels |
| `OI_WALL_CALL` | Call OI wall | top-2 CE OI strikes above spot, nearest weekly expiry | resistance | from the designed `ChainReader` / `OpenInterestStore` |
| `OI_WALL_PUT` | Put OI wall | top-2 PE OI strikes below spot, nearest weekly expiry | support | from the designed `ChainReader` / `OpenInterestStore` |
| `GAMMA_FLIP` | Gamma flip | spot level where net dealer gamma crosses zero | both | regime boundary |
| `GAMMA_WALL_CALL` | Gamma wall (calls) | largest gamma-concentration CE strikes | resistance | strongest mechanical hedging levels |
| `GAMMA_WALL_PUT` | Gamma wall (puts) | largest gamma-concentration PE strikes | support | strongest mechanical hedging levels |
| `MAX_PAIN` | Max pain | option-chain max-pain strike | both | expiry-day target/context, not a morning S/R line |
| `STRIKE_ROUND` | Strike round | round-number / strike-interval lines (50 / 100) | both | liquidity clusters |
| `ORDER_BLOCK` | Order Block | last opposite-color candle before a displacement move | resistance (bearish OB) / support (bullish OB) | smart-money resting-order footprints |

## The confluence score (0–4)

Each level carries a `score` from 0 to 4. The score is summed only over **distinct sources
overlapping within the band** — the default band width is one strike or 0.5×ATR, whichever
is wider:

| Component | +1 when |
| :--- | :--- |
| Level alignment | the level overlaps an OI wall, a PDH/PDL line, a gamma wall, or an Order Block |
| Building wall | the overlapping wall is *building* — intraday ΔOI > 0 |
| PCR / IV-skew tilt | OI PCR > 1 → support side preferred; PCR < 0.7 → resistances firmer |
| Regime agreement | the dealer-gamma regime agrees with the planned play: long-gamma + Reversal, short-gamma + Breakout |

**Levels with score < 3 are not tradeable.** The `score` field is validated
`0 <= score <= 4` at construction.

## Shipped SDK: `Level` and `LevelMap`

```python
from datetime import datetime
from decimal import Decimal

from tantra_strategies.sdk.levels import (
    Level,
    LevelKind,
    LevelMap,
    LevelSide,
)

nifty_map = LevelMap(
    instrument="NSE:NIFTY-INDEX",
    as_of=datetime(2026, 11, 15, 9, 15),  # 09:15 IST anchor
    levels=(
        Level(
            level_id="ee-els-1",
            kind=LevelKind.ELEPHANT_SUPPORT_1,
            side=LevelSide.SUPPORT,
            price=Decimal("24450.00"),
            band_half_width=Decimal("37.50"),
            score=4,                     # aligns with put OI wall + PCR > 1
            source="session-percentile-25",
        ),
        Level(
            level_id="ee-oiw-p-1",
            kind=LevelKind.OI_WALL_PUT,
            side=LevelSide.SUPPORT,
            price=Decimal("24400.00"),
            band_half_width=Decimal("25.00"),
            score=3,
            source="weekly-expiry-put-oi",
        ),
        Level(
            level_id="ee-gflip",
            kind=LevelKind.GAMMA_FLIP,
            side=LevelSide.BOTH,
            price=Decimal("24510.00"),
            band_half_width=Decimal("10.00"),
            score=2,                     # regime boundary, informational
            source="dealer-gamma",
        ),
    ),
)

# The two supports / two resistances from the session range.
for level in nifty_map.supports():
    low, high = level.band()             # (price - half_width, price + half_width)
    print(level.level_id, level.kind, low, high)

# Levels whose band contains 24455.00, or intersects price +/- 10.00.
hit = nifty_map.overlapping(Decimal("24455.00"), width=Decimal("10.00"))
```

Notes on the shipped surface:

- `Level.price > 0`, `band_half_width >= 0` and `0 <= score <= 4` are validated at
  construction.
- `Level.band()` returns `(price − half_width, price + half_width)`.
- `LevelMap.supports()` / `resistances()` split levels by `LevelSide`.
- `LevelMap.overlapping(price, width=None)` returns the levels whose band contains the
  price or intersects `price ± width` — the building block for scoring a hit and for
  merging the level cluster when placing stops.

## The option chain: `OptionsSnapshot`

The OI-wall and gamma inputs come from the option chain surface. The model is shipped and
top-n helpers are tested:

```python
from decimal import Decimal

from tantra_strategies.sdk.levels import (
    OptionLeg,
    OptionsSnapshot,
)

chain = OptionsSnapshot(
    instrument="NFO:NIFTY-INDEX",
    expiry="2026-11-26",
    underlying_spot=Decimal("24550.00"),
    legs=(
        OptionLeg(
            strike=Decimal("24600"), option_type="CE",
            open_interest=Decimal("182000"),
            open_interest_change=Decimal("12500"),   # building -> +1 score
        ),
        OptionLeg(strike=Decimal("24650"), option_type="CE",
                  open_interest=Decimal("154000")),
        OptionLeg(
            strike=Decimal("24500"), option_type="PE",
            open_interest=Decimal("169000"),
            open_interest_change=Decimal("9800"),
        ),
        OptionLeg(strike=Decimal("24450"), option_type="PE",
                  open_interest=Decimal("141000")),
    ),
)

pain = chain.max_pain()           # Decimal | None
walls_ce = chain.call_walls(n=2)  # top-2 CE legs by open interest
walls_pe = chain.put_walls(n=2)   # top-2 PE legs by open interest
```

`OptionLeg.option_type` is restricted to `{"CE", "PE"}`. Under the design, OI walls become
`OI_WALL_CALL` / `OI_WALL_PUT` levels (resistance above spot for CE, support below spot for
PE) and the max-pain strike becomes a `MAX_PAIN` level.

## Reading the map

- **Elephant zones** define the reaction frame; PDH/PDL and strike rounds define the
  break-out frame.
- **OI walls** are the earliest proxy for where market makers defend; a wall that is
  *building* (ΔOI > 0) scores an extra point.
- **Gamma flip** tells you the regime: below the flip the dealer is long-gamma (pin and
  reversal behaviour), above it short-gamma (trend and break behaviour).
- **Order Blocks** point at the footprints of the last displacement move — the resting
  orders of whoever moved price.

## Availability

`StrategyContext.level_map()` and `StrategyContext.options_snapshot(instrument, expiry)`
degrade honestly: until the upstream data gaps close (`tantra-market` gap 0005 for chain /
live level data, `tantra-data` gap 0016 for open-interest history), a `LiveContext` raises
`LevelsUnavailable` / `OptionsUnavailable`. `SimulatedContext` seeds its level and OI
stores so the models are fully testable today. See also [EE+ Studio & Chat Tools](studio.md)
and the [EE+ overview](overview.md).
