# 0003 — Declared mkdocstrings/redirects plugins not configured; Python API reference is hand-written

**Status**: open
**Filed**: 2026-11-23 — workspace design review (root plan 0021) · **Kind**: refactor · **Severity**: medium
**Plan**: [0006](../plans/0006-design-review-2026-11.md)

## What's stubbed or hardcoded

The requirements declare plugins that the site never enables.

- `requirements.txt` pins `mkdocstrings[python]==0.26.1`; `requirements-dev.txt` adds `mkdocs-redirects` and `mdx-truly-sane-lists`.
- `mkdocs.yml:45-46` has `plugins:` with `search` only; no `:::` mkdocstrings directive exists anywhere in `docs/`.
- `docs/api/python/index.md:1-30` is a hand-written package table, and its quickstart imports `rust_decimal` in Python at `:24`.

## Why

The Python API reference is manual prose and drifts from the wheel (`tantra-ffi/python/tantra/__init__.pyi`). The repo has had several page renames; without `redirects` those produce dead inbound links.

## How to close it

1. Generate reference pages from the wheel stubs with mkdocstrings (griffe on `.pyi`), for example `::: tantra.backtest.session`, and replace the hand-written table.
2. Enable the `redirects` plugin with a map for every renamed page.
3. Fix the quickstart snippet at `docs/api/python/index.md:24` so it imports from the `tantra` package.
4. Drop dependencies that remain unused after the change.

**Verification**: `mkdocs build --strict` renders the generated pages; a rename test page confirms the redirect map; the quickstart snippet is run against an installed wheel.

## Related

- [0004](0004-api-reference-provenance.md): the REST reference has a parallel generation problem.
- `tantra-ffi` plan 0005 (stub and codegen drift gate) keeps the `.pyi` stubs authoritative.
