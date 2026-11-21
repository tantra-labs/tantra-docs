# Strategy Loop, Graphical Layers & Expiry Hedges

The EE+ outer-buffer workflow is one instance of a **generic strategy loop**: evaluate any registered
strategy on any symbol / timeframe / horizon, sweep its parameters with out-of-sample checks, size a
Day / Weekly / Monthly (or commodity-cycle) hedge, and draw the result as a layered **OverlayScene** on
a chart. Nothing here is EE-specific — ORB-15 and the Predictive-Ranges recipes use the same path.
Root plan 0015 (Track T21) is the design record.

## The loop

| Step | Runtime endpoint (`/api/v2`) | Agent tool |
|------|------------------------------|------------|
| Evaluate a strategy run (KPIs, trades, tight-vs-buffered stop comparison, scene) | `POST /studies/strategy-loop/evaluate` | `strategy_loop_eval` |
| Bounded parameter sweep (`sl_buffer_atr`, `horizon_bars`, `target_r` grids; ≤ 64 candidates; IS/OOS + DSR) | `POST /studies/strategy-loop/sweep` | `strategy_loop_sweep` |
| Expiry hedge recommendation (zones, outer buffer, live option chain or an honest theoretical fallback) | `POST /studies/strategy-loop/recommend-hedge` | `strategy_hedge_recommend` |
| Package a tested candidate's scene for a chart | — (pure) | `chart_scene_annotate` |

All four agent tools are read-only. They are available in the web/TUI chat (the runtime calls its own
loop engine in-process) and over MCP (`tantra-agent-mcp`, which proxies the runtime REST API configured by
`TANTRA_RUNTIME_URL`). Every number in a tool result comes from the runtime; when bars, chains or the
engine are unavailable the tool returns an explicit *unavailable* error rather than sample data.

Requests are validated twice: the agent rejects unknown fields and out-of-range grids, and the runtime's
own request types (`deny_unknown_fields`) remain the authority. Required fields for an evaluation are
`strategy_id`, `instrument_id`, `asset_class` (`index`, `fno_stock`, `etf`, `equity`, `forex`,
`commodity`), `start_date` and `end_date`.

## Graphical layers (OverlayScene)

A scene has six layer groups, each toggleable independently:

- **signals** — entry/exit markers (buy/sell, sweep, retest, target hit) and trade connectors with realized R;
- **bands** — shaded zones (S1/S2/R1/R2, EE demand/supply) and dashed levels;
- **stops** — initial, trailing, breakeven and target lines (tight vs. outer-buffer shown together);
- **indicators** — price-unit series on the price pane; series named `pane:<name>` (ratios, oscillators,
  states) draw in a dedicated lower strip;
- **hints** — inspectable notes anchored to a bar (title, detail, metrics);
- **hedges** — hedge-leg strikes for the recommended structure.

Where scenes render:

- **Web** — the chart's generic OverlayScene renderer (price pane + lower strip). The Experimental-Analysis
  **Indicator Lab** tab plots any `tantra_library` entry or signal study through it.
- **Chat** — tool results carry an `OverlayScene` display block (see
  [Result protocol](../../ai/result_protocol.md)); clients offer *Render on Chart*.
- **TUI / CLI** — the Strategy Lab view projects scenes onto a terminal canvas; result blocks show a
  per-layer summary. `tantra study-loop --export-scene` writes the scene JSON.

## Expiry hedges

`strategy_hedge_recommend` sizes hedges for the chosen `expiry_horizon` (day, weekly, monthly expiry, or
commodity cycle), anchored on the EE zones and the outer-buffer stop. When a live option chain is
available its quotes are used (`live_chain_available: true`); otherwise the response says so and the legs
are theoretical. Lot size, tick size and capital can be overridden per request.

## Related

- [Studio & chat tools](studio.md) · [Stops & positioning](stops-positioning.md) ·
  [Reference & worked example](reference.md)
