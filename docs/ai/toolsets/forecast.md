# Forecast

The **Forecast** engine produces time-series point forecasts with prediction
intervals across six model families.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_forecast_series` | `series[]` (req), `horizon` (req ≥1), `model` enum theta\|ets\|holt_winters\|arima\|tbats\|gradient_boost, `seasonal_period`, `p`/`d`/`q`, `lags`/`n_estimators`/`max_depth`/`learning_rate` | Point forecast plus prediction interval for the horizon. |

## Chat-tool surface

The Forecast engine has no chat-tool surface; forecasting is served
exclusively by the MCP gateway tool above.

## Example

```json
{
  "tool": "tantra_forecast_series",
  "arguments": {
    "series": ["24500.0", "24610.0", "24750.0", "24690.0", "24830.0"],
    "horizon": 5,
    "model": "theta",
    "seasonal_period": 5
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 26,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Theta forecast: 5-step point forecast with 95% prediction interval",
  "data": {
    "model": "theta",
    "horizon": 5,
    "point_forecast": ["24910.0", "24990.0", "25070.0", "25150.0", "25230.0"],
    "lower_95": ["24720.0", "24750.0", "24780.0", "24810.0", "24840.0"],
    "upper_95": ["25100.0", "25230.0", "25360.0", "25490.0", "25620.0"]
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["step", "point", "lower_95", "upper_95"],
      "rows": [
        ["1", "24910.0", "24720.0", "25100.0"],
        ["2", "24990.0", "24750.0", "25230.0"],
        ["3", "25070.0", "24780.0", "25360.0"],
        ["4", "25150.0", "24810.0", "25490.0"],
        ["5", "25230.0", "24840.0", "25620.0"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

The tool is shipped and live. The `model` enum selects the forecast family;
ARIMA-family parameters (`p`/`d`/`q`) and gradient-boost hyperparameters
(`lags`/`n_estimators`/`max_depth`/`learning_rate`) apply per model.
