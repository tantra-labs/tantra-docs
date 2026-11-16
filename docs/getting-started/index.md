# Getting Started

This section walks through installing Tantra and running your first
backtest. It assumes no prior experience with the codebase.

## What You Will Need

- A machine with Rust 1.75+ and Python 3.10+ (see
  [Installation](installation.md) for the toolchain setup).
- Roughly 30 minutes for the install and first backtest.
- No broker credentials. Backtesting runs entirely offline against a
  local Parquet catalog.

## The Path

1. **[Installation](installation.md)** — clone the superproject, build the
   Rust workspaces in the `prod` profile, and build the shared Python venv
   with the `tantra` wheel.
2. **[Your First Backtest](first-backtest.md)** — run a moving-average
   crossover on synthetic bars, inspect the cost breakdown, and read the
   metrics.
3. **[Loading Data](loading-data.md)** — synthetic, lakehouse, and Parquet
   bar sources.
4. **[MCP Quickstart](mcp.md)** — connect an AI coding agent (Claude
   Code, Cursor, VS Code, Gemini CLI) to the quantitative MCP gateway.

## After the First Backtest

Once the first backtest runs, the natural next reads are:

- **[User Guide → Overview](../user-guide/index.md)** — the four headless
  work surfaces (CLI, REST API, Python SDK, AI/MCP) that are the stable
  daily driver while the web UI matures.
- **[Architecture → Overview](../architecture/overview.md)** — why
  the codebase is organized the way it is.
- **[India → Cost Model](../india/cost_model.md)** — the cost
  assumptions that determine whether a strategy is viable.
- **[Backtesting → Three-Tier Pipeline](../backtesting/three_tier_pipeline.md)**
  — how to validate a strategy properly.

## A Note on Data

Backtests need historical data. The tutorials use a small synthetic
dataset that ships with the `tantra-examples` package, so no downloads are
required for the first run. For real backtests, the
[Loading Data](loading-data.md) guide covers the lakehouse catalog and
NSE bhavcopy ingestion.
