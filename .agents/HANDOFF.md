# `tantra-docs` — Inter-Agent Handoff

## Phase / Slice Status
* **T14.16 (docs, 2026-11-16) — headless user guide + installation rewrite
  COMPLETE** (`docs/plans/0005` → Implemented): new `docs/user-guide/` —
  `index.md` (four headless surfaces, web-UI-not-ready banner, decision
  table), `cli.md` (full `tantra` command reference organized by job, grounded
  in `tantra-ui` `tantra-cli` `args.rs`), `rest-api.md` (`tantra serve` + curl
  workflows, envelope, `/ws/live`; full wire reference stays `api/rest.md`),
  `python.md` (strategy authoring, `Tantra.backtest(...).run()`, wheel CLI,
  data sources, zero-floats), `ai.md` (LLM backends `TANTRA_GGUF_PATH` /
  `TANTRA_LLM_BASE_URL`, `ask`/`chat`/`tools`/`mcp config`/`jobs`).
  Rewrote `docs/getting-started/installation.md` (real superproject:
  `git clone --recurse-submodules`, `make prepare` single venv + wheel,
  `make prod` prod-profile build, `tantra` binary at
  `tantra-ui/target/prod/tantra`, rust-version 1.85), `first-backtest.md`
  (real `Tantra.backtest` API on synthetic `trending_bars`; the old page
  taught a non-existent `Strategy.backtest(...)` / `result.print_report()`),
  `loading-data.md` (synthetic / lakehouse `tantra-data` / Parquet
  `SYMBOL.EXCHANGE.parquet` for `tantra serve`; removed the non-existent
  `tantra data load`). Paper trading cross-linked to `docs/paper-trading/`
  (plan 0004, not duplicated). Nav (User Guide section) + home +
  getting-started indexes wired; `mkdocs build --strict` green.
* **T14.15 (docs, 2026-11-16) — paper-trading user guide COMPLETE**
  (`docs/plans/0004` → Implemented): new `docs/paper-trading/` section —
  `index.md` (one engine / four embeddings, determinism + zero-floats notes),
  `python.md` (seeded `PaperSession` round trip; faithful excerpt of
  `tantra-examples/examples/basic/06_paper_trading.py`, covered by its 6-test
  suite incl. two-runs-identical), `cli.md` (`tantra paper --mode embedded`
  golden demo: sell VWAP `100.6667`, net 0, cash `1_000_000`; `--mode server`
  → `paper serve`), `rest-ws.md` (`paper serve --tape` / `--mis-square-off`,
  `/orders` + `/positions/close` + `/positions` + `/portfolio` + `/ws/live`,
  fill fields, exact JSON cited to `docs/api/rest.md` + runtime plan `0005`),
  `web.md` (`PaperPanel` embedded vs server; TUI `/positions`). Nav + home
  index wired; `mkdocs build --strict` green.
* **T11 track COMPLETE (2026-11-15) — docs plans 0001 + 0003 Implemented**:
  - **T11.1 — MCP gateway & 15-engine reference**: `docs/ai/mcp_gateway.md` overhauled
    into the complete 22-tool gateway reference (stdio + SSE/HTTP transports, Two-Tier
    Gateway Discovery `tantra_search_tools`/`tantra_describe_tool`/`tantra_read_result`,
    universal `tantra/result/v1` envelope, `_jq` filter, no `tantra_call_tool`); 16 pages
    under `docs/ai/toolsets/` (index + all 15 engines: market, technicals, scanner,
    analytics, validation, allocation, risk, regimes, volatility, ledger, calc, research,
    backtest, forecast, derivatives) with exact shipped tool schemas + honest stub notes
    (data gaps 0017/0018/0020–0022, market 0006); 4 client guides
    `docs/ai/clients/{claude_code,cursor,vs_code,gemini}.md`; `docs/ai/result_protocol.md`;
    `docs/ai/personas.md` (9 personas); `docs/getting-started/mcp.md`; `docs/llms.txt`;
    nav + `ai/index.md` + `getting-started/index.md` wired.
  - **T11.2 — EE+ strategy user guide**: `docs/strategies/elephant-edge/` — index,
    overview, level-map, signals, stops-positioning, studio. Grounded in the research
    basis + shipped SDK (gap 0006) with honest status banners: strategy engine / Studio /
    `level_map`+`oi_walls` chat tools documented as **planned** citing strategies plan
    0001, ui plan 0006, agent plan 0011. Code snippets use only shipped tested SDK models
    (`tantra_strategies.sdk.{levels,stop_protection,order}`).
  - Plan docs `docs/plans/0001` + `0003` removed (moved to Implemented in the index per
    gap-tracking §4); workspace task list T11 rows closed.
- **T12.10 (docs, 2026-11-15)** — EE+ guide completed with `docs/strategies/elephant-edge/reference.md` (parameter reference, declarative configuration + `config.toml` example, worked session walk-through; snippets use only shipped gap-0006 SDK models; cross-repo deps T12.4 engine / T12.8 chat tools / T12.9 Studio stay planned — the guide's "planned" banners remain until those land). Nav + index + cross-links wired; `mkdocs build --strict` green.
* **Adapters docs sync (COMPLETE, 2026-11-12)**: rewrote the site's adapter
  story against the actual `tantra-adapters` source (single package, 7 broker
  modules, REST-only, Decimal-only). The old pages described a **non-existent**
  per-broker-package architecture (`tantra-dhan`/`tantra-zerodha`
  distributions, `AdapterCapabilities`/`WireMap`/`routes.toml` contract suite,
  `from_env`/`<PREFIX>MODE`/`TANTRA_CACHE_DIR`, async facade, float prices) —
  none of it exists; corrected everywhere it appeared:
  - New page `docs/api/adapters-package.md` (detailed `tantra-adapters`
    reference: quickstart, canonical models, zero-floats parse, protocols/
    transports, per-broker wire-mapping table, paper/replay harness, registry,
    config/TOML, testing pattern, limitations table with gap links) — nav
    registered under API Reference.
  - Rewrote `docs/india/adapter_configuration.md` (constructor injection,
    `AdapterConfig`/`BrokerCredentials`, 3-of-7 TOML templates + pending loader
    gap 0007, paper harness, credentials guidance).
  - Rewrote `docs/contributing/adding_adapters.md` (module-in-one-package
    pattern, `as_decimal`/no-float rule, `MockTransport` contract tests,
    entry-point + `BROKER_ADAPTERS` sync invariant); the old version even
    taught `float` prices, violating the workspace zero-floats invariant.
  - Fixed `docs/india/brokers.md` (status table: all 7 implemented, 2
    certified; real Dhan/Zerodha module sections; auth/order-update/config/
    paper/rate-limit/adding sections re-grounded; broker API facts kept).
  - `docs/api/adapters.md` now carries a "Not yet implemented in the `tantra`
    SDK" banner: the documented `tantra.adapters` registry is planned-only
    (verified absent from `tantra-ffi/python/tantra`); shipped layer = the
    `tantra-adapters` package.
  - `docs/conformance_matrix.md` adapter row corrected (single-package
    description + real test paths, replacing the bogus `tantra-exec-*` test
    citations); `architecture/adapter_interface.md` §5 table fixed (source dir
    `tantra-adapters/tantra_adapters/*.py`, 7 brokers, sync REST);
    `architecture/index.md` + `api/python/index.md` rows updated;
    `getting-started/installation.md` + `contributing/development_setup.md`
    adapter install/testing sections rewritten.
* Gate: `mkdocs build --strict` **PASS** (0 warnings; only the known
  informational `docs/plans/README.md`-outside-nav warning).
* Runtime docs pass (2026-11-12, earlier same day) — see the folded summary
  below.

## Decisions & Discoveries
* `tantra-docs` `.venv` holds mkdocs-material; run
  `.venv/bin/mkdocs build --strict` (system `mkdocs` lacks the material theme).
* Two pages live outside `nav` (`docs/plans/*`) — informational warning only,
  not a build failure.
* Cross-directory links use `../` prefixes; keep that style for new pages.
* Heading anchors strip backticks/dots (`### 3.2 Headless Authentication
  (`tantra-exec-auth`)` → `#32-headless-authentication-tantra-exec-auth`);
  deep-link to the post-slugify form or the strict build flags it.
* **MCP gateway truth (verified 2026-11-15)**: 22 tools (6 base, 13 `tantra_*`
  quant, 3 discovery). There is **no `tantra_call_tool`** — invocation is the
  standard MCP `tools/call` with the exact tool name. 15 engines (the old doc
  listed 13 — `forecast` and `derivatives` were missing).
* `tantra-adapters` wire truth (verified 2026-11-12): all 7 broker modules
  implemented + entry-pointed; contract tests only for dhan/zerodha;
  `zerodha.get_bars` is the only real OHLCV path; all 7 `cancel_order`
  fabricate zeroed Orders; no WebSocket/TOTP/TOML-loader; configs templates
  for dhan/zerodha/paper only. Gaps 0001–0007 still open; plan 0002 retired →
  plan 0003 (`0003-adapter-parity-streaming-realism.md`).
* Runtime REST route conflicts were resolved against `v1.rs`, not prose:
  `/quotes` (no id), `/market-data/symbol-profile/:id`,
  `/approval/queue|approve|reject`, and the 4 × 501 portfolio routes are the
  wire truth.
* Source of truth for capabilities: per-repo `docs/design/`, `docs/plans/`,
  `docs/gaps/`, and `HANDOFF.md` files; the runtime per-crate design docs
  (`tantra-runtime/docs/design/code-*.md`) now cover all 12 non-stub crates,
  and `tantra-adapters/docs/design/code-*.md` now covers every module
  (parse/config/codec/public-api added 2026-11-12).

## Immediate Next Step
* User-guide + installation track COMPLETE (T14.16, close-out). None
  outstanding in this repo. When a later phase changes the paper wire contract
  (fill fields / `/ws/live` event names), re-sync `docs/paper-trading/`
  (sources of truth: `docs/api/rest.md` + runtime plan `0005`). If the
  `tantra` CLI subcommand set changes (`tantra-ui` `tantra-cli` `args.rs`),
  re-sync `docs/user-guide/cli.md`. When the web UI becomes the stable daily
  driver, replace the "web UI not yet your daily driver" banner in
  `docs/user-guide/index.md`. When the EE+ upstream slices land (T12.4
  strategy engine, T12.9 Studio, T12.8 `level_map`/`oi_walls` chat tools —
  all tracked in their own repos), drop the "planned" banners on the
  `docs/strategies/elephant-edge/` pages. When the SDK-side `tantra.adapters`
  registry lands, re-sync `api/adapters.md`.

## Operating Invariants
* `mkdocs build --strict` must stay green; docs code snippets must match tested
  code in `tantra-examples` / `tantra-strategies` / adapter `tests/`.
* Keep `docs/conformance_matrix.md` in sync with sub-repo plan/gap indexes as
  new capabilities land.

---

## Folded: runtime docs pass (2026-11-12, earlier)

Synced the site with the actual `tantra-runtime` implementation (all facts
re-verified against crate source): new `architecture/runtime_overview.md`
(14-crate overview, four operational surfaces, parity pipeline, invariants) and
`architecture/runtime_chat.md` (`/ws/chat` chat agent runtime: env-gated LLM
backend — `TANTRA_GGUF_PATH` or `TANTRA_LLM_BASE_URL` — read-only tools +
`Profile.alerts` alert store, in-memory sessions). Rewrote `event_loop.md`
against `tantra-runtime-actors` (no `AuditPersistenceActor`; coalescing
default 100/50 ms; no CPU pinning; supervision tracked; `PositionSizingActor`,
`PythonStrategyActor` 50 ms timeout; SLOs 2 ms/1 ms/5 ms/15 µs). Rewrote
`runtime_jobs.md` (real `JobSpec` fields, 5-field Vixie cron, trait-only
`JobScheduler`, `FileJobRegistry` atomic tmp-rename, 6 budget dimensions,
fencing leases, 429/503 backpressure, journals live in the API layer). Fixed
`strategy_tester_and_enhancer.md` (real `BacktestConfig` sample; GA defaults;
TPE; DSR ≥ 3.0 robust / PBO < 0.5; caller-counted MC; Odysseus node kinds).
Fixed `api/rest.md` (four `/portfolio*` routes answer 501
`valuation_engine_mismatch`; added `/trades`, `/ws/chat`, streaming/SSE/chat
section; removed non-existent generic `/reports/{kind}`). Updated
`conformance_matrix.md` (chat runtime noted; `tantra-ledger-journal` row
PLANNED → IMPLEMENTED; counts 17 IMPLEMENTED / 1 IN-PROGRESS / 0 PLANNED).
Earlier passes (folded): Tier 6E docs migration; Fincept/Quantcept pages
(`docs/plans/0002`); DDD design docs; the 2026-10 major re-sync.
