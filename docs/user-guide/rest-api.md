# REST API Workflows

`tantra serve` boots the full HTTP/WebSocket API (`tantra-runtime-api-rest`)
over a directory of Parquet bar files. It is the headless way to expose
market data, backtests, order placement, screener scans, and live streaming
to any client. The complete route-by-route reference is
[REST Read API and `tantra serve`](../api/rest.md); this page shows the
workflows.

## Boot the Server

```bash
tantra serve --data-dir ./bars                          # http://127.0.0.1:8000
tantra serve --data-dir ./bars --addr 127.0.0.1:9000
tantra serve --data-dir ./bars --profiles-dir ./profiles --portfolios-dir ./portfolios \
    --journals-dir ./journals --tokens-file ./tokens.toml
```

- `--data-dir` holds `SYMBOL.EXCHANGE.parquet` files (for example
  `RELIANCE.NSE.parquet`) and is loaded **once** at start-up; a bad directory
  fails before anything listens.
- The first stdout line is `listening on http://<addr>` with the address
  actually bound.
- Loopback-only by default; if you bind a non-loopback address the server
  warns that there is no auth or TLS unless `--tokens-file` is set.

## Health and Capabilities

```bash
curl http://127.0.0.1:8000/health        # {"data": {"status": "ok"}}
curl http://127.0.0.1:8000/capabilities  # crates, market_packs, toolsets, adapters, features
curl http://127.0.0.1:8000/schema        # OpenAPI 3.1 document
curl http://127.0.0.1:8000/docs          # Swagger UI in a browser
```

## Market Data

```bash
# Instruments and quotes
curl "http://127.0.0.1:8000/instruments?exchange=NSE"
curl "http://127.0.0.1:8000/quotes?symbols=RELIANCE.NSE,INFY.NSE&venue=NSE"

# Bars (half-open [from, to), ascending ts_event; cap 100_000 bars)
curl "http://127.0.0.1:8000/bars/RELIANCE.NSE?tf=1m&from=2026-01-15T00:00:00Z&to=2026-01-16T00:00:00Z"
```

Quotes are derived from bars (bid = ask = close of the latest bar at or
before `as_of`). Depth over a bar-only dataset answers 404
`market_data_unavailable` — nothing is fabricated.

## Screener Scan

```bash
curl -X POST http://127.0.0.1:8000/screener/scan \
  -H 'Content-Type: application/json' \
  -d '{"universe": ["RELIANCE.NSE", "INFY.NSE"], "filters": {"and": [{"metric": "close", "op": "gt", "value": "2500", "timeframe": "1m"}]}, "tf": "1m"}'
```

The answer is `{rows: [{instrument_id, metrics}]}`; any unknown metric is a
422 `reason = unsupported_metric`, never an empty result. Bounds: 1,000
instruments, 500 rows, 2M bars per scan, 100k bars per instrument.

## Strategies and Backtests

```bash
# Verify a manifest without storing it
curl -X POST http://127.0.0.1:8000/strategies/verify -H 'Content-Type: application/json' \
  -d '{"manifest": {...}}'

# Compile + store (id = SHA-256 of the canonical manifest JSON)
curl -X POST http://127.0.0.1:8000/strategies -H 'Content-Type: application/json' \
  -d '{"manifest": {...}}'

# List compiled strategies, create a backtest run, follow its journal/events
curl http://127.0.0.1:8000/strategies
curl -X POST http://127.0.0.1:8000/backtests -H 'Content-Type: application/json' -d '{"...": "..."}'
curl http://127.0.0.1:8000/backtests/{id}/journal
curl -N http://127.0.0.1:8000/backtests/{id}/events     # SSE stream; resume_from_seq=N
```

## Orders (Risk-Gated)

```bash
curl -X POST http://127.0.0.1:8000/orders -H 'Content-Type: application/json' \
  -d '{"instrument": "RELIANCE.NSE", "side": "buy", "order_type": "limit", "quantity": "10", "limit_price": "2500"}'
```

`POST /orders` runs through the pre-trade risk gate first: a refusal is a 422
with a `risk_*` code (category `risk`, not retryable). `DELETE /orders/{id}`
cancels without a gate; `POST /positions/close` is the emergency close-all
route. Four `/portfolio/*` routes (accounts/positions/holdings) answer 501
until the live valuation engine is wired — use `/portfolio/trades`,
`/portfolio/chart`, `/portfolio/concentration`, and `/portfolio/wac`, which
are implemented.

## Streaming: `/ws` and `/ws/live`

- `GET /ws` (alias `/ws/market`) pushes `WsTick` and `WsDepth` frames as data
  arrives; the client sends `WsClientCommand` subscribe/switch actions. No
  polling.
- `GET /ws/live` (served by the paper server — see
  [Paper Trading](../paper-trading/index.md)) pushes orders, fills, positions, and
  depth from the paper exchange, and accepts client
  place/cancel/subscribe commands.
- `GET /ws/chat` connects the runtime chat agent; it needs an LLM backend
  (`TANTRA_GGUF_PATH` or `TANTRA_LLM_BASE_URL`) — see
  [Runtime Chat Agent](../architecture/runtime_chat.md).

## The Response Envelope

Every response, success or failure, is an envelope with exactly one of `data`
or `error`:

```json
{"api_version": "...", "schema_version": 3, "data": {"status": "ok"}}
```

```json
{"api_version": "...", "schema_version": 3,
 "error": {"code": "instrument_not_found", "message": "...",
           "retryable": false, "context": {"field": "id"}}}
```

Decide on retry with `retryable`, not the HTTP status. All monetary values
are Decimal serialized as strings.

## Clients

- **Python**: use the typed [Python client](../api/python-sdk.md) rather than
  parsing the envelope by hand.
- **Web**: point a browser at `/docs` (Swagger UI); pass `--cors-origin` to
  allow a specific browser origin.
- **Anything else**: `curl` + the OpenAPI document at `/schema`.
