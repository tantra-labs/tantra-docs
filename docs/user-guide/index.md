# User Guide — Working Headless

> **The web UI is not your daily driver yet.** The Strategy Studio (WASM),
> the React terminal, and the CSR paper panel exist and are tested, but the
> supported, stable way to work with Tantra **today** is headless: the
> `tantra` CLI, the REST/WebSocket API, the Python SDK, and the AI/MCP
> gateway. Everything on this page is implemented, tested, and usable right
> now — nothing here is planned.

This guide is the pre-UI manual. If you have just installed the platform,
start at [Getting Started → Installation](../getting-started/installation.md),
then come back here for the day-to-day workflow.

---

## The Four Work Surfaces

| Surface | What it is | Reach for it when |
|:--------|:-----------|:------------------|
| **`tantra` CLI** | The single native binary (built by `tantra-ui`) with ~17 subcommands | You want an answer, a scan, a backtest, a paper session, or a scheduled job from a terminal or a script. |
| **REST / WebSocket API** | `tantra serve` and `paper-serve` — a headless HTTP server with OpenAPI 3.1, SSE, and `/api/v2/stream` streaming | You are building a client, a dashboard, a webhook, or any other process that talks to Tantra over HTTP. |
| **Python SDK** | The `tantra` PyPI wheel (`tantra-ffi`, PyO3) — strategies, `Tantra.backtest`, indicators, paper sessions, adapters | You are authoring strategies, running research, or scripting backtests in Python. |
| **AI / MCP gateway** | `tantra ask` / `tantra chat`, the 22-tool quantitative MCP gateway, autonomous `tantra jobs` | You want an AI agent to research, screen, and run strategies — or to drive Tantra from Claude Code, Cursor, VS Code, or Gemini CLI. |

All four surfaces share the same engine: the same zero-I/O domain kernel, the
same `Decimal` money, the same paper exchange, the same pre-trade risk gate.
A strategy behaves the same whether it is driven from the CLI, the REST API,
or Python.

---

## Choosing a Surface (Decision Table)

| Job | Surface | Command / page |
|:----|:--------|:---------------|
| Install the platform | shell | [Installation](../getting-started/installation.md) |
| Run your first backtest | Python | [First Backtest](../getting-started/first-backtest.md) |
| Backtest a strategy | Python / CLI / REST | `Tantra.backtest(...).run()` · `tantra strategy run` · `POST /backtests` |
| Optimize parameters | CLI | `tantra strategy tune` / `tantra strategy suggest` |
| Screen a universe | CLI / REST | `tantra scan "query"` · `GET /api/v2/screener/scans` |
| Paper trade | CLI / REST / Python | [Paper Trading](../paper-trading/index.md) |
| Serve market data + API | CLI | `tantra serve --data-dir ./bars` |
| Ask the AI agent | CLI | `tantra ask "..."` / `tantra chat` |
| Wire an AI coding agent | MCP | `tantra mcp config --client claude-code` |
| Schedule autonomous research | CLI | `tantra jobs add "..." --schedule "30 7 * * 1-5"` |
| Verify a strategy manifest | CLI / REST | `tantra verify` · `POST /strategies/verify` |
| Health-check the install | CLI | `tantra doctor` / `tantra health` |

---

## Read This Guide In Order

1. **[The `tantra` CLI](cli.md)** — every subcommand, organized by the job you
   actually want to do.
2. **[REST API Workflows](rest-api.md)** — boot `tantra serve`, hit the
   endpoints with `curl`, and stream `/api/v2/stream`.
3. **[Python SDK](python.md)** — authoring strategies and running backtests
   in Python.
4. **[AI & Automation](ai.md)** — the headless AI agent, the MCP gateway, and
   autonomous jobs.
5. **[Experimental-Analysis Workbench](experimental-analysis.md)** — interpreting
   period/expiry returns, Markov transitions, option overlays, ORB, and the
   Contrarian (Mean-Reversion) strategy playbook in `tantra-ui-web`.

Paper trading is covered by its own dedicated guide —
[Paper Trading Exchange](../paper-trading/index.md) — with the CLI session,
the `paper-serve` daemon, the REST `/api/v2/orders` + `/api/v2/stream` surfaces, and the
Python `PaperSession`.

## What This Guide Does Not Cover

- **Live broker trading.** Broker adapters (`tantra-adapters`, Python) are
  real but REST-only and parity is still in progress (`IN-PROGRESS` in the
  [conformance matrix](../conformance_matrix.md)). For anything that touches
  money, use the paper exchange instead until the parity gaps close.
- **The web workstations.** The WASM Strategy Studio and the React terminal
  are documented in
  [Strategy Studio](../architecture/strategy_studio.md) and
  [Using the Simulator](../architecture/simulator_usage.md); they are tested
  but not yet the recommended daily driver. The quantitative research workbench
  is covered separately in
  [Experimental-Analysis Workbench](experimental-analysis.md).
- **The full REST wire contract.** This guide shows workflows; the complete
  route-by-route reference is [REST Read API and `tantra serve`](../api/rest.md).

## After This Guide

- [Architecture → Overview](../architecture/overview.md) — why the platform
  is organized the way it is.
- [Backtesting → Three-Tier Pipeline](../backtesting/three_tier_pipeline.md) —
  how to validate a strategy properly.
- [AI & Quant Research → MCP Gateway](../ai/mcp_gateway.md) — the 22-tool
  gateway reference.
