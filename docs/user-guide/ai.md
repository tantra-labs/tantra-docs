# AI & Automation

The headless AI layer turns the platform into an agent that can research,
screen, backtest, and even run scheduled strategy jobs — all from the CLI,
or wired into an external coding agent through the MCP gateway.

## LLM Backends

The agent needs a model. Three ways, in priority order:

| Backend | Configuration |
|:--------|:--------------|
| Local GGUF | `--model-path models/foo.gguf` (or env `TANTRA_GGUF_PATH`) |
| OpenAI-compatible endpoint | `TANTRA_LLM_BASE_URL`, `TANTRA_LLM_MODEL`, optional `TANTRA_LLM_API_KEY` (e.g. an OmniRoute local router or Ollama at `http://localhost:11434/v1`) |
| Cloud providers | The agent engine also supports Anthropic / OpenAI via their standard API keys (see [AI Engine & Quant Researcher](../architecture/ai_engine.md)) |

Without a backend, `tantra ask` / `tantra chat` explain exactly what is
missing (e.g. `tantra chat (no model found. Provide --model-path or
TANTRA_GGUF_PATH)`).

## One-Shot Questions: `tantra ask`

```bash
tantra ask "What is the current drawdown of a 20/50 SMA cross on RELIANCE?" 
tantra ask "Screen NIFTY 50 for RSI < 30" --persona quant --format json
tantra ask "Backtest this strategy" --mode backtest --timeout-min 30 --profile default
```

| Flag | Meaning |
|:-----|:--------|
| `--persona` | Specialized financial persona (quant, analyst, trader, risk-manager, ...) — see [Personas](../ai/personas.md) |
| `--mode paper\|backtest` | Runtime execution mode (default `paper`) |
| `--profile` | Configuration profile (default `default`) |
| `--timeout-min` | Max minutes for the agent loop (default `20`) |
| `--format json` | Machine-readable answer |

## Interactive Chat: `tantra chat`

```bash
tantra chat
tantra chat --system-prompt "You are a risk manager. Never suggest a position over 2% of the account."
```

The Ratatui `tui` workstation (default command) wraps the same agent with
watchlist, screener, portfolio, and orders panels.

## The MCP Gateway: `tantra tools`

The quantitative gateway exposes **22 tools** across 15 engines (market,
technicals, scanner, analytics, validation, allocation, risk, regimes,
volatility, ledger, calc, research, backtest, forecast, derivatives).
Discover, inspect, and call them from the terminal:

```bash
tantra tools search "volatility"                 # find tools by name/category/tagline
tantra tools describe tantra_garch_volatility    # JSON schema for one tool
tantra tools call tantra_garch_volatility '{"symbol": "NSE:NIFTY50-INDEX", "window": 22}'
```

See [MCP Gateway](../ai/mcp_gateway.md) for the full 22-tool reference and
[Result Protocol](../ai/result_protocol.md) for the `tantra/result/v1`
envelope.

## External AI Coding Agents: `tantra mcp`

```bash
tantra mcp config --client claude-code     # print the config for Claude Code
tantra mcp config --client cursor
tantra mcp config --client vscode
tantra mcp config --client gemini
```

Each prints the client-specific MCP server configuration so your coding agent
can call the same 22 quantitative tools. Step-by-step guides:
[Claude Code](../ai/clients/claude_code.md), [Cursor](../ai/clients/cursor.md),
[VS Code](../ai/clients/vs_code.md), [Gemini CLI](../ai/clients/gemini.md).
Quickstart: [MCP Quickstart](../getting-started/mcp.md).

## Autonomous Jobs: `tantra jobs`

Schedule the agent to run research on a cron schedule, with budgets and an
approval gate:

```bash
# Add a job: research RELIANCE every weekday at 07:30 IST, ₹2 budget cap
tantra jobs add "Research RELIANCE and suggest a trade plan" \
  --schedule "30 7 * * 1-5" --strategy sma_crossover --symbol NSE:RELIANCE-EQ \
  --capital 1000000 --max-inr 2 --approval auto

tantra jobs list                # all scheduled/active jobs
tantra jobs run <id>            # run one job now
tantra jobs tick                # evaluate schedules and run due jobs
tantra jobs approvals           # pending actions needing a human
tantra jobs approve <id>        tantra jobs deny <id>
tantra jobs logs <id>           # per-run journal (manifest.json, events.ndjson, trades.json, metrics.json)
tantra jobs install             # systemd timer / crontab snippet
```

`--approval manual` holds every run behind a human approval; `--approval auto`
runs within budget and only gates breaches. Budget refusals (429-class) mint
no run id and write no journal. Full reference:
[Runtime Job Scheduler](../architecture/runtime_jobs.md).

## Memory & Plugins

`tantra memory tick` distills recent conversations into semantic facts;
`tantra memory import ~/research` ingests notes and PDFs. `tantra plugin` and
`tantra skills` manage the extension surface. See
[The `tantra` CLI](cli.md).

## What the AI Cannot Do

The agent is an **untrusted signal generator** (NoFX principle): it cannot
emit arbitrary commands or bypass the pre-trade risk gate. Every AI decision
parses into the closed `Decision` grammar, and every prompt/completion is
hashed and archived for deterministic replay. See
[AI Engine & Quant Researcher](../architecture/ai_engine.md) and
[Research Loop](../ai/research_loop.md).
