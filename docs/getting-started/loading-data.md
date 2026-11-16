# Loading Data

Backtests and `tantra serve` both need bars. Which source you use depends on
what you are doing:

| Need | Source | Where |
|:-----|:-------|:------|
| A reproducible first run, no downloads | **Synthetic bars** (`tantra_examples.synthetic`) | this page |
| A point-in-time research catalog | **Lakehouse** (`tantra-data`: DuckDB + Parquet, bhavcopy, corporate actions, coverage ledgers) | below |
| A headless data API over Parquet | **Bar files** (`SYMBOL.EXCHANGE.parquet`) fed to `tantra serve` | below |

## Synthetic Bars (first runs and tests)

The examples package ships deterministic bar generators — identical on every
machine, so first runs and tutorials are reproducible:

```python
from tantra_examples.synthetic import trending_bars, oscillating_bars

bars = trending_bars("RELIANCE", 120)      # ramp from ₹2500
bars = oscillating_bars("RELIANCE", 120)   # mean-reverting series
```

`trending_bars(symbol, n)` / `oscillating_bars(symbol, n)` return
`tantra.bar.Bar` objects with weekday timestamps. These are the bars used by
[Your First Backtest](first-backtest.md).

## Lakehouse (`tantra-data`)

`tantra-data` is the point-in-time lakehouse: NSE bhavcopy ingestion,
corporate actions (splits, bonuses, dividends, rights), point-in-time
fundamentals, coverage ledgers, and a Hive-partitioned Parquet catalog with
`DECIMAL128(18,4)` pricing (zero floats). Installed editable by
`make prepare`:

```bash
source .venv/bin/activate
python -c "import tantra_data; print(tantra_data.__version__)"
```

Its CLI handles catalog provisioning and bhavcopy ingestion (see the
`tantra-data` repo and [Indian Markets → Universes](../india/universes.md)
for how universes and as-of queries work).

## Bar Files for `tantra serve`

The headless API server reads a directory of Parquet bar files, one per
instrument, named `SYMBOL.EXCHANGE.parquet`:

```text
bars/
├── RELIANCE.NSE.parquet
├── INFY.NSE.parquet
└── NIFTY50.NSE.parquet
```

Boot the server over that directory:

```bash
tantra serve --data-dir ./bars
# listening on http://127.0.0.1:8000
```

Then query bars, quotes, screener scans, and backtests over HTTP — see
[REST API Workflows](../user-guide/rest-api.md).

## Symbol Forms

| Form | Where | Example |
|------|-------|---------|
| Input: bare symbol | Python `InstrumentId` | `InstrumentId("INFY", "NSE")` |
| Input: qualified `EXCHANGE:SYMBOL` | Python order APIs, CLI flags | `NSE:INFY`, `NSE:NIFTY50-INDEX` |
| Display / REST path | REST routes, output ids | `INFY.NSE` |

The Python SDK normalizes these for you: `tantra.instrument_id(...)` accepts
either form and returns a canonical `InstrumentId`; compiled
`OrderRequest`s and the paper exchange take `EXCHANGE:SYMBOL` strings
directly.

## Arrow / Polars Bridges

The wheel converts bars and ticks to Arrow and Polars zero-copy:

```python
from tantra.data import bars_to_arrow, bars_to_polars
arrow_table = bars_to_arrow(bars)        # pyarrow.Table
frame = bars_to_polars(bars)             # polars.DataFrame
```
