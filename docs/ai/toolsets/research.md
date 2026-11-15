# Research

The **Research** engine is the strategy-optimization loop in `tantra-agent`:
genetic and Bayesian sweeps over strategy parameters, driven by the
`optimize_strategy` gateway tool.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `optimize_strategy` | strategy manifest, parameter space, search method `genetic`\|`bayesian` | Best parameter set and its evaluated metrics. |

## Chat-tool surface

The Research engine has no chat-tool surface; optimization is served
exclusively by the MCP gateway tool above.

## Example

```json
{
  "tool": "optimize_strategy",
  "arguments": {
    "strategy": "ma_cross",
    "method": "bayesian",
    "space": {
      "fast_period": ["5", "50"],
      "slow_period": ["20", "200"]
    },
    "max_evals": 40
  }
}
```

!!! note
    `optimize_strategy` arguments follow the strategy-manifest schema; the
    example above is illustrative of a parameter sweep.

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 240,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Bayesian sweep: fast_period=12, slow_period=48, out-of-sample Sharpe 1.21",
  "data": {
    "method": "bayesian",
    "best": {
      "fast_period": 12,
      "slow_period": 48
    },
    "oos_sharpe": "1.21"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Fast period", "value": "12" },
        { "label": "Slow period", "value": "48" },
        { "label": "OOS Sharpe", "value": "1.21" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

The tool is shipped and live; the research loop itself runs in
`tantra-agent`. Pair optimization output with the [validation](validation.md)
engine to confirm DSR/PBO before promoting a parameter set.
