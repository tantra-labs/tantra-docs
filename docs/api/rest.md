# REST Read API and `tantra serve`

`tantra serve` exposes a full HTTP/WebSocket API. The runtime serves **only** `/api/v2/...` (plus the Swagger UI at `/docs`); earlier un-prefixed and v1 paths were removed. It boots `tantra-runtime-api-rest` as a standalone server over a directory of Parquet bar files plus optional profile, portfolio, journal, and token stores.

```bash
tantra serve --data-dir ./bars                      # 127.0.0.1:8000
tantra serve --data-dir ./bars --addr 127.0.0.1:0   # pick a free port
tantra serve --data-dir ./bars --profiles-dir ./profiles --portfolios-dir ./portfolios \
    --journals-dir ./journals --tokens-file ./tokens.toml
```

The data directory holds `SYMBOL.EXCHANGE.parquet` files and is loaded **once** at start-up; a bad directory fails before anything listens. The first stdout line is `listening on http://<addr>` with the address actually bound.

| Flag | Default | Meaning |
|------|---------|---------|
| `--data-dir` | required | Directory of Parquet bar files (`SYMBOL.EXCHANGE.parquet`) |
| `--addr` | `127.0.0.1:8000` | Listen address |
| `--cors-origin <origin>` | none | Allow this browser origin (repeatable) |
| `--profiles-dir` | `data/profiles` | Directory holding one JSON profile per user (`/api/v2/profile` routes) |
| `--portfolios-dir` | `data/portfolios` | Directory holding one JSON portfolio per user (`/api/v2/portfolio` routes) |
| `--journals-dir` | `data/journals` | Directory holding one sub-directory per backtest/run journal |
| `--tokens-file` | none | Bearer-token file (TOML); enables auth when set |

## Security posture

- **Loopback by default.** If `--addr` is not loopback, `tantra serve` prints a warning on stderr: the API has no auth or TLS unless `--tokens-file` is set, so anyone who can reach it can read and write data.
- **No TLS, no rate limiting by default.**
- **No CORS by default** (no CORS headers are sent). Opt in with `--cors-origin https://app.example` (repeatable). `*` and values that are not valid header values are rejected at start-up.
- **Auth** (optional, fail-closed): when `--tokens-file` (or a JWT config) is set, **every** route needs a bearer token carrying the route's scope (`read`, `trade`, `admin`, `research`, or any token) — not only mutating routes. Routes without a scope row are rejected, not public. Only `/api/v2/health`, `/api/v2/capabilities`, `/api/v2/openapi.json` and `/docs` are public. Trade-journal data and paper orders are per caller (the caller is the token id).

## Routes

Every route lives under the base path `/api/v2`. The full, generated route list (method, path, scope, summary) is the [API reference](api-reference.md); the machine-readable contract is `GET /api/v2/openapi.json`, and `/docs` serves the Swagger UI. All paths on this page are relative to `/api/v2`.

Route families: market data (`/instruments`, `/quotes`, `/bars/{id}`, `/depth/{id}`, `/calendar`, `/block-deals`, `/options/chain`), `/screener/scans`, `/strategies`, `/backtests`, `/sweeps`, `/orders` (place, `GET /orders/{id}`, `POST /orders/{id}/cancel`, `/orders/{id}/fills`), `/portfolio/*`, `/reports/*`, `/approvals`, `/alerts` (`GET`/`POST`/`DELETE`), `/trade-journal/*`, `/trading-state`, `/profile/*`, `/studies/*`, and the `/stream` WebSocket.

Envelope: every response is `{api_version: "v2", schema_version, data, error, meta}`. Error statuses follow the error code: validation 422, auth 401/403, not found 404, conflict 409, rate limit 429, unavailable 503 (for example a missing store is `503 service_unavailable`).

`POST /orders` is risk-gated (ADR 0018): a refusal is a 422 carrying the `risk_*` code (category `risk`, not retryable); `POST /orders/{id}/cancel` cancels without a gate and `POST /portfolio/positions/close` closes without one. Placing and cancelling need the `trade` scope.

A request body that does not parse on these routes is still a 422 first.

### `GET /api/v2/capabilities`

The manifest carries `crates`, `market_packs`, `toolsets`, `adapters` and `features`. `endpoints` lists every registry row as `METHOD /path`. The `not_implemented` list names routes that answer 501.

### `GET /api/v2/screener/scans`

Query: `universe` (JSON array of `SYMBOL.EXCHANGE`, required), `filters` (JSON filter group; omitted matches every instrument), `tf` (default `1d`) and `as_of` (inclusive). The answer is `{rows: [{instrument_id, metrics}]}` in instrument-id order; `metrics` holds the latest value of every metric the filter reads (`null` while warming up). Predicates are evaluated in Rust over the bar dataset. Computable metrics: `open`, `high`, `low`, `close`, `volume`, `price_52_week_high`/`_low` (need 252 bars), `SMA<N>` and `RSI`. Anything else is a 422 `reason = unsupported_metric`, never an empty result; a predicate `timeframe` must equal `tf` (`unsupported_timeframe`). An unknown instrument is a 404. A Parquet data directory holds `1m` bars, so pass `tf=1m` there; the default `1d` is a 404 `market_data_unavailable`.

Limits, each a 422 `too_many_rows` with `context.limit`: 1,000 instruments in the universe, 500 matching rows, 2,000,000 bars read per scan, and 100,000 bars per instrument. Filters are bounded to 8 levels of nesting and 64 predicates (`invalid_filter`). There is no pagination.

### Strategy compilation: `POST /strategies` and `GET /strategies`

**`POST /strategies`**: compiles and stores a manifest. Request body is `{manifest}` only (unknown fields are rejected). Compilation is the same verification step as `POST /strategies/verify`; if it succeeds, the strategy is stored in an in-process catalog and returned as `{id, ir}` (the IR is a dict). The `id` is the SHA-256 of the canonical manifest JSON, so the same manifest gets the same id across processes and is stored once. A manifest already held is re-posted successfully without duplication.

The catalog is per-process, in-memory, and lost on restart; capacity is bounded at **1,000 strategies**. A new strategy past the limit is a 422 `validation_invalid_request` with `context.reason = catalog_full` and `context.limit`, but re-posting a manifest already held always succeeds.

A request body containing `code` or `source` is rejected with 422 `context.reason = source_unsupported`. An invalid manifest gets the same 422 envelope as `/strategies/verify` with `context.reason` naming the issue (e.g., `no_subscriptions`).

**`GET /strategies`**: lists all compiled strategies of this process, ordered by id. Returns `{strategies: [CompiledStrategy, ...]}` where each has `id` and `ir`.

### Trade-Performance Journal: `/trade-journal/*` (Plan 0003)

Backed by `tantra-ledger-performance`. These are **distinct** from the existing run/backtest journals (`/backtests/{id}/journal`, `/sweeps/{id}/journal`) and from `/portfolio/accounts`.

| Method | Route | Purpose |
|--------|-------|---------|
| `GET` | `/trade-journal/accounts` | List journal accounts (`JournalAccount`: id, name, provenance, pnl_convention) |
| `POST` | `/trade-journal/accounts` | Create journal account (provenance: `Manual` / `Imported` / `BrokerSynced`) |
| `GET` | `/trade-journal/overview` | Performance metrics + edge score (`PerformanceMetrics`, `EdgeScore`) |
| `GET` | `/trade-journal/trades` | Closed trades with annotations, cursor-paginated (`?from=&to=&limit=&cursor=`) |
| `PATCH` | `/trade-journal/trades/{id}` | Set trade annotation (`tags`, `rating` 1–5, `review`, `planned_risk`) |
| `GET` | `/trade-journal/calendar` | Daily P&L heatmap (`?month=YYYY-MM`) |
| `GET` | `/trade-journal/notes` | Day-keyed journal notes (`?account=&limit=`) |
| `POST` | `/trade-journal/notes` | Create/replace day-keyed note |
| `GET` | `/trade-journal/compare` | Two-sided account comparison (`?accountA=&accountB=` or `?account=&mode=previous`) |

All monetary values are serialized as strings (Decimal exactness preserved).

### Market Reference Data: `/instruments/{id}/profile`, `/calendar` (Plan 0003 Phase 3)

Backed by `tantra-data` (symbol profile, economic calendar) — currently serves **illustrative sample data** pending the `tantra-data` → Rust FFI bridge. The owning gaps are tracked in `tantra-data/docs/gaps/`: `0002-company-fundamentals-symbol-profile.md` (symbol profile ingestion) and `0001-economic-calendar-ingestion.md` / `0003-calendar-stubbed-data.md` (calendar). Sample-data stubs in `tantra-runtime` cite these gaps in code comments.

| Method | Route | Purpose |
|--------|-------|---------|
| `GET` | `/instruments/{id}/profile` | `SymbolProfileDto`: symbol, name, description, sector, industry, market_cap, exchange, country, ipo_date, etc. |
| `GET` | `/calendar` | `CalendarEventDto`: instrument, scheduled_at, category, event_name, impact_level, actual, forecast, prior |
| `GET` | `/block-deals` | Block deals |

### Streaming & Chat: `/stream`, `/ws/chat`, SSE

* `/api/v2/stream` is the one authenticated WebSocket for market data, orders and fills. Client frames are JSON tagged by `op`: `{"op":"subscribe","channel":"quotes|depth|orders|fills|portfolio","ids":["RELIANCE.NSE"]}` (empty `ids` means all, allowed for `orders`/`fills`/`portfolio`), `unsubscribe` (same shape), `{"op":"ping"}`, `{"op":"place_order","request_id":"r1","order":{...}}`, `{"op":"cancel_order","request_id":"r2","order_id":"..."}` and `{"op":"close"}`. Server frames are tagged by `type`: `ack`, `event` (`{"type":"event","channel":"fills","data":{...}}`), `result` (the reply to place/cancel, carrying `request_id`), `error`, `lagged` and `pong`. Place and cancel need the `trade` scope on each message. Each caller receives its own `orders`, `fills`, and `portfolio` account events and snapshots.
* `/backtests/{id}/events` is an SSE stream replayed from the run's line-indexed `events.ndjson`; pass `resume_from_seq=N` to resume after a reconnect without gaps or duplicates.
* `/ws/chat` connects the [runtime chat agent](../architecture/runtime_chat.md) (`ChatRuntime`). It needs an LLM backend in the environment — `TANTRA_GGUF_PATH` (local Candle-GGUF, takes priority) or `TANTRA_LLM_BASE_URL`/`TANTRA_LLM_MODEL`/`TANTRA_LLM_API_KEY` (OpenAI/Ollama-compatible); without either, the socket answers with a clear `chat not configured` message. Sessions are in-memory (`InMemorySessionStore`) and lost on restart; alerts persist on the user profile.

### Behaviour notes

- **Bars cap:** a selection of more than **100,000** bars is rejected with 422 `validation_invalid_request`, `context.reason = "too_many_rows"` and `context.limit`. Narrow `from`/`to`. There is no pagination.
- **Quotes** are derived from bars: bid = ask = close of the latest bar at or before `as_of`, sizes `0` ("last price, no book"). A request is all-or-nothing: one instrument without a quote makes the whole request 404.
- **Depth** over a bar dataset is 404 `market_data_unavailable`; no levels are fabricated.
- Parquet files carry no reference data: instruments are derived as INR equities, lot 1, tick 0.05, and files are read as 1-minute bars.
- Prices are `f64` observations; timestamps are `{iso, unix_nanos}`.

| Case | Status | Code |
|------|--------|------|
| Unknown instrument | 404 | `instrument_not_found` |
| No bar at or before `as_of`; timeframe not held; bar-only depth | 404 | `market_data_unavailable` |
| Bad `tf`/`from`/`to`, empty range, unknown query key, malformed id, `depth` out of range | 422 | `validation_invalid_request` |
| More than 100,000 bars | 422 | `validation_invalid_request` (`too_many_rows`) |
| Unknown route | 404 | `not_found` (an envelope, not an empty body) |
| Known path, unsupported method | 405 | `unsupported` (an envelope) |
| Route not built | 501 | `not_implemented` |
| Port unavailable / timeout / transport | 503 / 504 / 502 | `market_data_unavailable` / `timeout` / `transport_error` |

## Envelope

Every response, success or failure, is an envelope:

```json
{"api_version": "...", "schema_version": 3, "data": {"status": "ok"}}
```

```json
{
  "api_version": "...",
  "schema_version": 3,
  "error": {
    "code": "instrument_not_found",
    "message": "...",
    "retryable": false,
    "context": {"field": "id"}
  }
}
```

Exactly one of `data` and `error` is present. `category` is not on the wire; it is derived from `code`. Use `retryable`, not the status, to decide on retry. (The `schema_version` value shown is illustrative; read it from a response.)

## CLI

- `tantra serve --data-dir DIR [--addr ADDR] [--cors-origin ORIGIN]... [--profiles-dir DIR] [--portfolios-dir DIR] [--journals-dir DIR] [--tokens-file FILE]` — boot the REST server.
- `tantra verify MANIFEST.json` — verifies a strategy manifest and prints the compiled IR as JSON (the CLI form of `POST /strategies/verify`).
- `tantra schema export [--output DIR] [--typescript DIR] [--client DIR] [--openapi DIR] [--pyi DIR] [--mcp DIR] [--docs DIR]` — writes the generated contract artifacts; `tantra codegen` is an alias that emits every one (see [Contracts from Rust](../architecture/contracts_from_rust.md)).
- `tantra jobs add/list/run/tick/install/logs/pause/resume/approvals/approve/deny` — job scheduler CLI (see [Runtime Job Scheduler](../architecture/runtime_jobs.md)).

Use the typed [Python client](python-sdk.md) rather than parsing this by hand.
