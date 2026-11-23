# 0002 — No operator documentation (deployment, config, auth, backups, upgrades)

**Status**: open
**Filed**: 2026-11-23 — workspace design review (root plan 0021) · **Kind**: deployment · **Severity**: high
**Plan**: [0006](../plans/0006-design-review-2026-11.md)

## What's stubbed or hardcoded

The site has no operations section; the audience is operators of a live algo system.

- `mkdocs.yml:48-190` nav has no Operations/Deployment section. A search for `docker|systemd|backup|prometheus|readyz` across `docs/` finds only `docs/examples/known_issues.md` plus incidental mentions.
- `tantra serve` appears only as usage in `docs/user-guide/rest-api.md:93` and `docs/architecture/runtime_overview.md:11`.
- JWT and `tokens_file` appear only incidentally in `docs/api/rest.md`; there is no setup guide for the fail-closed auth rule (`.agents/rules/security-and-secrets.md` section 1).
- No page covers the `tantra.jsonc` runtime block, ports, persistence (SQLite/Postgres) backup, schema migration, upgrade/rollback, or SEBI static-IP and algo-ID registration.

## Why

A retail-algo deployment needs a static egress IP, algo-ID tagging and audit-retention steps, none of which are written down. Operators are left to infer fail-closed auth, bind and CORS behaviour from source.

## How to close it

1. Add `docs/operations/` with: install as a service, config reference (generated from the config schema once root gap 0028 lands), auth/JWT/CORS, TLS and reverse proxy, backup and restore of persistence and the audit WAL, upgrade and rollback, observability (health/readiness, metrics), and a SEBI checklist.
2. Add the nav entry in `mkdocs.yml` and link the section from `docs/getting-started/`.
3. Keep operator pages in step with the runtime deployment architecture in root plan 0022 and the runtime health/readiness work (`tantra-runtime/docs/gaps/0022-observability-health-readiness.md`).

**Verification**: `mkdocs build --strict`; every command and config key in the new pages is exercised once against a local `tantra serve`.

## Related

- Root plan `docs/plans/0022-future-deployment-architecture.md` (containers/k8s, HA, observability, secrets, SEBI deployment).
- [0001](0001-publish-and-versioning.md): operator pages should be versioned with the release.
