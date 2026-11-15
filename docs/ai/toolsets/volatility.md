# Volatility

The **Volatility** engine models conditional volatility with GARCH: fit,
conditional volatility forecasts, half-life, and persistence.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_garch_volatility` | `returns[]` (req), `p` (default 1), `q` (default 1), `forecast_horizon` (default 5), `annualization` (default 252) | GARCH(1,1) fit; conditional volatility forecasts, half-life, persistence. |

## Chat-tool surface

The Volatility engine has no chat-tool surface; volatility modelling is served
exclusively by the MCP gateway tool above.

## Example

```json
{
  "tool": "tantra_garch_volatility",
  "arguments": {
    "returns": ["0.0012", "-0.0008", "0.0021", "-0.0014", "0.0009"],
    "p": 1,
    "q": 1,
    "forecast_horizon": 5,
    "annualization": 252
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 18,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "GARCH(1,1): annualized vol 14.3%, half-life 21 days",
  "data": {
    "p": 1,
    "q": 1,
    "annualized_vol_pct": "14.3",
    "half_life_days": 21,
    "persistence": "0.96",
    "forecast_horizon": 5,
    "forecast_vol_pct": ["14.6", "14.5", "14.4", "14.4", "14.4"]
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Annualized vol", "value": "14.3%" },
        { "label": "Half-life", "value": "21d" },
        { "label": "Persistence", "value": "0.96" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

The tool is shipped and live. The default `p=1`, `q=1` configuration is the
classic GARCH(1,1) model.
