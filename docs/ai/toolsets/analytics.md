# Analytics

The **Analytics** engine is the statistical workbench: Monte Carlo simulation,
cointegration, walk-forward evaluation, factor attribution, change-point
detection, copula tail risk, permutation tests, and the `evaluate_metrics`
gateway tool. It is the most tool-dense engine in the toolset.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_monte_carlo` | `returns[]` (req), `num_sims` (min 10, default 500), `horizon` | Moving-block bootstrap equity paths; drawdowns, ruin probability, stability. |
| `tantra_cointegration` | `series_x[]`, `series_y[]` (req) | Engle–Granger two-step: hedge ratio, ADF statistic, spread z-score. |
| `tantra_walk_forward` | `returns[]` (req), `train_size` (≥1), `test_size` (≥1) | Walk-forward evaluation and overfitting detection (WFE). |
| `tantra_factor_attribution` | `factor_returns` (req object), `asset_returns[]`, `holdings[]`, `annualization_factor` (default 252) | Systematic exposures and idiosyncratic residual. |
| `tantra_change_point` | `series[]` (req), `min_observations` (default 10), `threshold_multiplier` (default 3.0), `min_segment` (default 5) | Two-sided CUSUM change-point indices. |
| `tantra_copula_tail_risk` | `series_x[]`, `series_y[]` (req), `family` clayton\|gumbel (default clayton), `n_simulations` (default 5000), `seed` (default 42) | Kendall tau, tail dependence, joint VaR95. |
| `tantra_permutation_test` | `returns[]` (req), `n_permutations` (default 1000), `seed` (default 42) | Sharpe sign-flip p-value. |
| `evaluate_metrics` | strategy/backtest results | Sharpe, Sortino, MaxDD, WinRate, OTR, DSR, PBO. |

## Chat-tool surface

The conversational tools that also serve this engine (shipped in
`tantra-agent-chat-tools`, 32 read-only tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `pnl_view` | Portfolio P&L view. |
| `portfolio_view` | Portfolio holdings and valuation. |

## Example

```json
{
  "tool": "tantra_monte_carlo",
  "arguments": {
    "returns": ["0.0012", "-0.0008", "0.0021", "-0.0014", "0.0009"],
    "num_sims": 500,
    "horizon": 252
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 12,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "500 simulated 1-year equity paths; 5th-percentile drawdown -22.4%",
  "data": {
    "num_sims": 500,
    "horizon": 252,
    "median_final_equity": "1.083",
    "p05_drawdown_pct": "-22.4",
    "ruin_probability": "0.004",
    "stability": "0.71"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Median final equity", "value": "1.083" },
        { "label": "P05 drawdown", "value": "-22.4%" },
        { "label": "Ruin probability", "value": "0.004" },
        { "label": "Stability", "value": "0.71" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

All eight tools are shipped and live. `tantra_walk_forward`,
`tantra_permutation_test` and `evaluate_metrics` overlap with the
[validation](validation.md) engine; `tantra_change_point` also serves the
[regimes](regimes.md) engine.
