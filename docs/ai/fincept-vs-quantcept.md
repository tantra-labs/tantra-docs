# Fincept vs. Quantcept: Which Product Grounded Which Design

Two external products that Tantra has been compared against are often conflated
in passing conversation. They are **separate products**, and each grounded a
*different* part of Tantra's design:

| Product | What it is | Where Tantra referenced it |
| :--- | :--- | :--- |
| **Fincept** | A research platform exposing a quantitative **MCP toolset** (analytics, screener, valuation, filing data). | `tantra-docs/docs/plans/0001` and its sibling per-repo plans (`tantra-market`, `tantra-ledger`, `tantra-agent`, …) — the Fincept/Quantcept **gap-closing initiative** (see the build order below). |
| **Quantcept** | A live, chat-first **AI terminal** product. | `tantra-ui/docs/plans/0002-quantcept-web-ux-reference.md` — the chat-UX research behind the Tantra terminal's chat experience. |

## Why the distinction matters

- `tantra-docs/docs/plans/0001` (MCP gateway & quantitative toolset reference)
  is scoped against **Fincept's MCP toolset specifically**.
- `tantra-ui/docs/plans/0002-quantcept-web-ux-reference.md` is scoped against
  **Quantcept's chat product** (personas, "your instructions", unified chat
  landing pages).
- The gap-closing **build order** lives in `docs/future-work-bottoms-up-build-order.md`
  at the workspace root — it is the index into every per-repo `docs/plans/*.md`
  produced by the initiative, and covers **both** products' feature surfaces.

A reader of this documentation should be able to tell at a glance which
product grounded which design decision. The rule of thumb:

> **Fincept → quantitative tools. Quantcept → chat UX.**

## Mapping

| Tantra design decision | Grounded by |
| :--- | :--- |
| 15 quantitative engines + MCP gateway (`tantra-agent`) | Fincept toolset |
| Indicators breadth, derivatives pricing (`tantra-market`) | Fincept toolset |
| Portfolio allocation & optimization (`tantra-ledger`) | Fincept toolset |
| Screener / market-data read ports (`tantra-data`) | Fincept toolset |
| Terminal chat experience, personas, chat list/portfolio sync (`tantra-ui`) | Quantcept chat product |
