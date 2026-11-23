# 0006 — Architecture/conformance pages reference nonexistent `tantra-fe` and omit `tantra-ui-web`

**Status**: open
**Filed**: 2026-11-23 — workspace design review (root plan 0021) · **Kind**: design-flaw · **Severity**: medium
**Plan**: [0006](../plans/0006-design-review-2026-11.md)

## What's stubbed or hardcoded

- `docs/conformance_matrix.md:37,45` lists `tantra-fe` as IMPLEMENTED (count 17); the workspace `AGENTS.md` tier table has `tantra-ui-web`, not `tantra-fe`.
- `docs/architecture/tradebook.md:9,31-33` and `docs/architecture/kao_simulator_port.md:10` cite paths under `tantra-fe/apps/web/src/...`, which are no longer in any repo.
- `docs/architecture/architecture_layers.md:26` lists only `tantra-ui` (Leptos/TUI/CLI) in the L5 row; `tantra-ui-web` has a single passing mention (`docs/user-guide/index.md:63`).
- `scripts/verify_conformance.py:1-4` still titles itself "honba-docs".

## Why

The conformance matrix is the stated source of truth for status, yet it contradicts the workspace tier table on L5 and counts a nonexistent repo as implemented.

## How to close it

1. Rename `tantra-fe` to `tantra-ui-web` across the matrix and design docs, and fix or drop the dead file paths.
2. Add `tantra-ui-web` to the L5 row of the layer table.
3. Regenerate the conformance counts with the fixed script, and retitle `scripts/verify_conformance.py`.

**Verification**: `rg -n 'tantra-fe' docs` returns nothing; counts match a fresh script run; `mkdocs build --strict`.

## Related

- Root plan 0019 P0.5 (partial: script filter only; this gap is the content fallout).
- [0005](0005-legacy-honba-wording.md): the same title fix applies to the script.
