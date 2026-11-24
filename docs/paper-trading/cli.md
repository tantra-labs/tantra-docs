# Paper Trading — CLI

The `tantra` CLI ships a paper-trading command that boots the paper exchange with
zero configuration — no broker credentials, no config file, no network.

## `tantra paper --mode embedded`

Boots an in-memory paper exchange, runs the deterministic demo tape, and prints
the fills plus the session summary:

```bash
tantra paper --mode embedded
```

The demo tape is deterministic, so the figures are stable across runs. The golden
demo's key figures are:

| Figure | Value |
|--------|-------|
| Sell VWAP | `100.6667` |
| Net P&L | `0` |
| Cash | `1_000_000` |

(The exact printed labels may vary by release; these are the golden values
verified by the paper track's tests.)

## `tantra paper --mode server`

Prints the instructions for the long-running daemon, pointing at the `paper serve`
REST `/api/v2/orders` route and the `/api/v2/stream` WebSocket stream:

```bash
tantra paper --mode server
```

Continue to [REST & WebSocket](rest-ws.md) for the daemon walkthrough, or
[Python SDK](python.md) for the programmatic session.
