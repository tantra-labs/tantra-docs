# Paper Trading — REST & WebSocket (`paper serve`)

`paper serve` (in `tantra-runtime-api-rest`) runs the paper exchange as a headless
daemon: no broker credentials, no market-data subscription, no settlement. Orders
and fills flow through the same `PaperExchange` engine as the Python SDK, the CLI
and the web panel.

## Run the daemon with a bar tape

```bash
paper serve --tape <bars-json>
```

- `--tape <bars-json>` replays a bar tape (a JSON array of bars) into the exchange,
  so matching is driven by the tape instead of a live feed.
- `--mis-square-off HH:MM` enables MIS square-off: open positions taken under the
  MIS product are squared off automatically at the configured time.

## Endpoints

All paths are relative to `/api/v2`.

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/orders` | Place an order (returns order id + client order id) |
| `POST` | `/orders/{id}/cancel` | Cancel a working order |
| `POST` | `/portfolio/positions/close` | Close all open positions |
| `GET` | `/portfolio/positions` | Current open positions |
| `GET` | `/portfolio` | Cash, equity, margin utilization, FIFO trade history |
| `WS` | `/stream` | Bidirectional order / fill / depth / position push |

### Place an order

The request mirrors the SDK's `place_order` surface — instrument, side, quantity,
order type, prices and time-in-force:

```json
{
  "instrument": "NSE:RELIANCE-EQ",
  "side": "BUY",
  "quantity": "10",
  "order_type": "LIMIT",
  "limit_price": "100.00",
  "tif": "DAY"
}
```

### Fill payload

Fills are reported with these fields:

```json
{
  "fill_id": "<fill-id>",
  "order_id": "<order-id>",
  "client_order_id": "<client-order-id>",
  "instrument": "NSE:RELIANCE-EQ",
  "side": "BUY",
  "price": "100.00",
  "quantity": "10",
  "algo_id": "<sebi-algo-id>",
  "timestamp": "2023-11-14T22:14:00Z",
  "fee": "0.00"
}
```

Prices and quantities are decimal strings — the daemon is zero-float end to end,
and every fill carries its own explicit `timestamp`.

### WebSocket `/stream`

The live stream pushes order and market events to connected clients. The event
kinds are:

| Event kind | Carries |
|------------|---------|
| Order accepted | order id, client order id, instrument, side, quantity, type, time-in-force, accepted timestamp |
| Fill / partial fill | the fill payload above; a partial fill also reports the remaining quantity |
| Cancel | order id, cancelled timestamp |
| Reject | order id, rejection reason |
| Stop triggered | order id, triggered price, the working order that resulted |
| Depth | L2 book snapshot for an instrument |
| Positions | current open positions |

The stream is bidirectional — clients can also send orders over the same socket.

> **Exact wire JSON.** The precise request/response envelopes, event names and
> field casing for the endpoints above are documented in
> [REST API](../api/rest.md). For `paper serve` daemon surfaces that are not yet
> covered there (tape loading, MIS square-off), see the runtime plan
> `tantra-runtime/docs/plans/0005`.

See [Python SDK](python.md) for the same engine from a script, or
[Web & TUI](web.md) for the panel that projects `/stream` onto a UI.
