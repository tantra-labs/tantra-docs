# Backtest

The **Backtest** engine validates strategy manifests and dispatches backtests
to the honba-ya runtime.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `check_spec` | strategy manifest | Manifest validation result (no backtest executed). |
| `run_backtest` | strategy manifest, data range, parameters | Dispatch to the honba-ya runtime; backtest results and metrics. |

## Chat-tool surface

The Backtest engine has no chat-tool surface; validation and backtesting are
served exclusively by the MCP gateway tools above.

## Example

```json
{
  "tool": "run_backtest",
  "arguments": {
    "strategy": "ma_cross",
    "symbols": ["NSE:NIFTY50-INDEX"],
    "start": "2024-01-01",
    "end": "2025-12-31",
    "parameters": {
      "fast_period": 10,
      "slow_period": 30
    }
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 1850,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Backtest complete: 23 trades, Sharpe 1.42",
  "data": {
    "runtime": "honba-ya",
    "trades": 23,
    "sharpe": "1.42",
    "max_drawdown_pct": "-8.7"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Trades", "value": "23" },
        { "label": "Sharpe", "value": "1.42" },
        { "label": "MaxDD", "value": "-8.7%" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

Both tools are shipped and live: `check_spec` runs without dispatching a
backtest, while `run_backtest` dispatches to the honba-ya runtime. Feed the
results into `evaluate_metrics` on the [analytics](analytics.md) /
[validation](validation.md) pages for DSR/PBO.
