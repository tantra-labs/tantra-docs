# Dependency Rules

The crate hierarchy is enforced by `scripts/dependency_graph.py`. Every
Rust crate in the workspace declares its `tantra-*` dependencies in its
`Cargo.toml`, and the script verifies those dependencies match the
allowed table.

A pull request that violates the hierarchy fails CI. This is
intentional. The hierarchy is what keeps the codebase maintainable as
it grows.

## The Allowed Table

| Crate | May depend on |
|---|---|
| `tantra-marketssages` | *(nothing)* |
| `tantra-core` | `tantra-marketssages` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-strategies` | `tantra-strategies` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-strategies` | `tantra-strategies`, `tantra-strategies` |
| `tantra-strategies` | `tantra-marketssages`, `tantra-core` |
| `tantra-data` | `tantra-marketssages`, `tantra-core` |
| `tantra-data` | `tantra-marketssages`, `tantra-core` |
| `tantra-market` | `tantra-core` |

Non-`tantra-*` dependencies (serde, tokio, arrow, etc.) are not
restricted by the rule. They are audited separately by `cargo deny`.

## Why Each Rule Exists

### `tantra-marketssages` depends on nothing

Messages are the vocabulary of the engine. If `tantra-marketssages` depended
on `tantra-core`, the two crates would be coupled and neither could
be tested in isolation. Messages must be self-contained types.

### `tantra-core` depends only on `tantra-marketssages`

Entities are domain models. They use message types (a `Bar` might be
referenced by an `Instrument`), but they do not know how to be traded.
A `Position` does not know how to place an order.

### `tantra-strategies` depends on messages and entities

The engine operates on messages and tracks entities. It defines the
connector traits that adapters implement. It does not depend on any
specific strategy or indicator.

### `tantra-strategies` depends only on `tantra-strategies`

Strategies use the engine API. They do not import indicators (those
are separate) or testing infrastructure (that is higher).

### `tantra-strategies` depends on messages and entities

Indicators consume bars (messages) and can be attached to instruments
(entities). They do not need the engine.

### `tantra-strategies` depends on the engine and strategies

The backtester runs strategies in the engine. It is at the top of the
Rust hierarchy.

### `tantra-strategies` depends on messages and entities

Analytics operate on backtest results, which are messages and entities.
They do not need the engine.

### `tantra-data` and `tantra-data` depend on messages and entities

Data I/O produces and consumes messages and entities. It has no need
for the engine.

### `tantra-market` depends only on `tantra-core`

This is the most important restriction. `tantra-market` is the
market specialization module. It should be testable without
spinning up an engine. The market calendars, cost models, and universe
definitions are all pure data transformations that take a date and
return a value.

Adding `tantra-strategies` as a dependency of `tantra-market` would mean the
calendar cannot be tested without an event loop. This is exactly the
kind of coupling the hierarchy is designed to prevent.

## When You Need a Forbidden Dependency

If a piece of code in `tantra-market` needs something from `tantra-strategies`,
you have four options, in order of preference:

### 1. Move the code to the lower crate

The most common case. If `tantra-market` needs to know about a
`Price` type from `tantra-strategies`, the `Price` type probably belongs in
`tantra-marketssages`, not `tantra-strategies`.

### 2. Introduce a trait in the lower crate

If `tantra-market` needs to call a function from `tantra-strategies`, define a
trait in `tantra-market` and implement it in `tantra-strategies`. This inverts
the dependency.

    // In tantra-market
    pub trait Clock {
        fn now(&self) -> UnixNanos;
    }

    // In tantra-strategies
    impl Clock for EngineClock {
        fn now(&self) -> UnixNanos { ... }
    }

### 3. Duplicate the small bit of code

If it is genuinely small — a five-line helper — duplicating it in the
lower crate is sometimes cheaper than restructuring. This is a last
resort, and the duplication must be noted in a comment.

### 4. Discuss in an issue

If none of the above work, open an issue. The response may be that the
hierarchy needs to change, which is a bigger decision than a single
pull request should make.

## What the Script Checks

`scripts/dependency_graph.py` reads each crate's `Cargo.toml` and
extracts the `tantra-*` dependencies. For each crate, it compares the
actual dependencies against the allowed set.

    # From the script
    ALLOWED = {
        "tantra-marketssages": set(),
        "tantra-core": {"tantra-marketssages"},
        "tantra-strategies": {"tantra-marketssages", "tantra-core"},
        "tantra-strategies": {"tantra-strategies"},
        "tantra-strategies": {"tantra-marketssages", "tantra-core"},
        "tantra-strategies": {"tantra-strategies", "tantra-strategies"},
        "tantra-strategies": {"tantra-marketssages", "tantra-core"},
        "tantra-data": {"tantra-marketssages", "tantra-core"},
        "tantra-data": {"tantra-marketssages", "tantra-core"},
        "tantra-market": {"tantra-core"},
    }

Running it locally:

    python3 scripts/dependency_graph.py
    # → Dependency hierarchy OK.

If a crate violates the hierarchy:

    python3 scripts/dependency_graph.py
    # VIOLATION: tantra-market illegally depends on ['tantra-strategies']
    #
    # 1 violation(s) found.

The error message is precise. It names the crate and the offending
dependency.

## Dev Dependencies

Dev dependencies (under `[dev-dependencies]` in `Cargo.toml`) are
**not** checked by the hierarchy script. This is deliberate: tests
often need to set up scenarios that cross layers. For example, testing
`tantra-market` might use `tantra-strategies` to build a small fixture
engine.

The rule is: a **runtime** dependency must follow the hierarchy. A
**test-only** dependency may not.

This means the following is legal:

    # tantra-market/Cargo.toml
    [dependencies]
    tantra-core = { workspace = true }

    [dev-dependencies]
    tantra-strategies = { workspace = true }   # only for tests

But this is not:

    # tantra-market/Cargo.toml
    [dependencies]
    tantra-core = { workspace = true }
    tantra-strategies = { workspace = true }            # runtime violation

## Feature Flags

Feature flags are checked the same way as regular dependencies. A
crate that adds an optional dependency on a forbidden crate must be
modified or the feature moved.

## The Python Layer

The dependency hierarchy applies to Rust crates. The Python control
plane in `python/tantra/` has a looser structure: it can import from
any crate that has been exposed via PyO3. However, the same principle
applies — the Python `core` module should not import from
`python.tantra.ai`, and so on.

This is enforced by convention, not by a script. If it becomes a
problem, a Python-side version of `dependency_graph.py` can be added.

## Removing a Dependency

Removing a dependency is always allowed. If you find that a crate no
longer needs a `tantra-*` dependency it has, remove it from
`Cargo.toml`. The script will pass either way, but removing unused
dependencies reduces build time and clarifies intent.

## Updating the Rule Table

If you genuinely need to add a new edge to the hierarchy — for
example, because `tantra-market` needs to depend on `tantra-strategies` for a
new feature — you must:

1. Justify the change in an issue or pull request description.
2. Update `scripts/dependency_graph.py` with the new edge.
3. Update `docs/architecture/crate_hierarchy.md` with the new edge.
4. Update this document if the reasoning changes.

The rule table is not a bureaucratic constraint. It is a description
of the intended architecture. If the intended architecture changes,
the table changes with it, in the same pull request.
