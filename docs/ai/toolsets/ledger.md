# Ledger

The **Ledger** engine is the accounting heart of the platform: FIFO tax-lot
matching, positions, orders, P&L, tax reports, and ledger statements. FIFO
tax-lot accounting is implemented in the `tantra-ledger` crate; the toolset
surface is conversational.

## MCP gateway tools

The Ledger engine has **no dedicated MCP quant tool**. Ledger access is served
through the chat-tool surface below.

## Chat-tool surface

These conversational tools live in `tantra-agent-chat-tools` (32 read-only
tools + 2 LocalWrite trade tools) and serve the Ledger engine:

| Tool | Returns |
| :--- | :--- |
| `portfolio_view` | Portfolio holdings and valuation. |
| `positions_view` | Open positions. |
| `orders_view` | Order history. |
| `tax_lots_view` | FIFO tax-lot records. |
| `pnl_view` | Portfolio P&L. |
| `tax_report` | Capital-gains tax: STCG 20%, LTCG 12.5% over the ₹1.25L exemption, computed from closed tax lots. |
| `ledger_statement` | Double-entry ledger statement. |

## Example

```json
{
  "tool": "tax_report",
  "arguments": {
    "fy": "2025-26"
  }
}
```

```json
{
  "schema": "tantra/result/v1",
  "status": "ok",
  "meta": {
    "elapsed_ms": 16,
    "timestamp_ist": "2026-11-06T08:27:00+05:30",
    "version": "0.1.0",
    "precision": "exact_decimal_zero_floats"
  },
  "summary": "FY2025-26: STCG tax 12480.00, LTCG tax 4210.00 after 125000.00 exemption",
  "data": {
    "fy": "2025-26",
    "stcg_rate_pct": "20",
    "ltcg_rate_pct": "12.5",
    "ltcg_exemption": "125000.00",
    "stcg_tax": "12480.00",
    "ltcg_tax": "4210.00"
  },
  "blocks": [
    {
      "type": "table",
      "columns": ["bucket", "tax"],
      "rows": [
        ["STCG (20%)", "12480.00"],
        ["LTCG (12.5%)", "4210.00"]
      ]
    }
  ],
  "refs": {}
}
```

## Status

The ledger surface is **conversation-surface only** — no dedicated MCP quant
tool. FIFO tax-lot matching itself runs in `tantra-ledger`; `tax_report` and
`ledger_statement` are live and compute from closed tax lots.
