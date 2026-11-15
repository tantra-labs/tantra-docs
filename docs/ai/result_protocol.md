# Universal Result Protocol

Every tool in the Tantra MCP gateway — base, quantitative, and discovery — returns its payload
wrapped in a single predictable envelope: **`tantra/result/v1`**. Clients never guess the shape of
a response; they read `status`, `summary`, `data`, `blocks`, and `refs` uniformly. The envelope is
defined in `tantra-agent-core/src/result.rs`.

## Envelope

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
  "summary": "Delivery sale of ₹1,00,000 incurs ₹120.45 in total statutory charges.",
  "data": {
    "stt": "100.00",
    "exchange_charge": "3.45",
    "sebi_fee": "0.10",
    "stamp_duty": "0.00",
    "gst_18": "0.64",
    "total_statutory": "104.19"
  },
  "blocks": [
    {
      "type": "table",
      "title": "Statutory Charge Breakdown",
      "columns": ["Charge", "Rate", "Amount (INR)"],
      "rows": [
        ["STT (Delivery Sell)", "0.1%", "100.00"],
        ["NSE Exchange Fee", "0.00345%", "3.45"],
        ["SEBI Turnover Fee", "₹10/crore", "0.10"],
        ["GST", "18% on fees", "0.64"],
        ["Total Costs", "-", "104.19"]
      ]
    }
  ],
  "refs": {}
}
```

## Envelope fields

| Field | Type | Description |
|-------|------|-------------|
| `schema` | string | Always `tantra/result/v1`. |
| `status` | enum | `ok` on success, `error` on failure. |
| `meta` | object | Execution metadata (below). |
| `summary` | string | Human-readable one-liner describing the result. |
| `data` | object | Typed, machine-readable payload. |
| `blocks` | array | Presentation blocks for rich rendering (below). |
| `refs` | object | Map of `key → "$tantra/ref/<uuid>"` for large datasets that are not inlined. |

## `meta`

| Field | Description |
|-------|-------------|
| `elapsed_ms` | Server-side execution time in milliseconds. |
| `timestamp_ist` | Completion timestamp in IST (`Asia/Kolkata`), e.g. `2026-11-06T08:27:00+05:30`. |
| `version` | Gateway version, e.g. `0.1.0`. |
| `precision` | Always `exact_decimal_zero_floats` — the workspace zero-floats invariant. |

## Display blocks

`blocks` carries presentation-ready content the client can render directly:

| Type | Fields | Description |
|------|--------|-------------|
| `Table` | `title`, `columns`, `rows` | Tabular data with column headers and string rows. |
| `MetricGrid` | `items: [{label, value}]` | Label/value metric cards. |
| `Chart` | `title`, `chart_type`, `series_ref` | Chart reference; `chart_type` is `candlestick`, `line`, or `sparkline`. `series_ref` points into `data` or `refs`. |
| `Alert` | `level`, `message` | Status alert; `level` is `info`, `warning`, or `critical`. |

## Data references

Large datasets are never inlined into the envelope. A tool that produces a large time series,
trade log, or covariance matrix returns a reference:

```json
{
  "refs": {
    "returns": "$tantra/ref/0192e8c4-0001-7a10-8000-9e3f8c1b2a4d"
  }
}
```

Read the referenced payload back with `tantra_read_result`, using `offset`/`limit` for
pagination:

```json
{
  "ref_id": "$tantra/ref/0192e8c4-0001-7a10-8000-9e3f8c1b2a4d",
  "offset": 0,
  "limit": 100
}
```

## `_jq` token optimization

Every `tantra_`-prefixed quantitative tool accepts an optional `_jq` string: a JSONPath filter
applied server-side to the response payload **before** the envelope is serialized. This keeps
large payloads cheap for the LLM context window (token-optimization feature, plan 0007 Ph 15).

```json
{
  "returns": ["0.001", "-0.002", "0.003", "0.001"],
  "_jq": "$.forecast[0:5]"
}
```

## Precision invariant

`meta.precision` is always `exact_decimal_zero_floats`: prices, quantities, cash balances,
statutory taxes, and margin calculations are exact decimal (`rust_decimal::Decimal`) — never
`f32`/`f64`/`float` — and are serialized as decimal strings. Statistic-style outputs such as
Sharpe or DSR ratios follow the same serialization.

---

See the [MCP Gateway](mcp_gateway.md) for the full 22-tool catalog, or the [Quantitative
Toolsets index](../ai/toolsets/index.md) for the engines behind the tools.
