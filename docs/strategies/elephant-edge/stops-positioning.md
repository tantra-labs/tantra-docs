# Stops & Positioning

!!! warning "Implementation status"
    The **EE+ stop and sizing engine is planned, not shipped** (strategy spec:
    `tantra-strategies` plan 0001; master plan: `docs/plans/0005`), grounded in the
    research basis `docs/research/elephant-edge-strategy.md` (workspace root). The rules
    below describe the **designed** behavior in future tense. The `StopProtection`,
    `TrailMode`, `StopUpdate` and `PositionIntent` models in the snippets **are shipped and
    tested** (gap 0006, closed 2026-11-14); `Strategy.stop_loss()` / `Strategy.trail_stop()`
    helpers and the `on_stop_update` lifecycle hook are shipped SDK surface too.

## Initial stop placement

Every signal attaches a `StopProtection`. The initial stop always sits **beyond the level
cluster + buffer**, never inside the band:

- **Reversal at support**: `SL = level_low − buffer`, where
  `buffer = sl_buffer_atr × ATR` (default `0.25`).
- **Breakout long**: `SL = band_low − buffer` — beyond the *broken* band on the opposite
  side.
- **Mirror for shorts**: reversal at resistance → `SL = level_high + buffer`; breakout
  short → `SL = band_high + buffer`.

All values are `Decimal`; the stop must clear the cluster (`LevelMap.overlapping(...)`
around the level) so one re-test does not stop the trade.

**Minimum distance guard**: if `|entry − sl| < min_sl_atr × ATR` (default `0.5`), the
setup is skipped — a stop tighter than half an ATR is noise, and the position would be
unwound before the thesis plays out.

## Trailing (TSL)

Trailing activates only after the trade reaches `activation_after_r` (default `1.0R`).
`TrailMode` (from `tantra_strategies.sdk.stop_protection`):

| Mode | Rule |
| :--- | :--- |
| `ATR` | per bar, longs: `stop = max(sl, highest_close_since_entry − trail_atr_mult × ATR)`; mirror for shorts. Default `trail_atr_mult = 2.0` |
| `SWING` | park the stop under the most recent higher-low (lower-high for shorts) |
| `OFF` | fixed SL only — allowed only when `allow_fixed_sl_only` is on, and flagged for the risk gate |

Trail updates are emitted as `StopUpdate` events to `on_stop_update`, so `tantra-exec`
(gap 0003) can modify the resting stop and `tantra-ledger` (gap 0012) can journal them.

## First-target rule

The default target is the **next confluence level in the trade direction** (the closest
score ≥ 3 level beyond entry). If the IV-implied expected daily move cannot reach it at
≥ 1:2 R:R, the setup is skipped — the strategy does not take a trade whose target is
unreachable in the day.

## Position sizing

A `PositionIntent` is emitted per signal:

- Risk per trade: `risk_per_trade_pct` (default 0.5%) of equity.
- Quantity:
  `qty = (equity × risk_pct) / (|entry − sl| × instrument_value_per_unit)`,
  rounded **down to whole lots**.
- Caps: `max_position_fraction` (default 0.25 of equity), basket `RiskBudget.max_loss`,
  and `max_trades_per_day`.
- `alternate_mode` forces the next signal to the opposite side.

## Intraday square-off

Flatten on `on_stop`, or at the end-of-window exit — default `square_off_time` 15:10. No
positions are ever held past the window; EE+ is strictly intraday.

## Shipped SDK: `StopProtection`, `StopUpdate`, `PositionIntent`

```python
from decimal import Decimal

from tantra_strategies.sdk.order import OrderSide
from tantra_strategies.sdk.stop_protection import (
    StopProtection,
    StopUpdate,
    TrailMode,
)

protection = StopProtection(
    sl=Decimal("24412.00"),
    trail=TrailMode.ATR,
    trail_distance=Decimal("12.50"),       # 2 x ATR(6.25) on the trade bar
    activation_after_r=Decimal("1.0"),     # trail only after 1R in our favour
)

protection.to_dict()
# {'sl': '24412.00', 'trail': 'atr', 'trail_distance': '12.50', 'activation_after_r': '1.0'}

update = StopUpdate(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    old_stop=Decimal("24412.00"),
    new_stop=Decimal("24470.00"),
)
```

`StopProtection` validates `sl > 0`, `trail_distance >= 0`, `activation_after_r >= 0`.
The sizing intent uses the shipped `PositionIntent` model:

```python
from decimal import Decimal

from tantra_strategies.sdk.levels import PositionIntent
from tantra_strategies.sdk.order import OrderSide

intent = PositionIntent(
    instrument="NSE:NIFTY-INDEX",
    side=OrderSide.BUY,
    quantity=Decimal("75"),          # whole lots, rounded down
    entry=Decimal("24505.00"),
    stop=Decimal("24412.00"),
    target=Decimal("24620.00"),      # next confluence level in trade direction
    risk_amount=Decimal("6000"),     # 0.5% of a 12,00,000 equity book
)
```

The `Strategy.stop_loss(...)` / `Strategy.trail_stop(...)` helpers and the `on_stop_update`
lifecycle hook are shipped (gap 0006): the helpers construct and validate a
`StopProtection`, and the hook receives `StopUpdate` events so downstream execution and
ledger slices can react.

## Related

- [The Level Map](level-map.md) — bands, clusters and the confluence score
- [Signals](signals.md) — what a signal carries into stop placement
- [Position management](../position_management.md) — the broader SDK position rules
- [EE+ overview](overview.md)
- [Reference & Worked Example](reference.md)
- [Strategies overview](../index.md)
