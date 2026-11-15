# Derivatives

The **Derivatives** engine prices options with Black–Scholes–Merton and
returns the Greeks; the options chain is served conversationally.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_price_derivatives` | `spot`, `strike`, `t_years`, `risk_free_rate`, `volatility` (req), `option_type` call\|put (req), `dividend_yield` (default 0) | Black–Scholes–Merton price + Delta/Gamma/Vega/Theta/Rho. |

## Chat-tool surface

The conversational tool that also serves this engine (shipped in
`tantra-agent-chat-tools`, 32 read-only tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `options_chain` | Options chain for an underlying. |

## Example

```json
{
  "tool": "tantra_price_derivatives",
  "arguments": {
    "spot": "24500.00",
    "strike": "24600.00",
    "t_years": "0.08",
    "risk_free_rate": "0.065",
    "volatility": "0.14",
    "option_type": "call",
    "dividend_yield": "0"
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 7,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Call premium 412.15; delta 0.55",
  "data": {
    "option_type": "call",
    "premium": "412.15",
    "delta": "0.55",
    "gamma": "0.0004",
    "vega": "1.85",
    "theta": "-0.62",
    "rho": "1.20"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Premium", "value": "412.15" },
        { "label": "Delta", "value": "0.55" },
        { "label": "Gamma", "value": "0.0004" },
        { "label": "Vega", "value": "1.85" },
        { "label": "Theta", "value": "-0.62" },
        { "label": "Rho", "value": "1.20" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

The tool is shipped and live. `options_chain` supplies the market-side chain;
`tantra_price_derivatives` prices any single option from the parameters.
