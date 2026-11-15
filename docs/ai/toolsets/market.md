# Market

The **Market** engine aggregates NSE/BSE market data across quotes, history,
indicators, symbol search, L2 depth, options chains, block deals, corporate
actions, institutional flows, delivery analysis, OI buildup, and macro series.
It is the data-facing entry point of the pipeline and is served entirely
through the conversational tool surface — there is no dedicated MCP quant tool
for market data yet.

## MCP gateway tools

The Market engine has **no dedicated MCP quant tool**. Market data is served
through the chat-tool surface below.

!!! note "Stub surfaces"
    `institutional_flows` and `market_depth` are shipped as
    `PortError::unavailable` stubs citing upstream data gaps (`tantra-data`
    0017/0018 and `tantra-market` 0006). Do not assume live data where only
    the stub is shipped.

## Chat-tool surface

These conversational tools live in `tantra-agent-chat-tools` (32 read-only
tools + 2 LocalWrite trade tools) and serve the Market engine:

| Tool | Returns |
| :--- | :--- |
| `market_quote` | Latest quote for a symbol. |
| `market_history` | OHLCV history (bars). |
| `market_indicators` | Indicator values computed over market history. |
| `market_search` | Symbol/universe search. |
| `macro_series` | Macroeconomic time series. |
| `block_deals` | Exchange block-deal prints. |
| `options_chain` | Options chain for an underlying. |
| `corporate_actions` | Dividends, splits, bonuses, buybacks. |
| `market_depth` | L2 5-level depth (stub — see note above). |
| `institutional_flows` | FII/DII flows (stub — see note above). |
| `delivery_analysis` | Delivery-delivered% analysis. |
| `oi_buildup` | Open-interest buildup. |

!!! note
    Chat-tool argument schemas are defined per tool; the arguments in the
    example below are illustrative.

## Example

```json
{
  "tool": "market_quote",
  "arguments": {
    "symbol": "NSE:RELIANCE-EQ"
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 4,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Latest quote for RELIANCE-EQ",
  "data": {
    "symbol": "NSE:RELIANCE-EQ",
    "last_price": "2987.45",
    "change_pct": "0.62",
    "price_band_upper": "3220.00",
    "price_band_lower": "2710.00"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "LTP", "value": "2987.45" },
        { "label": "Change", "value": "0.62%" },
        { "label": "Upper band", "value": "3220.00" },
        { "label": "Lower band", "value": "2710.00" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

Market data is **conversation-surface only** — there is no dedicated MCP quant
tool yet. `market_depth` and `institutional_flows` are shipped as
`PortError::unavailable` stubs; the remaining tools carry live data where the
underlying feeds are connected.

Related pages: [technicals](technicals.md) (indicators), [derivatives](derivatives.md) (options pricing).
