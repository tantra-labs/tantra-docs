# Technicals

The **Technicals** engine exposes the indicator catalogue — 200+ indicators
and 61 candlestick patterns — plus the bounds used to validate indicator
parameters before a strategy runs. It is served by the `get_indicator_catalog`
gateway tool and the `market_indicators` chat tool.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `get_indicator_catalog` | none required (optional `_jq` filter) | The technicals catalogue: indicator IDs, families, and parameter bounds; candlestick-pattern catalogue. |

## Chat-tool surface

The conversational tool that also serves this engine (shipped in
`tantra-agent-chat-tools`, 32 read-only tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `market_indicators` | Indicator values computed over market history for a requested indicator/period. |

## Example

```json
{
  "tool": "get_indicator_catalog",
  "arguments": {}
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 2,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Technicals catalogue: 200+ indicators, 61 candlestick patterns",
  "data": {
    "indicators_count": 214,
    "candlestick_patterns_count": 61
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["id", "family", "bounds"],
      "rows": [
        ["sma", "moving_average", "period 2..200"],
        ["rsi", "oscillator", "period 2..100"],
        ["macd", "oscillator", "fast 2..100, slow 2..200, signal 2..50"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

`get_indicator_catalog` is a shipped, live gateway tool and is the discovery
entry point for the Technicals engine. See also the [market](market.md)
engine's `market_indicators` chat tool.
