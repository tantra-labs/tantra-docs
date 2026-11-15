# MCP Quickstart

This guide gets a coding agent talking to Tantra through the MCP gateway in four steps: install,
launch, connect, run.

## Prerequisites

- The `tantra` CLI, installed from the PyPI wheel compiled by `tantra-ffi` (PyO3). The CLI ships
  the MCP gateway commands.
- An MCP-capable client: Claude Code, Cursor, VS Code Copilot Agent mode, or Gemini CLI.

## 1. Install

Install the `tantra` package (the Python SDK + CLI wheel). Confirm the CLI is available:

```bash
tantra --help
```

## 2. Launch the gateway

Run the stdio server in the foreground:

```bash
tantra mcp --stdio
```

This is the `mcp_stdio_server` binary: JSON-RPC 2.0 over stdin/stdout. Local clients spawn it on
demand through their `mcpServers` config, so in normal use you do not keep a server process open
by hand. For remote clients the same gateway serves an SSE/HTTP transport (Axum) exposing `/sse`
and `/message`.

## 3. Connect a client

One command writes the correct config for your client:

```bash
tantra mcp config --client claude-code
```

`--client` accepts `claude-code`, `cursor`, `vscode`, or `gemini`. See the connection guides:

- [Claude Code](../ai/clients/claude_code.md)
- [Cursor](../ai/clients/cursor.md)
- [VS Code (Copilot Agent)](../ai/clients/vs_code.md)
- [Gemini CLI](../ai/clients/gemini.md)

## 4. Run your first tool

The CLI gateway mirrors the MCP server:

```bash
tantra tools search "GARCH volatility"
tantra tools describe tantra_garch_volatility
tantra tools call tantra_garch_volatility '{"returns": ["0.001", "-0.002", "0.003", "0.001"], "forecast_horizon": 5}'
```

The last command returns a `tantra/result/v1` envelope with `status: "ok"`, GARCH(1,1) parameter
estimates, and conditional volatility forecasts.

## Try a canonical workflow

Once connected, ask your agent for a full research task:

- *"Calculate walk-forward Sharpe and DSR for Momentum strategy on NIFTY 50."*
- *"Scan for breakout candidates with RSI > 60 and calculate exact delivery statutory charges."*
- *"Fit a 2-state Hidden Markov Model on BANKNIFTY returns to classify the current volatility
  regime."*

## Next steps

- [MCP Gateway reference](../ai/mcp_gateway.md) — the full 22-tool catalog.
- [Universal Result Protocol](../ai/result_protocol.md) — the response envelope.
- [Agent Personas](../ai/personas.md) — the 9 research personas.
- [Quantitative Toolsets](../ai/toolsets/index.md) — the 15 engines behind the tools.
