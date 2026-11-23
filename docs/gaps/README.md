# Gap Index — `tantra-docs`

Per workspace rule `.agents/rules/gap-tracking.md`: each gap is an individual missing feature, stub or workaround filed as `docs/gaps/XXXX-*.md`. Numbers are sequential and never reused. When a gap is closed, its document is removed and the item is recorded under "Closed Gaps".

## Open Gaps

| # | Title | Severity | Status | Plan |
|---|-------|----------|--------|------|
| [0001](0001-publish-and-versioning.md) | No deploy/publish pipeline and no versioned docs | high | open | [0006](../plans/0006-design-review-2026-11.md) |
| [0002](0002-operator-docs.md) | No operator documentation (deployment, config, auth, backups, upgrades) | high | open | [0006](../plans/0006-design-review-2026-11.md) |
| [0003](0003-generated-python-api-reference.md) | Declared mkdocstrings/redirects plugins not configured; Python API reference is hand-written | medium | open | [0006](../plans/0006-design-review-2026-11.md) |
| [0004](0004-api-reference-provenance.md) | "Generated" API reference is hand-committed with a bogus crate path and no regeneration step | medium | open | [0006](../plans/0006-design-review-2026-11.md) |
| [0005](0005-legacy-honba-wording.md) | Pages still describing legacy `honba` runtime/crate names | medium | open | [0006](../plans/0006-design-review-2026-11.md) |
| [0006](0006-architecture-tier-drift.md) | Architecture/conformance pages reference nonexistent `tantra-fe` and omit `tantra-ui-web` | medium | open | [0006](../plans/0006-design-review-2026-11.md) |

## Closed Gaps

| # | Title | Closed In |
|---|-------|-----------|
| _(none)_ | — | — |
