# Validation

The **Validation** engine detects overfitting and validates strategy
performance: DSR (Deflated Sharpe Ratio), PBO (Probability of Backtest
Overfitting), and walk-forward evaluation, backed by permutation testing.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `evaluate_metrics` | strategy/backtest results | Sharpe, Sortino, MaxDD, WinRate, OTR, DSR, PBO. |
| `tantra_permutation_test` | `returns[]` (req), `n_permutations` (default 1000), `seed` (default 42) | Sharpe sign-flip p-value. |
| `tantra_walk_forward` | `returns[]` (req), `train_size` (≥1), `test_size` (≥1) | Walk-forward evaluation and overfitting detection (WFE). |

## Chat-tool surface

The Validation engine has no chat-tool surface; validation is served
exclusively by the MCP gateway tools above.

## Example

```json
{
  "tool": "evaluate_metrics",
  "arguments": {
    "returns": ["0.0011", "0.0006", "-0.0004", "0.0018", "0.0009"]
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 9,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Sharpe 1.42; DSR 0.61 and PBO 0.23 indicate modest overfitting risk",
  "data": {
    "sharpe": "1.42",
    "sortino": "1.88",
    "max_drawdown_pct": "-8.7",
    "win_rate_pct": "58.3",
    "otr": "4.1",
    "dsr": "0.61",
    "pbo": "0.23"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Sharpe", "value": "1.42" },
        { "label": "Sortino", "value": "1.88" },
        { "label": "MaxDD", "value": "-8.7%" },
        { "label": "WinRate", "value": "58.3%" },
        { "label": "DSR", "value": "0.61" },
        { "label": "PBO", "value": "0.23" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

All three tools are shipped and live. For the overfitting-detection workflow,
pair `evaluate_metrics` (DSR/PBO) with `tantra_walk_forward` and
`tantra_permutation_test`. See also the [analytics](analytics.md) engine,
which hosts the same tools in its wider statistical catalogue.
