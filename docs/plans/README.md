# Plans Index — `tantra-docs`

Per workspace rule `.agents/rules/gap-tracking.md`:
- Gaps are individual features (`docs/gaps/XXXX-*.md`).
- Plans are collections of gaps (`docs/plans/XXXX-*.md`).
- When implemented, plan documents are cleaned up from `docs/plans/` and recorded in this index.

## Active Plans

None currently — 0004 and 0005 are implemented (see below).

## Implemented Plans

| # | Title | Target Scope | Implemented In |
|---|-------|--------------|----------------|
| [0005](0005-headless-user-guide-and-installation.md) | Headless User Guide & Installation Guide — pre-UI daily-driver manual (CLI / REST / Python / AI) + superproject installation rewrite | `docs/user-guide/`, `docs/getting-started/` | Implemented 2026-11-16 — `docs/user-guide/` (index, cli, rest-api, python, ai), rewritten `installation.md` + `first-backtest.md` + `loading-data.md`, nav + home/getting-started indexes wired; paper trading cross-linked to `docs/paper-trading/` (plan 0004); `mkdocs build --strict` green |
| [0004](0004-paper-trading-exchange-user-guide.md) | Paper Trading Exchange User Guide — CLI / REST+WS / Python SDK / web coverage of the paper exchange | `docs/paper-trading/` | Implemented 2026-11-16 (T14.15) — `index.md`, `python.md`, `cli.md`, `rest-ws.md`, `web.md`; nav + home index wired; `mkdocs build --strict` green |
| 0002 | Documenting the Fincept/Quantcept Mapping and the Free-Tier LLM Backend | `docs/ai/` | Implemented in commit `1267490` (`docs/ai/fincept-vs-quantcept.md` and `docs/ai/omniroute_setup.md`) |
| 0001 | Documentation Plan: MCP Quantitative Gateway & 15 Engine Reference | `docs/ai/mcp_gateway.md`, `docs/ai/toolsets/*.md`, `docs/ai/clients/*.md`, `docs/ai/result_protocol.md`, `docs/ai/personas.md`, `docs/getting-started/mcp.md`, `docs/llms.txt` | Implemented 2026-11-15 (T11.1) — gateway reference overhauled, 15 engine toolset pages, 4 client connection guides, result protocol + personas references, MCP quickstart, `llms.txt` |
| 0003 | Elephant Edge (EE+) Strategy User Guide — level map, signals, SL/TSL, positioning, studio | `docs/strategies/elephant-edge/` | Implemented 2026-11-15 (T11.2) — `overview.md`, `level-map.md`, `signals.md`, `stops-positioning.md`, `studio.md`, `index.md` (strategy engine / Studio / chat tools documented as planned per `tantra-strategies` plan 0001, `tantra-ui` plan 0006, `tantra-agent` plan 0011); **`reference.md` added for T12.10 (2026-11-15)** — full parameter reference, declarative configuration example, and worked session walk-through, using only the shipped gap-0006 SDK models. |
