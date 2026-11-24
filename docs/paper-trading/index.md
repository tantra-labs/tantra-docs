# Paper Trading Exchange

The Tantra paper exchange is a **real-exchange mimic**: it matches orders against an
L2 limit order book with price-time priority, walks every order through the full
order lifecycle, and accounts for every fill in exact decimal arithmetic — with no
broker account, no network connection, and no wall clock. It is the same fill
engine that powers the event-driven backtester, and it is exposed through four
embeddings: the Python SDK, the REST + WebSocket daemon, the CLI, and the web/TUI
panels.

## What the paper exchange is

Unlike a "fill everything instantly" simulator, the paper exchange models the
mechanics of an exchange venue:

- **L2 order book** — resting bids and offers with per-level depth, maintained
  tick by tick (see `depth(instrument)` in the SDK).
- **Price-time priority** — a resting order fills only when an aggressing order
  crosses its price; same-price orders fill in arrival order.
- **Full order lifecycle** — submitted → accepted → working (resting or aggressing)
  → filled / partially filled / cancelled / rejected; stop orders add a
  triggered → working transition.
- **Partial fills** — an aggressing order can match against several resting orders
  at successive price levels and report a fill per trade.
- **Stop orders** — stop-limit and stop-market orders trigger when the market
  trades through the trigger price.
- **Time-in-force** — `DAY`, `IOC` (immediate-or-cancel) and `GTD` (good-till-date)
  are respected.

Order books, fills, cash and positions are all exact `decimal.Decimal` — the engine
never touches `float` — and every state transition takes an explicit timestamp, so
the same inputs replay to the same state byte for byte.

## One engine, four embeddings

The `PaperExchange` engine (`tantra-exec-paper`) is the single fill engine behind
every embedding. Replaying the same tape with the same seed produces
**byte-identical fills** in all four (verified by the golden vector
`paper_golden.json`, T14.14):

```text
                 ┌─────────────────────────────────────────┐
                 │   PaperExchange — the one fill engine    │
                 │   tantra-exec-paper                      │
                 │   L2 book · price-time priority          │
                 │   order lifecycle · stops · IOC / GTD    │
                 │   Decimal-only · explicit timestamps     │
                 └─────────────────────────────────────────┘
                       │        │        │        │
       ┌───────────────┘        │        │        └───────────────┐
       ▼                        ▼        ▼                        ▼
 Python SDK                REST + WS     CLI                  Web / TUI
 tantra.paper              paper serve  tantra paper          PaperPanel
 PaperSession              /orders      --mode embedded       (embedded or
                           /api/v2/stream --mode server         server) ·
                                                               tantra-tui
                                                               /positions
```

| Embedding | Surface | When to reach for it |
|-----------|---------|----------------------|
| Python SDK | `tantra.paper.PaperSession` — scripts, notebooks, tests | Strategy prototyping, deterministic smoke tests, research loops |
| REST + WebSocket | `paper serve` — `/api/v2/orders`, `/api/v2/portfolio/positions`, `/api/v2/portfolio`, `/api/v2/stream` | Headless daemons, dashboards, multi-client setups |
| CLI | `tantra paper --mode embedded` | A five-second sanity check that the paper engine round-trips |
| Web / TUI | `PaperPanel` (embedded or server mode), `tantra-tui` `/positions` | Interactive, zero-install exploration |

## Paper trading vs backtesting vs live broker

| | Backtest (`tantra.backtest`) | **Paper exchange** | Live broker |
|---|---|---|---|
| Fill engine | Same `PaperExchange` engine | Same engine | Broker / exchange |
| Market data | Historical bars / ticks | Live or tape-fed bars / ticks | Live feeds (`tantra-market`) |
| Credentials | None | **None** | Broker API keys + TOTP |
| Money at risk | None | None | Real capital |
| Wall clock | Frozen (explicit timestamps) | Explicit timestamps | Real-time |
| Deterministic replay | Yes | Yes (same tape + seed) | No |
| Settlement / taxes | Modeled costs only | Modeled fills, no settlement | Real settlement |

Use the paper exchange when you want **broker-like order mechanics without any
credentials or risk**: validating a strategy's order logic end to end, exercising
the REST / WebSocket surfaces, or rehearsing a live deployment. Use backtesting
for historical performance research, and a live broker for real trading.

## Determinism and exact arithmetic

- **Zero floats** — prices, quantities, cash and equity are `Decimal` end to end;
  no `f32` / `f64` anywhere in the financial path.
- **Deterministic clock** — the engine never reads the wall clock; every
  transition receives an explicit timestamp (`ts_iso` / `advance_to` / tape bar
  timestamps).
- **Seeded latency** — `seed=` selects the engine's latency model; the same seed
  reproduces the same fills and equity across two runs (the SDK tests assert
  this).

## Where to go next

- [Python SDK](python.md) — a seeded `PaperSession` round trip.
- [CLI](cli.md) — `tantra paper --mode embedded` golden demo.
- [REST & WebSocket](rest-ws.md) — the `paper serve` daemon.
- [Web & TUI](web.md) — `PaperPanel` and the `tantra-tui` paper panel.
