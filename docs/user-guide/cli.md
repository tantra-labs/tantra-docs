# The `tantra` CLI

The `tantra` binary is the native workstation command line (built by
`tantra-ui`, binary name `tantra`). It is the fastest way to get an answer, a
scan, a backtest, a paper session, or a scheduled job — and everything it does
is scriptable.

## Finding the Binary

After a successful `make prod` the binary lives at:

```bash
tantra-ui/target/prod/tantra
```

Add it to your `PATH` (or symlink it into a directory that is on your `PATH`):

```bash
export PATH="$PWD/tantra-ui/target/prod:$PATH"
tantra --version
```

> The Python SDK also ships a small `tantra` command (`python -m tantra.cli`,
> subcommands `version` and `backtest`). This page is about the **native**
> binary. If a command below does not parse, you are probably on the Python
> one — run `tantra --help` and check that `strategy`, `paper`, `jobs`,
> `serve`, `scan` are listed.

## Global Flags

These apply to every subcommand:

| Flag | Meaning |
|:-----|:--------|
| `--model-path PATH` | Local GGUF model file (for `ask` / `chat` / `tui`). |
| `--temperature 0..1` | Sampling temperature for the agent. |
| `--log-level debug\|info\|warn\|error\|silent` | Log verbosity (env `TANTRA_LOG_LEVEL` also works). |
| `-v` / `--verbose` | Shortcut for `--log-level debug`. |
| `-q` / `--quiet` | Shortcut for `--log-level silent`. |
| `--skip-permissions` | Auto-accept agent tool confirmations (aliases: `--dangerously-skip-permissions`, `--yolo`). |
| `-c` / `--continue` | Resume the latest session in the current directory. |
| `-r` / `--resume SESSION_ID` | Resume a specific session. |

## Command Index

| Subcommand | What it does | See |
|:-----------|:-------------|:----|
| `ask` | One headless question to the AI agent | [AI & Automation](ai.md) |
| `chat` | Interactive conversational agent | [AI & Automation](ai.md) |
| `scan` | Run a screener scan (offline fixture or `--server`) | below |
| `serve` | Boot the REST/WebSocket API server | [REST API Workflows](rest-api.md) |
| `strategy` | List / run / tune / suggest strategies | below |
| `paper` | Deterministic paper-trading session (embedded or server client) | [Paper Trading](../paper-trading/index.md) |
| `jobs` | Autonomous scheduled jobs and approvals | [AI & Automation](ai.md) |
| `verify` | Verify a strategy manifest for lookahead bias / leakage | below |
| `tools` | Search / describe / call MCP gateway tools | [AI & Automation](ai.md) |
| `mcp` | Manage MCP servers; generate client config | [AI & Automation](ai.md) |
| `memory` | Semantic memory: distill, stats, model, import, install | below |
| `plugin` | Plugins, skills, marketplace | below |
| `skills` | List / show installed financial skills | below |
| `doctor` | Environment diagnostics + `--fix` | [Installation](../getting-started/installation.md) |
| `health` | Print a system health report | below |
| `purge` | Remove caches and session traces (`--dry-run` first) | below |
| `tui` | The Ratatui terminal workstation (default command) | below |

## Strategy Work: `strategy`

```bash
tantra strategy list                                # discover built-in + manifest strategies
tantra strategy run sma_crossover --symbol NSE:RELIANCE-EQ --capital 1000000
tantra strategy run sma_crossover --params '{"fast_period":12}' --format json
tantra strategy tune sma_crossover --symbol NSE:NIFTY50-INDEX --metric sharpe
tantra strategy suggest sma_crossover --symbol NSE:RELIANCE-EQ --capital 1000000 --risk-pct 1.0
```

- `run` runs one backtest and reports the outcome; `--params` is a JSON object
  of parameter overrides, `--format json` emits machine-readable output.
- `tune` runs a parameter grid search with overfitting guardrails; `--metric`
  is `sharpe` or `pnl`.
- `suggest` tunes and then recommends a position sized to `--risk-pct` of the
  account.
- `verify` (below) checks a manifest *before* you spend time running it.

## Screener: `scan`

```bash
tantra scan "roe>15 and pe between 10 30"                    # offline fixture universe
tantra scan "close > sma20" --server http://127.0.0.1:8000 --universe '["RELIANCE.NSE","INFY.NSE"]' --tf 1m
```

Without `--server` the scan runs against the offline fixture universe. With
`--server` it evaluates the same query on the live `GET /api/v2/screener/scans`
endpoint of a running `tantra serve` (see
[REST API Workflows](rest-api.md)).

## Verification: `verify`

```bash
tantra verify manifest.json            # compiles the manifest, prints the IR
tantra verify strategy.py --strict     # treat warnings (fit-before-split) as fatal
```

This is the CLI form of `POST /strategies/verify`: it checks a strategy
manifest or algorithm script for lookahead bias and data leakage before you
commit to a run.

## Housekeeping: `doctor`, `health`, `purge`

```bash
tantra doctor          # environment diagnostics
tantra doctor --fix    # provision missing directories, tables, sidecars
tantra doctor --json   # machine-readable report
tantra health          # concise system/environment report
tantra purge --dry-run # show what would be deleted
tantra purge --yes     # actually delete caches and session traces
```

## Plugins, Skills, Memory

```bash
tantra plugin list
tantra plugin install <name>        tantra plugin uninstall <name>
tantra plugin enable <name>         tantra plugin disable <name>
tantra plugin validate <path>       tantra plugin marketplace list

tantra skills list                  tantra skills show quant

tantra memory stats                 # notes / vectors / storage
tantra memory tick                  # distill recent transcripts into facts
tantra memory import ~/research     # ingest notes, PDFs, strategy markdown
tantra memory model <name>          # set the active embedding model
tantra memory install               # systemd/cron snippet for auto-distillation
```

## Machine-Readable Output

Commands that take `--format json` emit a single JSON document on stdout —
pipe them into `jq` in scripts:

```bash
tantra strategy run sma_crossover --format json | jq '.metrics'
```

## Tips

- **Start with `doctor`.** After a fresh install, `tantra doctor --fix`
  provisions whatever the runtime expects and makes the failure mode of the
  next command obvious instead of cryptic.
- **`verify` before `run`.** A manifest that fails `verify --strict` will not
  produce a trustworthy backtest.
- **Prefer `paper` over live adapters today.** The paper exchange is the
  deterministic, offline stand-in for a broker — see
  [Paper Trading](../paper-trading/index.md).
- **The TUI is still there.** Running `tantra` with no arguments (or `tantra
  tui`) opens the Ratatui terminal workstation with watchlist, screener,
  portfolio, and orders panels.
