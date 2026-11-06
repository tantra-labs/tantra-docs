# 0001 — Documentation Plan: MCP Quantitative Gateway & 15 Engine Reference

> **Status**: Ready for implementation.
> **Target Files**: `vyapaar-docs/docs/ai/mcp_gateway.md`, `vyapaar-docs/docs/ai/toolsets/*.md`, `vyapaar-docs/docs/getting-started/mcp.md`.
> **Depends on reading**:
> - `vyapaar-agent/docs/plans/0001-mcp-gateway-discovery-and-quantitative-engines.md`
> - `vyapaar-ui/docs/plans/0003-mcp-gateway-result-rendering-and-client-configs.md`
> - Fincept MCP Documentation (`https://docs.fincept.in/`)

---

## 0. Executive Summary & Objective

Fincept provides a gold-standard documentation pattern for quantitative AI tools ([docs.fincept.in](https://docs.fincept.in/)):
- A fast discovery guide (`llms.txt`, `quickstart`).
- Dedicated client connection guides for every major AI coding tool (Claude Code, Cursor, Codex, VS Code).
- Comprehensive API reference for every quantitative engine with input schemas, return envelopes, and parameter bounds.

This document plans the corresponding documentation rollout in `vyapaar-docs` to ensure users and AI agents have exhaustive, high-quality documentation for Vyapaar's MCP gateway and 15 quantitative engines.

---

## 1. Documentation Structure

```
vyapaar-docs/docs/
├── ai/
│   ├── index.md                      # Overview of AI architecture & NoFX principle
│   ├── mcp_gateway.md                # MCP Server, transports (Stdio/SSE), and discovery
│   ├── personas.md                   # 9 Specialized financial personas & skills
│   ├── result_protocol.md            # Universal result envelope (vyapaar/result/v1)
│   ├── toolsets/                     # Dedicated reference per engine
│   │   ├── market.md                 # Quotes, candles, order books, holiday calendar
│   │   ├── technicals.md             # 200+ indicators & 61 candlestick patterns
│   │   ├── scanner.md                # Universe screens, 4,000 fields & custom formulas
│   │   ├── analytics.md              # Performance tearsheets, Sharpe, Sortino, drawdowns
│   │   ├── validation.md             # DSR, PBO, and statistical backtest verification
│   │   ├── allocation.md             # Portfolio optimization (MVO, HRP, Black-Litterman)
│   │   ├── risk.md                   # Pre-trade SEBI margin checks, VaR, CVaR
│   │   ├── regimes.md                # HMM calm/turbulent regime detection
│   │   ├── volatility.md             # GARCH models, volatility cone, HAC covariance
│   │   └── ledger.md                 # Indian statutory taxes (STT, GST) & capital gains
│   └── clients/                      # Connection guides
│       ├── claude_code.md            # Setup with Claude Code CLI
│       ├── cursor.md                 # Setup with Cursor IDE
│       └── vs_code.md                # Setup with GitHub Copilot agent mode
└── llms.txt                          # Machine-readable documentation index for coding agents
```

---

## 2. Key Documentation Deliverables

### 2.1 Machine-Readable Documentation Index (`llms.txt`)
Deploy `vyapaar-docs/docs/llms.txt` following the modern standard so external LLM coding agents connecting to Vyapaar can index the entire quantitative toolset catalog in a single turn.

### 2.2 Client Connection Guides
Provide exact configuration snippets and setup steps:
- Running `vyapaar mcp config --client <name>`.
- Testing connection with `tools/list` and `vyapaar_search_tools`.

### 2.3 Interactive Example Prompts
Document canonical quantitative workflows:
- *"Calculate walk-forward Sharpe and DSR for Momentum strategy on NIFTY 50"*
- *"Scan for breakout candidates with RSI > 60 and calculate exact delivery statutory charges"*
- *"Fit a 2-state Hidden Markov Model on BANKNIFTY returns to classify the current volatility regime"*

---

## 3. Implementation Phases

### Phase 1: Core Gateway Documentation
- Overhaul `docs/ai/mcp_gateway.md` from stub into complete reference guide.
- Create `docs/llms.txt`.

### Phase 2: Client Connection Guides
- Add guides for Claude Code, Cursor, and VS Code.

### Phase 3: Engine Reference Pages
- Generate reference markdown pages for all 15 quantitative engines with input schemas and examples.
