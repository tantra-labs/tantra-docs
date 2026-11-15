# Risk

The **Risk** engine guards every decision before it reaches execution: the SEBI
pre-trade risk engine lives in `tantra-risk` (algo ID, OTR circuit breakers,
price bands, freeze limits). The gateway exposes decision explanation and
copula-based tail-risk estimation, and `risk_inspection` provides the
conversational inspection surface.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `explain_decision` | prompt + market context + risk checks for a historical decision | Plain-language explanation of why a decision passed or failed risk checks. |
| `tantra_copula_tail_risk` | `series_x[]`, `series_y[]` (req), `family` clayton\|gumbel (default clayton), `n_simulations` (default 5000), `seed` (default 42) | Kendall tau, tail dependence, joint VaR95. |

## Chat-tool surface

The conversational tool that also serves this engine (shipped in
`tantra-agent-chat-tools`, 32 read-only tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `risk_inspection` | Inspection of risk-engine state (`RiskInspectionTool`). |

## Example

```json
{
  "tool": "explain_decision",
  "arguments": {
    "prompt": "Buy 50 units NSE:RELIANCE-EQ at market",
    "market_context": {
      "symbol": "NSE:RELIANCE-EQ",
      "last_price": "2987.45",
      "upper_band": "3220.00",
      "lower_band": "2710.00"
    },
    "risk_checks": ["algo_id", "otr", "price_band", "freeze"]
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 14,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Decision passed all pre-trade risk checks",
  "data": {
    "checks": {
      "algo_id": "pass",
      "otr": "pass",
      "price_band": "pass",
      "freeze": "pass"
    }
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["check", "status"],
      "rows": [
        ["algo_id", "pass"],
        ["otr", "pass"],
        ["price_band", "pass"],
        ["freeze", "pass"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

Both gateway tools are shipped and live. The authoritative SEBI pre-trade
engine itself is the `tantra-risk` crate; the gateway surface explains and
inspects it rather than replacing it. `tantra_copula_tail_risk` is shared with
the [analytics](analytics.md) engine.
