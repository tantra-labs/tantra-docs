# Quantitative Toolset — Engine Reference

The **quantitative toolset** is the reference catalogue for the 15 engines
that make up the Tantra quantitative stack: market data, technicals, scanning,
statistical analytics, validation, allocation, risk, regimes, volatility, the
ledger, statutory calculation, research, backtesting, forecasting, and
derivatives.

Every engine is reachable through the [MCP gateway](../mcp_gateway.md) in one
of two ways:

- a dedicated `tantra_*` MCP **quant tool** (called directly by agents and the
  persona loop), or
- the **conversational tool surface** shipped by `tantra-agent-chat-tools`
  (32 read-only tools + 2 LocalWrite trade tools).

All results — from either surface — are returned in the
[`tantra/result/v1` envelope](../result_protocol.md), and every `tantra_*`
tool accepts an optional `_jq` JSONPath filter applied to the response payload.

## Two-tier discovery

Discovery is split across two tiers so an agent can find a tool and validate a
strategy without running a backtest:

1. **Engine surface (this index).** Each engine page enumerates the shipped
   tools for that engine — exact tool names, parameter names, defaults, and
   return shape — and is the authoritative map for a given quantitative task.
2. **Catalogue & spec validation.** `get_indicator_catalog` exposes the
   technicals catalogue (200+ indicators, 61 candlestick patterns) with its
   bounds; `check_spec` validates a strategy manifest without dispatching a
   backtest. Both are base gateway tools documented on the
   [technicals](technicals.md) and [backtest](backtest.md) pages.

For the result shape, metadata, and `DisplayBlock` types, see the
[result protocol](../result_protocol.md). For the personas that drive these
tools, see [Personas](../personas.md).

## The 15 engines

| Engine | Page | What it does |
| :--- | :--- | :--- |
| Market | [market.md](market.md) | Quotes, history, L2 depth, options chains, block deals, corporate actions, institutional flows, delivery and OI analytics. |
| Technicals | [technicals.md](technicals.md) | 200+ indicators and 61 candlestick patterns via the indicator catalogue. |
| Scanner | [scanner.md](scanner.md) | 4,000-field universe screening. |
| Analytics | [analytics.md](analytics.md) | Monte Carlo, cointegration, walk-forward, factor attribution, change-point, copula tail risk, permutation tests. |
| Validation | [validation.md](validation.md) | DSR/PBO overfitting detection and performance validation. |
| Allocation | [allocation.md](allocation.md) | MVO, HRP, risk-parity and Black–Litterman portfolio construction. |
| Risk | [risk.md](risk.md) | SEBI pre-trade risk gate, decision explanation, copula tail risk. |
| Regimes | [regimes.md](regimes.md) | HMM regime detection and two-sided CUSUM change points. |
| Volatility | [volatility.md](volatility.md) | GARCH(1,1) conditional volatility modelling. |
| Ledger | [ledger.md](ledger.md) | FIFO tax-lot accounting, positions, P&L and tax reports. |
| Calc | [calc.md](calc.md) | Indian statutory cost calculation (STT, GST, stamp duty, exchange charges). |
| Research | [research.md](research.md) | Genetic/Bayesian strategy optimization. |
| Backtest | [backtest.md](backtest.md) | Strategy-manifest validation and dispatch to the honba-ya runtime. |
| Forecast | [forecast.md](forecast.md) | Time-series point forecasts with prediction intervals. |
| Derivatives | [derivatives.md](derivatives.md) | Black–Scholes–Merton pricing and the Greeks. |

## Reading an engine page

Every engine page follows the same anatomy: an overview, a **MCP gateway
tools** table (exact tool name, inputs with defaults, return shape), a
**chat-tool surface** section where conversational tools also serve the
engine, a JSON example call with the `tantra/result/v1` envelope, and an
honest status line — engines served primarily by chat tools say so plainly,
and stub tools (`PortError::unavailable`) are flagged rather than implied to
be live.

## Beyond the 15 engines

The 32 read-only chat tools also include content/news surfaces (`news_search`,
`filings_search`), fundamentals, mutual-fund and IPO surfaces (`fundamentals`,
`financial_statements`, `fund_search`, `fund_holdings`, `ipo_calendar`,
`ipo_subscription`), and the economic calendar (`economic_calendar`, scheduled
RBI/CPI/GDP/FOMC releases with IN/US countries and high/medium/low impact).
These are catalogued on the [MCP gateway](../mcp_gateway.md) page.

!!! note "Stub surfaces"
    `fundamentals`, mutual-fund and IPO tools are shipped as
    `PortError::unavailable` stubs citing `tantra-data` gaps 0020–0022; on the
    market engine, `institutional_flows` and `market_depth` are stubs citing
    `tantra-data` gaps 0017/0018 and `tantra-market` gap 0006. Do not imply
    live data where only the stub is shipped.

## Related

- [MCP gateway](../mcp_gateway.md) — the gateway that hosts these tools.
- [Result protocol](../result_protocol.md) — the `tantra/result/v1` envelope and `DisplayBlock` types.
- [Personas](../personas.md) — the agents that drive the toolset.
- [Getting started with MCP](../../getting-started/mcp.md).
