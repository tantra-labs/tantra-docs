# 0003 — Elephant Edge (EE+) Strategy User Guide

**Status**: Proposed
**Target Scope**: `docs/` (MkDocs Material)
**Depends on**: `tantra-strategies` plan 0001 (strategy spec), `tantra-ui` plan
0006 (studio screens), `tantra-agent` plan 0011 (chat tools)
**Master plan**: root [`docs/plans/0005-elephant-edge-strategy-platform.md`](../../../docs/plans/0005-elephant-edge-strategy-platform.md)

## 0. Objective

Document the EE+ intraday strategy end-to-end for traders: how the level map
is built, how buy/sell signals, SL/TSL, and positioning work, how to configure
and run the strategy, and how to read the Strategy Studio — with code snippets
that correspond to tested code in `tantra-strategies` (per this repo's
"code snippets must correspond to tested code" rule).

## 1. Pages

1. **`docs/strategies/elephant-edge/overview.md`** — the concept: price action
   + smart-money (market-maker / institutional) moves, the two-support /
   two-resistance Elephant percentile zones, the first-1-minute-candle anchor,
   and the research basis (`docs/research/elephant-edge-strategy.md`).
2. **`docs/strategies/elephant-edge/level-map.md`** — every level kind
   (Elephant zones, PDH/PDL, OI walls, gamma flip, max pain, strike rounds,
   **Order Blocks**) with a legend diagram and the confluence score (0–4).
3. **`docs/strategies/elephant-edge/signals.md`** — buy/sell signal rules:
   trigger candles (marubozu / hammer / engulfing), breakout vs reversal vs
   retest, volume participation, time window, trade-count discipline.
4. **`docs/strategies/elephant-edge/stops-positioning.md`** — SL placement
   (beyond the level cluster + buffer), ATR/swing trailing stops with
   activation-after-R, risk-based position sizing to whole lots, caps, and the
   intraday square-off.
5. **`docs/strategies/elephant-edge/studio.md`** — reading the EE+ Strategy
   Studio (level-map canvas, signal/stop lines, positioning table) and the
   `level_map`/`oi_walls` chat tools.
6. **`docs/strategies/elephant-edge/reference.md`** — parameter reference
   (mirrors the strategy's declarative `Parameter`s), configuration example,
   and a worked session walk-through.

## 2. Quality Gates

- `mkdocs build --strict` passes with no broken links/unresolved anchors.
- Snippets import-tested against `tantra-strategies` (TDD note: any code
  snippet ships with its `tests/` counterpart first).
- Tables and math fences valid (strict Markdown linting).

## 3. Related

- Strategy spec: [`tantra-strategies/docs/plans/0001-elephant-edge-strategy.md`](../../../tantra-strategies/docs/plans/0001-elephant-edge-strategy.md)
- Studio plan: [`tantra-ui/docs/plans/0006-elephant-edge-strategy-studio.md`](../../../tantra-ui/docs/plans/0006-elephant-edge-strategy-studio.md)
- Research: [`docs/research/elephant-edge-strategy.md`](../../../docs/research/elephant-edge-strategy.md)
