# `tantra-docs` — Documentation Architecture & Conformance Matrix

## 1. Bounded Context & Responsibility
`tantra-docs` (Tier 6E, ported from `tantra-docs`) is the **Single Source of Truth Technical Documentation** built with MkDocs Material (`mkdocs build --strict`).

## 2. Platform-Wide DDD Architecture (New Design)
The Tantra platform follows a strict **Domain-Driven Design** with 15 strictly bounded repositories organized across 6 architectural layers (L0–L6). The authoritative topological reference is:

* **[Architecture Layers & Bounded Context Topology](../architecture/architecture_layers.md)** — Full layer table (L0 Shared Kernel through L6 Python Ecosystem), dependency direction diagram, and tactical DDD invariants (Zero-I/O purity, Zero-Floats policy, self-validating value objects, rich aggregates, ACL boundaries, parallel test directory rule).
* **[DDD Conflicts & Resolutions](../architecture/ddd_conflicts_resolutions.md)** — Bounded-context conflicts identified during the `honba` → `tantra` migration and their resolutions, including the migration checklist and remaining ambiguities.

## 3. Key Structural Improvements Over `tantra-docs`
* **Single Unified Doc System**: Eliminates the split-brain `docs/` (MkDocs) vs `book/` (mdBook) duplication found in `tantra-docs`. All documentation is consolidated under `docs/` rendered by `mkdocs.yml`.
* **Code-Verified API Naming**: Uses exact exported names (`tantra`, `Sma`, `Ema`, `Rsi`, `Atr`, `Strategy`, `Price`, `Quantity`, `Money`).
* **Implementation Conformance Matrix**: Includes `docs/conformance_matrix.md` tracking `[STATUS: IMPLEMENTED | IN-PROGRESS | SCAFFOLD]` across all 15 repositories.
