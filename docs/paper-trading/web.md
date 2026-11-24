# Paper Trading — Web & TUI

## `PaperPanel` (tantra-ui-app)

`PaperPanel` is the web (CSR — client-side rendered) paper-trading panel. It has
two modes:

- **Embedded** — runs an in-browser `PaperExchange` session: zero server, works
  offline. Every order and fill is simulated locally by the same engine used
  everywhere else; the panel is a thin UI over it.
- **Server** — connects to a `paper serve` daemon and projects the `/api/v2/stream`
  `ClientEvent`s (fills, positions, working orders) onto the panel. Same UI, live
  server state.

The embedded mode is the quickest possible way to try the paper engine: open the
panel, place an order, watch it rest or fill against the in-browser book — no
credentials, no server.

## The TUI paper panel (`tantra-tui`)

`tantra-tui`'s paper panel (the `/positions` command) shows working orders, fills,
depth and positions from the live stream. When no daemon is reachable it falls
back to fixture data so the panel stays navigable offline.

See [REST & WebSocket](rest-ws.md) for the daemon these panels connect to, and
[Python SDK](python.md) for the same engine in a script.
