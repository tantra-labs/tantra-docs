# EE+ Strategy Studio & Chat Tools

!!! warning "Implementation status"
    The **EE+ Strategy Studio and chat tools are planned, not shipped.** The Studio is
    `tantra-ui` plan 0006 and the `level_map` / `oi_walls` chat tools are `tantra-agent`
    plan 0011 (master plan: `docs/plans/0005`; strategy spec: `tantra-strategies` plan 0001;
    research basis `docs/research/elephant-edge-strategy.md`, workspace root). Everything
    on this page describes the **planned** product in design/future tense. What is real
    today is the SDK surface it will render — `LevelMap`, `StrategySignal`,
    `StopUpdate`, `PositionIntent` (see [The Level Map](level-map.md) and
    [Signals](signals.md)) — plus the honest degradation paths below.

## What the Studio will be

The EE+ Strategy Studio is a planned web workbench (Leptos/WASM, `tantra-ui` plan 0006)
for watching the level map, signals and stops live during the session. It is intended to
render the shipped SDK models directly: a `LevelMap` becomes the canvas, a
`StrategySignal` becomes a card, a `StopUpdate` moves a line.

## Level-map canvas (planned)

- The session anchor: the first 1-minute candle (09:15 IST).
- The Elephant zones shaded by confluence score — a score ≥ 3 zone is filled, a score < 3
  zone is hatched and not tradeable.
- Overlays: OI walls, gamma flip, max pain, PDH/PDL, strike-round lines, and Order Block
  boxes.
- A regime badge: **long-gamma** vs **short-gamma**, from the current `GAMMA_FLIP` level.

## Signals & Stop panel (planned)

- Entry line, initial SL line, and the trailing stop line updated by each `StopUpdate`.
- A per-signal card showing `ref_levels`, level score, `confidence`, and current R:R.

## Positioning table (planned)

- One row per `PositionIntent`: side, whole-lot quantity, risk in ₹, entry / stop / target.
- A square-off countdown to 15:10.
- A TUI Positioning tab and a `tantra-cli elephant` report for terminal users.

## Planned API endpoints

The Studio is designed to consume these endpoints (built from `tantra-core` types):

- `GET /level-map/{date}` — the session `LevelMap` with confluence scores.
- `GET /signals/{date}` — the session's `StrategySignal` log.
- `GET /option-chain/walls/{instrument}` — OI-wall and max-pain data.
- `WS /ws/live` — streaming `StopUpdate` and fill events.

## Chat tools (planned)

The planned `tantra-agent` chat surface (plan 0011) exposes two read-only tools backed by
the SDK:

| Tool | Returns | Notes |
| :--- | :--- | :--- |
| `level_map` | the session `LevelMap` with confluence scores | read-only |
| `oi_walls` | top-2 CE / PE OI strikes plus ΔOI building scores and PCR | read-only |

Both are `ToolRisk::ReadOnly` and will answer honestly with an `unavailable` result until
the upstream data gaps close.

## Honest degradation today

`StrategyContext.level_map()` and `StrategyContext.options_snapshot(instrument, expiry)`
are shipped, but a `LiveContext` raises `LevelsUnavailable` / `OptionsUnavailable` until
the upstream data is live: `tantra-market` gap 0005 (chain / live level data) and
`tantra-data` gap 0016 (open-interest history). `SimulatedContext` seeds its level and OI
stores, so every model and the Studio's rendering logic are fully testable offline.

## Related

- [The Level Map](level-map.md) — the data the Studio draws
- [Signals](signals.md)
- [Stops & Positioning](stops-positioning.md)
- [Reference & Worked Example](reference.md)
- [Strategies overview](../index.md)
