# `vyapaar-docs` — Subagent Migration & DDD Refactoring Guide

> **Tier**: Tier 6E
> **Source**: `/home/pmallapp/Devel/Finance/honba-workspace/honba-docs`
> **Target**: `/home/pmallapp/Devel/Finance/vyapaar-labs/vyapaar-docs`

---

## 1. Migration & Refactoring Steps
1. Copy `honba-workspace/honba-docs/docs/*` into `vyapaar-labs/vyapaar-docs/docs/`.
2. **Do NOT copy `honba-docs/book/`** (eliminates the duplicate mdBook tree; fold any unique mdBook pages from `book/src/` into `docs/architecture/`).
3. Update subsystem terminology across all markdown pages:
   - `honba-core` → `vyapaar-core`
   - `honba-kokoro` → `vyapaar-ledger`
   - `honba-mon` → `vyapaar-risk`
   - `honba-me` → `vyapaar-market`
   - `honba-te` → `vyapaar-exec`
   - `honba-ya` → `vyapaar-runtime`
   - `honba-nou` → `vyapaar-agent`
   - `honba-tamashii` → `vyapaar-ffi`
   - `honba-kao` → `vyapaar-ui`
   - `honba-fe` → `vyapaar-fe`
   - `honba-{data,adapters,strategies,examples}` → `vyapaar-{data,adapters,strategies,examples}`
4. Update `mkdocs.yml` navigation and theme configuration.

## 2. Verification Commands
```bash
cd /home/pmallapp/Devel/Finance/vyapaar-labs/vyapaar-docs
mkdocs build --strict
```
