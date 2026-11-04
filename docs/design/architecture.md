# `vyapaar-docs` — Documentation Architecture & Conformance Matrix

## 1. Bounded Context & Responsibility
`vyapaar-docs` (Tier 6E, ported from `honba-docs`) is the **Single Source of Truth Technical Documentation** built with MkDocs Material (`mkdocs build --strict`).

## 2. Key Structural Improvements Over `honba-docs`
* **Single Unified Doc System**: Eliminates the split-brain `docs/` (MkDocs) vs `book/` (mdBook) duplication found in `honba-docs`. All documentation is consolidated under `docs/` rendered by `mkdocs.yml`.
* **Code-Verified API Naming**: Uses exact exported names (`vyapaar`, `Sma`, `Ema`, `Rsi`, `Atr`, `Strategy`, `Price`, `Quantity`, `Money`).
* **Implementation Conformance Matrix**: Includes `docs/conformance_matrix.md` tracking `[STATUS: IMPLEMENTED | IN-PROGRESS | SCAFFOLD]` across all 15 repositories.
