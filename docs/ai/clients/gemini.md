# Gemini CLI — MCP Connection Guide

The Gemini CLI connects to the Tantra MCP gateway over the stdio transport.

## Configure

```bash
tantra mcp config --client gemini
```

This generates the Gemini CLI MCP configuration via `generate_gemini_cli`, registering the
`tantra` MCP server with the Gemini CLI.

## Verify

1. Check `tools/list` in the Gemini CLI — the `tantra` server should show 22 tools.
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
