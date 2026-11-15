# Claude Code — MCP Connection Guide

Claude Code connects to the Tantra MCP gateway over the stdio transport.

## Configure

```bash
tantra mcp config --client claude-code
```

This writes the `tantra` MCP server into `~/.claude.json`:

```json
{
  "mcpServers": {
    "tantra": {
      "command": "tantra",
      "args": ["mcp", "--stdio"]
    }
  }
}
```

Restart Claude Code so the server is discovered.

## Verify

1. Check `tools/list` — the `tantra` server should show 22 tools.
2. Query the catalog:

```bash
tantra tools search "GARCH volatility"
```

3. Run a first tool through the CLI gateway:

```bash
tantra tools call tantra_garch_volatility '{"returns": ["0.001", "-0.002", "0.003", "0.001"], "forecast_horizon": 5}'
```

Every response is a `tantra/result/v1` envelope (see the [Universal Result
Protocol](../result_protocol.md)).

## Next steps

- [MCP Quickstart](../../getting-started/mcp.md)
- [MCP Gateway reference](../mcp_gateway.md)
