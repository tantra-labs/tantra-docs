# Allocation

The **Allocation** engine constructs portfolios: mean-variance optimization,
risk parity, hierarchical risk parity (HRP), and Black–Litterman, all backed by
the `tantra-ledger-allocation` crate — the same crate that ships the `Hrp` and
`BlackLitterman` objectives.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_portfolio_optimize` | `covariance_matrix[][]` (req), `expected_returns[]`, `objective` mean_variance\|risk_parity\|hrp (default mean_variance), `target_return`, `risk_free_rate` (default 0), `symbols[]`, `weight_bounds[]` | Optimal weights (MVO/HRP/risk-parity). |
| `tantra_multi_period_optimize` | `covariance_matrix[][]` (req), `expected_returns[]`, `objective` (default risk_parity), `periods` (default 3), `transaction_cost` (default 0.001), `turnover_penalty` (default 0.0001), `max_turnover_per_period`, `symbols[]`, `weight_bounds[]` | Multi-period rebalance schedule with transaction costs (MPO). |

## Chat-tool surface

The Allocation engine has no chat-tool surface; allocation is served
exclusively by the MCP gateway tools above.

## Example

```json
{
  "tool": "tantra_portfolio_optimize",
  "arguments": {
    "covariance_matrix": [
      ["0.0004", "0.0001"],
      ["0.0001", "0.0009"]
    ],
    "expected_returns": ["0.0012", "0.0008"],
    "objective": "risk_parity",
    "risk_free_rate": 0,
    "symbols": ["NSE:NIFTY50-INDEX", "NSE:GOLDBEES"],
    "weight_bounds": ["0.0", "1.0"]
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 21,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "Risk-parity weights: NIFTY50 0.42, GOLDBEES 0.58",
  "data": {
    "objective": "risk_parity",
    "weights": {
      "NSE:NIFTY50-INDEX": "0.42",
      "NSE:GOLDBEES": "0.58"
    }
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["symbol", "weight"],
      "rows": [
        ["NSE:NIFTY50-INDEX", "0.42"],
        ["NSE:GOLDBEES", "0.58"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

Both tools are shipped and live. `tantra_portfolio_optimize` serves the
MVO/HRP/risk-parity objectives; Black–Litterman is available in the same
`tantra-ledger-allocation` engine family via the `BlackLitterman` objective.
`tantra_multi_period_optimize` extends the same family with multi-period
rebalancing and transaction costs.
