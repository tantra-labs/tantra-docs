# Scanner

The **Scanner** engine runs universe screening across 4,000 fields. It is
served through the `screener` chat tool (`ScreenerQueryTool`); there is no
dedicated MCP quant tool yet.

## MCP gateway tools

The Scanner engine has **no dedicated MCP quant tool**. Screening is served
through the chat-tool surface below.

## Chat-tool surface

This conversational tool lives in `tantra-agent-chat-tools` (32 read-only
tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `screener.query` | Echoes the screened `universe` size and `metric` for a screening request across 4,000 fields (`ScreenerQueryTool`). |

!!! note
    `ScreenerQueryTool` (in `tantra-agent-tools`) validates a symbol `universe`
    array and a `metric` string; the full 4,000-field screening pipeline is a
    deeper surface (honest status below).

## Example

```json
{
  "tool": "screener.query",
  "arguments": {
    "universe": ["NSE:NIFTY50-INDEX", "NSE:BANKNIFTY-INDEX"],
    "metric": "rsi_14"
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 48,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "2 symbols screened on rsi_14",
  "data": {
    "universe_size": 2,
    "metric": "rsi_14"
  },
  "blocks": [],
  "refs": {}
}
```

## Status

Screening is **conversation-surface only** — no dedicated MCP quant tool yet.
The `screener` chat tool is live.
