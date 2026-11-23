# 0005 — Pages still describing legacy `honba` runtime/crate names

**Status**: open
**Filed**: 2026-11-23 — workspace design review (root plan 0021) · **Kind**: design-flaw · **Severity**: medium
**Plan**: [0006](../plans/0006-design-review-2026-11.md)

## What's stubbed or hardcoded

Active guidance still uses retired names.

- `docs/ai/toolsets/backtest.md:4,11,48,70`, `docs/ai/toolsets/index.md:55` and `docs/ai/mcp_gateway.md:152` say "honba-ya runtime" and show `"runtime": "honba-ya"` in a sample result.
- `docs/architecture/ddd_conflicts_resolutions.md:3-5,11,57,74,90,92,113` frames active guidance through `honba-*` old/new columns.
- `docs/examples/index.md:449` names `honba` verification.
- In total 11 docs files match `honba|vyapaar`.

## Why

A reader searching for `honba-ya` finds a runtime that does not exist, and the sample JSON teaches an invalid value. The binding rule `.agents/rules/coding-and-ddd.md` section 3 forbids new legacy references.

## How to close it

1. Replace the names with `tantra-runtime` (and `tantra` equivalents) in the pages above; correct the sample result value.
2. Keep `honba` names only inside `migration-guide.md` and the roadmap pages.
3. Add a CI grep: `! rg -n 'honba' docs --glob '!migration-guide.md' --glob '!roadmap/*'` (extend to `vyapaar` as appropriate).

**Verification**: the CI grep passes; `mkdocs build --strict`.

## Related

- Root plan 0019 P0.5 covers the scripts only, not page content.
- Provider: `tantra-agent` MCP tool descriptions emit the same text; fix there too so the two stay consistent.
