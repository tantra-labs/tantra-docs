# `tantra-docs` — Subagent Migration & DDD Refactoring Guide

> **Tier**: Tier 6E
> **Source**: `honba-workspace/honba-docs`
> **Target**: `tantra-docs`

---

## 1. File & Directory Migration Map

| Source Path (`honba-docs/`) | Target Path (`tantra-docs/`) | Migration Action & Notes |
| :--- | :--- | :--- |
| `docs/*` | `docs/*` | Copy all directory trees (`ai/`, `api/`, `architecture/`, `backtesting/`, `examples/`, `getting-started/`, `india/`, `strategies/`, `tutorials/`, `conformance_matrix.md`). Retain target's `design/` and `roadmap/`. |
| `book/src/architecture/crate_hierarchy.md` | `docs/architecture/crate_hierarchy.md` | Port from mdBook into `docs/architecture/`, updating to Tantra crate names. |
| `book/src/architecture/message_flow.md` | `docs/architecture/message_flow.md` | Port from mdBook into `docs/architecture/`, updating message flow diagrams to Tantra architecture. |
| `book/src/backtesting/avoiding_backtest_biases.md` | `docs/backtesting/avoiding_backtest_biases.md` | Port Tucker Balch's 10 biases guide into `docs/backtesting/`. |
| `book/src/nl-verification.md` | `docs/ai/nl_verification.md` | Replace stub page with full NL-to-strategy documentation from mdBook. |
| `book/src/contributing/*` | `docs/contributing/*` | Port contribution guides (`index.md`, `development_setup.md`, `adding_adapters.md`, `adding_indicators.md`, `dependency_rules.md`). |
| `book/src/cost-model.md` | `docs/india/cost_model.md` | Integrate component breakdowns and statutory Indian transaction tax tables. |
| `book/src/market-calendar.md` | `docs/india/market_calendar.md` | Integrate session windows and auction schedules. |
| `book/` | *(Excluded)* | Eliminate duplicate mdBook tree entirely. |
| `requirements.txt` | `requirements.txt` | Port doc build requirements (`mkdocs`, `mkdocs-material`, `mkdocs-redirects`, `pymdown-extensions`). |
| `requirements-dev.txt` | `requirements-dev.txt` | Port dev doc requirements. |
| `Makefile` | `Makefile` | Update targets for MkDocs single-doc-site build and dev server. |
| `scripts/` | `scripts/` | Port `bootstrap.sh`, `build.sh`, `clean.sh`, `_common.sh`, `serve.sh`, removing mdBook logic. |
| `mkdocs.yml` | `mkdocs.yml` | Update configuration, navigation tree, Material theme settings, and extensions. |

---

## 2. Phased Execution Plan

### Phase 1: Environment & Tooling Setup
1. Create isolated Python 3.13 virtual environment (`.venv`) via `uv venv --python 3.13`.
2. Port `requirements.txt` and `requirements-dev.txt`, removing any pinned dependencies that conflict with modern tooling.
3. Install documentation dependencies (`mkdocs`, `mkdocs-material`, `mkdocs-redirects`, `pymdown-extensions`, `mkdocs-autorefs`, `mkdocstrings`).
4. Port helper scripts in `scripts/` (`_common.sh`, `build.sh`, `serve.sh`, `clean.sh`, `bootstrap.sh`) and `Makefile`, removing all `mdbook` build paths.

### Phase 2: Documentation Asset Migration & mdBook Consolidation
1. Synchronize all subdirectories from `honba-docs/docs/*` to `tantra-docs/docs/`, preserving `design/`, `roadmap/`, and `migration-guide.md`.
2. Transfer unique pages from `honba-docs/book/src/`:
   - `book/src/architecture/crate_hierarchy.md` → `docs/architecture/crate_hierarchy.md`
   - `book/src/architecture/message_flow.md` → `docs/architecture/message_flow.md`
   - `book/src/backtesting/avoiding_backtest_biases.md` → `docs/backtesting/avoiding_backtest_biases.md`
   - `book/src/nl-verification.md` → `docs/ai/nl_verification.md` (overwriting placeholder stub)
   - `book/src/contributing/*` → `docs/contributing/*`
3. Merge detailed reference sections from `book/src/cost-model.md` and `book/src/market-calendar.md` into `docs/india/cost_model.md` and `docs/india/market_calendar.md`.

### Phase 3: Subsystem Terminology & DDD Refactoring
Execute automated and manual refactoring across all markdown files in `docs/`:
- **Subsystem & Crate Names**:
  - `honba-core` → `tantra-core` (`honba_core` → `tantra_core`)
  - `honba-kokoro` → `tantra-ledger` (`honba_kokoro` → `tantra_ledger`)
  - `honba-mon` → `tantra-risk` (`honba_mon` → `tantra_risk`)
  - `honba-me` → `tantra-market` (`honba_me` → `tantra_market`)
  - `honba-te` → `tantra-exec` (`honba_te` → `tantra_exec`)
  - `honba-ya` → `tantra-runtime` (`honba_ya` → `tantra_runtime`)
  - `honba-nou` → `tantra-agent` (`honba_nou` → `tantra_agent`)
  - `honba-tamashii` → `tantra-ffi` (`honba_tamashii` → `tantra_ffi`)
  - `honba-kao` → `tantra-ui` (`honba_kao` → `tantra_ui`)
  - `honba-fe` → `tantra-fe` (`honba_fe` → `tantra_fe`)
  - `honba-data` → `tantra-data` (`honba_data` → `tantra_data`)
  - `honba-adapters` → `tantra-adapters` (`honba_adapters` → `tantra_adapters`)
  - `honba-strategies` → `tantra-strategies` (`honba_strategies` → `tantra_strategies`)
  - `honba-examples` → `tantra-examples` (`honba_examples` → `tantra_examples`)
  - `honba-docs` → `tantra-docs` (`honba_docs` → `tantra_docs`)
- **Python Imports & Namespaces**:
  - `import honba` → `import tantra`
  - `from honba.` → `from tantra.`
- **Organization & Branding**:
  - `honba-labs` → `tantra-labs`
  - "Honba" → "Tantra" (preserving contextual historical design origins where appropriate)

### Phase 4: MkDocs Configuration & Navigation Restructuring
1. Rewrite `mkdocs.yml`:
   - Set `site_name: Tantra Labs Documentation`
   - Set `site_url: https://docs.tantra-labs.io`
   - Configure Material theme palette (slate / indigo), copy buttons, section indexes.
   - Configure markdown extensions (`pymdownx.superfences`, `pymdownx.highlight`, `admonition`, `tables`, `footnotes`, `attr_list`, `toc`).
2. Construct comprehensive navigation tree incorporating:
   - Home (`index.md`)
   - Architecture & Design (including `design/architecture.md`, crate hierarchy, message flow, DDD patterns)
   - Getting Started (installation, first backtest, loading data)
   - Indian Markets (brokers, adapters, options, mutual funds, universes, cost model, calendar)
   - Strategies (writing strategies, indicators, styles, portfolio construction, chaining)
   - Backtesting (three-tier pipeline, cost & latency modeling, statistical validation, avoiding biases)
   - AI & Quant Research (research loop, RL training, MCP gateway, NL verification)
   - Tutorials (NIFTY50, BankNIFTY options, SIP, Alpha30 factor model, autoresearch)
   - Examples & Case Studies
   - API Reference
   - Contributing (setup, adding adapters, adding indicators, dependency rules)
   - Conformance Matrix & Roadmap (`conformance_matrix.md`, `roadmap/roadmap.md`, `migration-guide.md`)

### Phase 5: Link Sanitization & Strict Build Verification
1. Fix relative link anomalies (e.g. `../architecture/` links in root `conformance_matrix.md`, and broken links to `conformance_matrix.md` in `architecture/*.md`).
2. Remove stale dead external links (e.g. dead GitHub Pages mdBook external links).
3. Validate and execute strict build:
   ```bash
   mkdocs build --strict
   ```
   Ensure build finishes with 0 errors and 0 warnings.

---

## 3. Strict Verification Commands
```bash
# Run from the repository root
source .venv/bin/activate
mkdocs build --strict
```
