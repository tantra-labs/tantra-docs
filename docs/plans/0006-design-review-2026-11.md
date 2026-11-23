# 0006 — tantra-docs design review (2026-11): publishing, generated references & operator documentation

**Status**: Proposed (2026-11-23)
**Scope**: `tantra-docs` · **Umbrella**: root `docs/plans/0021-workspace-design-review-2026-11.md`

## 0. Executive Summary & Objective

The review found that the site builds but is not published or versioned, has no operator documentation, carries "generated" references that are hand-committed, and still contains legacy `honba` and `tantra-fe` names. This plan makes the site publishable and versioned, adds an operations section, wires generated references to their sources, and removes stale naming. Non-goals: the scripts-level `honba` filter work owned by root plan 0019 P0.5, and the build/CI/release design itself, which belongs to root plan 0023.

## 1. Context & Gaps Covered

| Gap | Title | Kind | Severity |
|---|---|---|---|
| [0001](../gaps/0001-publish-and-versioning.md) | No deploy/publish pipeline and no versioned docs | deployment | high |
| [0002](../gaps/0002-operator-docs.md) | No operator documentation | deployment | high |
| [0003](../gaps/0003-generated-python-api-reference.md) | Python API reference not generated; plugins unconfigured | refactor | medium |
| [0004](../gaps/0004-api-reference-provenance.md) | "Generated" API reference hand-committed, no regeneration step | design-flaw | medium |
| [0005](../gaps/0005-legacy-honba-wording.md) | Legacy `honba` wording in pages | design-flaw | medium |
| [0006](../gaps/0006-architecture-tier-drift.md) | `tantra-fe` references and missing `tantra-ui-web` tier | design-flaw | medium |

Plan-only items (no standalone gap doc):

- R1 — Orphan pages, stale nav targets and no link/anchor validation (low) — `docs/plans/README.md` is not in `nav` and there is no `exclude_docs`/`not_in_nav` in `mkdocs.yml`; nav keeps migration-era pages (`mkdocs.yml:89,91` `kao_simulator_port.md`, `migration_plan_kokoro_risk_to_mon.md`; `mkdocs.yml:188-190` `roadmap/roadmap.md`, `migration-guide.md`) and a planned-adapters design page (`mkdocs.yml:184-186`, `docs/api/adapters.md:10`) as first-class content.
- R2 — Design docs duplicated between this site and root `docs/` (medium) — `docs/design/architecture.md` differs from the root `docs/design/architecture.md`, and root design docs 0001..0006 (crate topology, runtime API surface, ACP orchestration) are absent here; root `docs/reading-list/` and `docs/training/` are mdBook trees outside MkDocs; `docs/examples/index.md` (449+ lines) restates `tantra-examples/README.md`; `docs/roadmap/roadmap.md` (38 lines) overlaps root `docs/task-list-tracks-and-phases.md`.

## 2. Component Specifications & Phases

### Phase A — quick, low-risk fixes
1. Gap 0005: replace legacy names, add the CI grep.
2. Gap 0006: rename `tantra-fe`, add `tantra-ui-web` to the layer table, regenerate counts.
3. Gap 0004 (part): correct the crate name at the three cited locations.
4. R1: add `exclude_docs: plans/` (or `not_in_nav`), enable the `validation:` block with `links.anchors: warn`, move migration/history pages into an Archive nav section or delete them (git history keeps them).

**Gate**: `mkdocs build --strict`; `rg -n 'honba' docs --glob '!migration-guide.md' --glob '!roadmap/*'` and `rg -n 'tantra-fe' docs` both empty.

### Phase B — generated references and single-sourcing
1. Gap 0003: mkdocstrings reference pages from `.pyi` stubs, `redirects` map, snippet fix.
2. Gap 0004: `make api-docs` plus the CI diff check; render OpenAPI from `openapi.v2.json`.
3. R2: decide ownership (root `docs/design` holds ADRs, synced into `docs/design/` by a script or snippets); delete the divergent `architecture.md`; publish or link reading-list and training; add a CI check that synced copies are identical.

**Gate**: `mkdocs build --strict`; regeneration on a clean checkout yields an empty `git diff`; sync check passes.

### Phase C — deployment readiness
1. Gap 0001: deploy job on `main` and tags, `mike` versioning, pinned plugins, PR previews, link-check job.
2. Gap 0002: `docs/operations/` section (service install, config reference, auth/JWT/CORS, TLS/proxy, backup/restore, upgrade/rollback, observability, SEBI checklist), nav entry, link from `getting-started/`.

**Gate**: `mkdocs build --strict`; dry-run deploy of `dev` and of a test version tag.

## 3. Relationship to Other Plans

- Root `docs/plans/0019-codebase-audit-refactoring-unification-and-wiring.md` P0.5: scripts filter only; this plan owns page content.
- Root `docs/plans/0023-build-ci-release-engineering.md`: feeds from gap 0001 (publish, versioning, pinned requirements).
- Root `docs/plans/0022-future-deployment-architecture.md`: gap 0002 documents what that plan defines.
- Root gap 0022 (canonical OpenAPI) is the source for gap 0004.
- Provider repos: `tantra-ffi` (codegen and stubs), `tantra-agent` (MCP tool descriptions with the same legacy text).

## 4. Exit Criteria

1. `docs.tantra-labs.io` is deployed from CI, with a version selector driven by wheel tags.
2. `docs/operations/` exists, is in nav, and is linked from getting-started.
3. Python and REST references are generated from stubs and OpenAPI; CI fails on drift.
4. No `honba` or `tantra-fe` match outside the allowed archive pages.
5. Plans pages are excluded from the published site; the validation block is on.
6. Design docs have one owner and a CI-enforced sync.
7. `mkdocs build --strict` is green.
