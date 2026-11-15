# Cursor — MCP Connection Guide

Cursor connects to the Tantra MCP gateway over the stdio transport.

## Configure

```bash
tantra mcp config --client cursor
```

This writes `.cursor/mcp.json` in the current project workspace:

```json
{
  "mcpServers": {
    "tantra": {
      "command": "tantra",
      "args": ["mcp", "--stdio"],
      "env": {
        "TANTRA_LOG": "info",
        "TANTRA_WORKSPACE": "/path/to/workspace"
      }
    }
  }
}
```

The `env` block is optional. `TANTRA_LOG` controls server logging verbosity and
`TANTRA_WORKSPACE` overrides the workspace root the server resolves data against.

## Verify

1. Check `tools/list` in Cursor's MCP panel — the `tantra` server should show 22 tools.
2. Query the catalog:

```bash
tantra tools search "GARCH volatility"
```

3. Run a first tool:

```bash
tantra tools call tantra_garch_volatility '{"returns": ["0.001", "-0.002", "0.003", "0.001"], "forecast_horizon": 5}'
```

Every response is a `tantra/result/v1` envelope (see the [Universal Result
Protocol](../result_protocol.md)).

## Next steps

- [MCP Quickstart](../../getting-started/mcp.md)
- [MCP Gateway reference](../mcp_gateway.md)
