# Calc

The **Calc** engine computes Indian statutory trading costs: STT, GST, stamp
duty, and exchange charges. It is served through the `research_calc` chat tool
(`ResearchCalcTool`); there is no dedicated MCP quant tool.

## MCP gateway tools

The Calc engine has **no dedicated MCP quant tool**. Statutory cost
calculation is served through the chat-tool surface below.

## Chat-tool surface

This conversational tool lives in `tantra-agent-chat-tools` (32 read-only
tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `research_calc` | Statutory cost breakdown for a trade. The underlying calculator exposes e.g. `tantra_calc_statutory_costs` with `segment`, `turnover`, `side`. |

## Example

```json
{
  "tool": "tantra_calc_statutory_costs",
  "arguments": {
    "segment": "equity_intraday",
    "turnover": "250000.00",
    "side": "sell"
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 3,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Statutory costs 87.55 on 250000.00 sell turnover (0.035%)",
  "data": {
    "segment": "equity_intraday",
    "turnover": "250000.00",
    "side": "sell",
    "stt": "62.50",
    "exchange_charges": "7.50",
    "stamp_duty": "0.00",
    "gst": "12.60",
    "sebi_charges": "0.25",
    "total": "87.55"
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["component", "amount"],
      "rows": [
        ["STT", "62.50"],
        ["Exchange charges", "7.50"],
        ["Stamp duty", "0.00"],
        ["GST", "12.60"],
        ["SEBI charges", "0.25"],
        ["Total", "87.55"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

The calc surface is **conversation-surface only** — no dedicated MCP quant
tool. The breakdown above is illustrative; the calculator applies the current
statutory schedules, which vary by `segment` and `side`.
