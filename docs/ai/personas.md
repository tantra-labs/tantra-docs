# Agent Personas

Tantra defines 9 canonical agent personas (from `tantra-agent-prompt/src/persona.rs`). A persona
is a fixed professional lens: it fixes the role, framing, and review priorities used when the AI
layer generates, critiques, or validates a research hypothesis. The research loop and the prompt
builder select personas per task, so a single thesis can be examined from several angles before
the validation suite sees it — and a user can ask for "the bear case" or "the risk manager's
view" and get the corresponding framing.

## Persona index

| ID | Title | Role |
|----|-------|------|
| `tantra-ai` | TantraAI | Lead generalist financial analyst and research-desk coordinator |
| `analyst` | Fundamental Equity Analyst | Fundamental equity research analyst and forensic accountant |
| `devils-advocate` | Devil's Advocate | Thesis stress-tester and bear-case builder |
| `macro-strategist` | Macro Strategist | Rates, currencies, inflation, liquidity |
| `portfolio-manager` | Portfolio Manager | Multi-asset allocation, drift, rebalancing |
| `quant` | Quant | Factor models, backtests, statistical verification |
| `risk-manager` | Risk Manager | Downside VaR, stress testing, position sizing |
| `trader` | Trader | Price action, levels, risk:reward |
| `value-investor` | Value Investor | Moats, owner earnings, margin of safety |

## The personas

### `tantra-ai` — TantraAI

Lead generalist financial analyst and research-desk coordinator. The default orchestrator
persona: it frames the overall research question, assigns and synthesizes the specialist
personas, and produces the research-desk summary.

### `analyst` — Fundamental Equity Analyst

Fundamental equity research analyst and forensic accountant. Reviews financial statements,
accounting quality, cash conversion, and red flags in the reported numbers.

### `devils-advocate` — Devil's Advocate

Thesis stress-tester and bear-case builder. Given a thesis, builds the strongest
counter-arguments, breaks assumptions, and asks what has to be true for the trade to fail.

### `macro-strategist` — Macro Strategist

Reads the macro regime through rates, currencies, inflation, and liquidity. Frames whether the
macro backdrop supports or contradicts an equity or sector thesis.

### `portfolio-manager` — Portfolio Manager

Multi-asset allocation, drift, and rebalancing. Positions a single thesis inside an overall
portfolio construction, sizing, and rebalancing discipline.

### `quant` — Quant

Factor models, backtests, and statistical verification. Demands the numbers: factor exposures,
backtest integrity, walk-forward Sharpe, DSR, PBO, and out-of-sample behavior.

### `risk-manager` — Risk Manager

Downside VaR, stress testing, and position sizing. Focuses on tail outcomes, worst-case scenario
analysis, and how much of the book a position should consume.

### `trader` — Trader

Price action, levels, and risk:reward. Reads structure, support/resistance, entry and exit
levels, and whether the risk:reward at the current price justifies the trade.

### `value-investor` — Value Investor

Moats, owner earnings, and margin of safety. Asks whether the business generates owner earnings,
how durable its competitive moat is, and whether the price offers a margin of safety.

## Using personas

Personas are selected per task by the prompt builder; the [research loop](research_loop.md) runs
hypotheses through the validation suite regardless of which persona generated them. The NoFX
principle applies to every persona: they propose and critique, they never place live orders (see
the [MCP Gateway](mcp_gateway.md) safety invariants).
