# 0001 — No deploy/publish pipeline and no versioned docs

**Status**: open
**Filed**: 2026-11-23 — workspace design review (root plan 0021) · **Kind**: deployment · **Severity**: high
**Plan**: [0006](../plans/0006-design-review-2026-11.md)

## What's stubbed or hardcoded

CI only builds the site; nothing publishes it and there is a single unversioned tree.

- `.github/workflows/ci.yml:1-24` is a single job running `mkdocs build --strict`; there is no `gh-deploy`, Pages, artifact upload or release trigger.
- `mkdocs.yml:3` sets `site_url: https://docs.tantra-labs.io`, but no workflow publishes to that address.
- `requirements.txt` has no `mike`; `mkdocs.yml` has no `version: provider: mike` block.
- Root `Makefile:132` `docs` target only builds/serves locally.
- Deployment notes: the build is hermetic and fast, so a per-PR preview deploy is cheap to add. `site/` should be git-ignored if it is not already. Only mkdocs/material are pinned exactly; unpinned transitive plugins (for example `mkdocs-redirects>=`) can break strict builds.

## Why

The site is never published from CI, and one tree describes `main`. A user of an installed wheel `0.1.x` reads documentation for unreleased APIs, with no way to select the matching version. Unpinned plugin ranges make `--strict` builds non-reproducible (see root plan 0023).

## How to close it

1. Add a deploy job in `.github/workflows/` triggered on pushes to `main` and on tags (GitHub Pages, or object storage plus CDN for `docs.tantra-labs.io`).
2. Adopt `mike`: add it to `requirements.txt`, set `extra.version.provider: mike` in `mkdocs.yml`, and cut a docs version on each wheel tag, with a `latest` alias for the current release and `dev` for `main`.
3. Pin transitive plugins exactly (or use a lock file) in `requirements.txt` and `requirements-dev.txt`.
4. Add a PR preview deploy and a link-check job (see plan item R1 in [0006](../plans/0006-design-review-2026-11.md)).
5. Make sure `site/` is listed in `.gitignore`.

**Verification**: a dry-run deploy on a branch publishes `dev`; tagging a test version produces a selectable version in the site switcher; `mkdocs build --strict` stays green with pinned dependencies.

## Related

- Root plan `docs/plans/0023-build-ci-release-engineering.md` (versioning, per-repo CI).
- [0004](0004-api-reference-provenance.md): generated references need a refresh step in the same release flow.
