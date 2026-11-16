# Installation

Tantra is a **superproject** of Git submodules: the Rust engine crates
(`tantra-core`, `tantra-ledger`, `tantra-risk`, `tantra-market`,
`tantra-exec`, `tantra-runtime`, `tantra-agent`, `tantra-ffi`, `tantra-ui`)
plus Python packages (`tantra-strategies`, `tantra-adapters`, `tantra-data`,
`tantra-examples`, `tantra-docs`). This guide installs the whole workspace
with one shared Python venv and the canonical `prod` build profile.

You need **Rust** (to build the engines and the `tantra` CLI) and **Python
3.11+** (the workspace standard; the `tantra` wheel supports 3.10+). Node.js
is **not** required — the web UI is optional (see
[the user-guide note](../user-guide/index.md)).

## 1. Prerequisites

### Rust

Install via [rustup](https://rustup.rs), then add the components:

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    rustup component add rustfmt clippy

The workspace pins `rust-version = "1.85"`, so any stable toolchain from
1.85 on works. The Rust build needs a C linker (`gcc`/`clang`).

### Python

Python 3.11 or later. We recommend [`uv`](https://github.com/astral-sh/uv),
or a plain `venv` (the workspace creates one for you — see step 4):

    curl -LsSf https://astral.sh/uv/install.sh | sh

### System packages

On Debian/Ubuntu:

    sudo apt install build-essential pkg-config libssl-dev

On macOS with Homebrew:

    brew install pkg-config openssl

## 2. Clone the Superproject

    git clone --recurse-submodules https://github.com/tantra-labs/tantra-labs.git
    cd tantra-labs

`--recurse-submodules` pulls every subsystem repo at its pinned commit.
(Already cloned without submodules? `git submodule update --init --recursive`.)

## 3. Build the Rust Workspaces (prod profile)

The **only** canonical profile is `prod` (`target/prod`). Bare `cargo build`
and `cargo build --release` are deliberately off-profile — use the Makefile
so every crate builds consistently:

    make prod

The first build downloads Arrow, Parquet, Tokio, and their dependencies;
expect several minutes on a modern machine. This also builds the `tantra`
CLI binary at `tantra-ui/target/prod/tantra` — add it to your `PATH`:

    export PATH="$PWD/tantra-ui/target/prod:$PATH"
    tantra --help

## 4. Build the Python Environment

`make prepare` creates **one** workspace venv at the repo root (`.venv`),
symlinks it into every Python sub-repo, builds the `tantra` wheel with
maturin, and installs `tantra-adapters`, `tantra-data`, `tantra-strategies`,
and `tantra-examples` editable into it:

    make prepare

Then activate it:

    source .venv/bin/activate
    python -c "import tantra; print(tantra.__version__)"

## 5. Install Broker Adapters

Adapters ship in the single `tantra-adapters` package (already installed by
`make prepare`): one module per broker, all seven brokers (Dhan, Zerodha,
Angel One, Upstox, Fyers, Kotak, IIFL). Dhan and Zerodha are the
contract-certified ones. The deterministic `PaperBroker` needs no credentials
and no network — you never need live broker credentials for offline tests.
See [Adapters Package](../api/adapters-package.md) and
[Adapter Configuration](../india/adapter_configuration.md).

## 6. Configuration

Copy the example environment file:

    cp .env.example .env

Minimal `.env` for backtesting / paper trading only — leave broker
credentials blank, no live broker required:

    # Leave blank — no broker credentials required for backtests or paper
    DHAN_CLIENT_ID=
    DHAN_ACCESS_TOKEN=
    DHAN_MODE=paper          # build adapters in paper mode (default is live)

For the AI agent, point at an OpenAI-compatible endpoint (local or cloud) or
a local GGUF model:

    # OpenAI-compatible endpoint (Ollama / OmniRoute / any /v1 endpoint)
    TANTRA_LLM_BASE_URL=http://localhost:11434/v1
    TANTRA_LLM_MODEL=your-model
    TANTRA_LLM_API_KEY=       # only if the endpoint requires one

    # ...or a local GGUF model file
    # TANTRA_GGUF_PATH=/path/to/model.gguf

## 7. Verify the Whole Stack

    # Rust: every workspace in the prod profile
    make test

    # Python: wheel + adapters + strategies + examples
    make prepare   # once, after the Rust build (idempotent)

    # CLI sanity
    tantra --help
    tantra doctor          # environment diagnostics (--fix repairs what it can)

    # A minimal backtest end-to-end (synthetic data, offline)
    python tantra-examples/examples/backtesting/01_first_backtest.py --synthetic

    # A deterministic paper session (offline, no credentials)
    tantra paper --seed 42

If all four run, you are ready: read
[Your First Backtest](first-backtest.md), then the
[User Guide](../user-guide/index.md).

## Common Issues

**`E0034: multiple applicable items in scope` from `arrow-arith`**

A chrono/arrow version conflict. Pin chrono below 0.4.40 in the workspace
`Cargo.toml`:

    chrono = { version = ">=0.4.20, <0.4.40", features = ["serde"] }

Then:

    cargo update -p chrono --precise 0.4.39

**`E0583: file not found for module`**

The crate's `lib.rs` declares a module that has no file on disk. Create a
stub for it:

    touch crates/<crate>/src/<module>.rs

**`maturin` fails to find Python headers**

Install the development headers for your Python version. On Debian/Ubuntu:

    sudo apt install python3-dev

**`cargo test --workspace` OOMs under prod LTO in `tantra-ui`**

The `tantra-ui` facade has no tests of its own; run its suites per crate
(`cargo test --workspace --exclude tantra-ui` from that repo) or via the
per-crate `make test` targets.

**`tantra: command not found`**

The `tantra` binary is native and lives at `tantra-ui/target/prod/tantra`
(step 3). The Python `python -m tantra.cli` is a separate, smaller command.
Run `tantra --help` after adding the binary's directory to `PATH`.
