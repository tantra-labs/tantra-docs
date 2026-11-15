# Regimes

The **Regimes** engine segments return series into market states: a Gaussian
hidden Markov model (HMM) with Baum–Welch + Viterbi estimation labels states
`bullish`, `bearish`, or `choppy_volatile`, and a two-sided CUSUM detects
change points.

## MCP gateway tools

| Tool | Inputs | Returns |
| :--- | :--- | :--- |
| `tantra_detect_regimes` | `returns[]` (req), `n_states` 2\|3 (default 2), `max_iterations` (default 100) | HMM regime labels (bullish/bearish/choppy_volatile), transition and emission parameters. |
| `tantra_change_point` | `series[]` (req), `min_observations` (default 10), `threshold_multiplier` (default 3.0), `min_segment` (default 5) | Two-sided CUSUM change-point indices. |

## Chat-tool surface

The conversational tool that also serves this engine (shipped in
`tantra-agent-chat-tools`, 32 read-only tools + 2 LocalWrite trade tools):

| Tool | Returns |
| :--- | :--- |
| `regime_check` | Current regime assessment for a symbol/portfolio (`RegimeCheckTool`). |

## Example

```json
{
  "tool": "tantra_detect_regimes",
  "arguments": {
    "returns": ["0.0012", "0.0018", "-0.0009", "-0.0014", "0.0004", "0.0007"],
    "n_states": 2,
    "max_iterations": 100
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 31,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "2-state HMM: current regime bullish, 68% probability",
  "data": {
    "n_states": 2,
    "regime_labels": ["bearish", "bullish"],
    "current_regime": "bullish",
    "current_probability": "0.68"
  },
  "blocks": [
    {
      "type": "metric_grid",
      "items": [
        { "label": "Current regime", "value": "bullish" },
        { "label": "Probability", "value": "0.68" }
      ]
    }
  ],
  "refs": {}
}
```

## Status

Both gateway tools are shipped and live. `tantra_change_point` is shared with
the [analytics](analytics.md) engine; `regime_check` adds the conversational
current-regime surface.
