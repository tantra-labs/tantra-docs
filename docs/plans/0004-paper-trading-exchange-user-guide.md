# 0004 — Paper Trading Exchange User Guide

**Status**: Implemented (T14.15, 2026-11-16).
**Track**: T14 (P4) · **Phase**: 6 (documentation)
**Owning repo**: `tantra-docs` · **Master plan**: root `docs/plans/0007-*.md`

## Why

Once the paper exchange ships (root plan 0007), users need one guide that covers every
embedding: CLI session, REST `/orders` + `/ws/live`, Python SDK (`tantra.paper`), and the
web/CSR panel. Tantra's docs rule requires code snippets to correspond to tested code in
`tantra-examples` / `tantra-strategies`, so this guide lands after those surfaces exist.

## Deliverables

- `docs/paper-trading/index.md` — what the paper exchange is (real-exchange mimic), when to
  use it vs backtest vs live broker.
- `docs/paper-trading/cli.md` — `tantra-cli paper --mode embedded|server` walkthrough.
- `docs/paper-trading/python.md` — `tantra.paper.PaperSession` snippet (seeded deterministic
  session), verified against `tantra-examples` paper example.
- `docs/paper-trading/rest-ws.md` — `POST /orders`, `DELETE /orders/{id}`,
  `POST /positions/close`, `/ws/live` event shapes.
- `docs/paper-trading/web.md` — `PaperPanel` embedded vs server modes.
- Nav + index wiring; `mkdocs build --strict` gate.

## Verification

```bash
mkdocs build --strict
```

## Cross-repo dependencies

- **Requires** P0–P3 surfaces: `tantra-exec` plan 0003, `tantra-runtime` plan 0005,
  `tantra-ffi` plan 0003, `tantra-ui` plan 0008 (all shipped), and the `tantra-examples`
  paper example (T14.11).
