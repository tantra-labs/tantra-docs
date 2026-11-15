# Elephant Edge (EE+) — Intraday Strategy Guide

> The Elephant Edge (EE+) intraday playbook: price action plus smart-money footprints —
> option open-interest walls, dealer-gamma regime, max pain, Order Blocks — traded against
> the Elephant two-support / two-resistance percentile zones on NSE index products.

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

## The idea in one paragraph

Market makers and institutions leave footprints: where open interest walls up, where
dealer gamma flips, where the prior day's range and the displacement candles sit. EE+
turns those footprints into a **level map** of support and resistance **bands**, scores
each level for confluence (0–4), and only trades when price arrives at a score ≥ 3 band
with a confirming trigger candle, volume participation and regime permission. Stops sit
beyond the entire level cluster; size is risk-based and rounded to whole lots; everything
is squared off at the end-of-window exit.

## Guide sections

| Section | Covers |
| :--- | :--- |
| [Overview](overview.md) | The concept, the Elephant percentile zones, the 09:15 anchor, the shipped-vs-designed split, the parameter reference. |
| [The Level Map](level-map.md) | Every level kind, the legend table, the 0–4 confluence score, and the shipped `Level` / `LevelMap` / `OptionsSnapshot` models. |
| [Signals](signals.md) | Breakout / reversal / retest triggers, trigger candles and filters, volume participation, time window and trade-count discipline. |
| [Stops & Positioning](stops-positioning.md) | Initial SL beyond the level cluster, ATR/swing trailing stops, the first-target rule, whole-lot risk sizing, caps, intraday square-off. |
| [EE+ Studio & Chat Tools](studio.md) | The planned Strategy Studio canvas, signal/stop panel, positioning table, planned API, and the planned `level_map` / `oi_walls` chat tools. |

## Status summary

| Layer | Status | Reference |
| :--- | :--- | :--- |
| SDK primitives (`Level`, `LevelMap`, `OptionsSnapshot`, `StrategySignal`, `PositionIntent`, `StopProtection`, `StopUpdate`, ...) | **Shipped & tested** (gap 0006 closed 2026-11-14) | `tantra_strategies/sdk/levels.py`, `tantra_strategies/sdk/stop_protection.py` |
| Strategy context & stop helpers (`StrategyContext.level_map()`, `Strategy.stop_loss()`, `on_stop_update`) | **Shipped & tested** | gap 0006 |
| EE+ strategy engine (level scoring, signals, sizing, square-off) | **Planned** | `tantra-strategies` plan 0001 |
| Strategy Studio | **Planned** | `tantra-ui` plan 0006 |
| `level_map` / `oi_walls` chat tools | **Planned** | `tantra-agent` plan 0011 |
| Research basis | Workspace root | `docs/research/elephant-edge-strategy.md` |
| Master plan | — | `docs/plans/0005` |

## Related guides

- [Strategies overview](../index.md)
- [Writing strategies](../writing_strategies.md)
- [Position management](../position_management.md)
- [Indicators](../indicators.md)
