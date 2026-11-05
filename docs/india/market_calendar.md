# Indian Market Calendar & Session Windows

The Indian market calendar operates with specialized market phases, pre-open auctions, special sessions (Muhurat trading), segment-specific closures, and settlement holidays that differ from exchange trading holidays.

`vyapaar-market` (and Python `vyapaar.markets.india.calendar`) models all Indian exchange dynamics with microsecond-level session validation.

*Authoritative calendar source: National Stock Exchange of India (NSE) & Bombay Stock Exchange (BSE).*

---

## 1. Trading Session Windows

Normal equity and F&O sessions on NSE and BSE adhere to the following sequence:

| Session | IST Window | Microstructure Notes |
| :--- | :--- | :--- |
| **Pre-open Call Auction** | 09:00 – 09:08 | Order entry, modification, and cancellation; no trade matching. |
| **Pre-open Matching** | 09:08 – 09:12 | Order matching and indicative equilibrium price discovery. |
| **Pre-open Buffer** | 09:12 – 09:15 | Transition buffer into regular trading. |
| **Normal Trading Session** | 09:15 – 15:30 | Continuous double-auction order book matching. |
| **Closing Price Discovery** | 15:30 – 15:40 | Weighted average calculation for official settlement close. |
| **Post-close Session** | 15:40 – 16:00 | Execution of market orders at the confirmed closing price. |

Strategies operating on the open must start evaluation at **09:15:00 IST**, discarding pre-open auction tick bursts unless explicitly modeled.

---

## 2. 2026 Exchange Trading Holidays

NSE and BSE observe **15 full trading holidays** for equities and derivatives in 2026:

| # | Date | Day | Occasion |
| :---: | :--- | :--- | :--- |
| 1 | 26 Jan 2026 | Monday | Republic Day |
| 2 | 03 Mar 2026 | Tuesday | Holi |
| 3 | 26 Mar 2026 | Thursday | Shri Ram Navami |
| 4 | 31 Mar 2026 | Tuesday | Shri Mahavir Jayanti |
| 5 | 03 Apr 2026 | Friday | Good Friday |
| 6 | 14 Apr 2026 | Tuesday | Dr. Baba Saheb Ambedkar Jayanti |
| 7 | 01 May 2026 | Friday | Maharashtra Day |
| 8 | 28 May 2026 | Thursday | Bakri Id |
| 9 | 26 Jun 2026 | Friday | Muharram |
| 10 | 14 Sep 2026 | Monday | Ganesh Chaturthi |
| 11 | 02 Oct 2026 | Friday | Mahatma Gandhi Jayanti |
| 12 | 20 Oct 2026 | Tuesday | Dussehra |
| 13 | 10 Nov 2026 | Tuesday | Diwali-Balipratipada |
| 14 | 24 Nov 2026 | Tuesday | Guru Nanak Jayanti |
| 15 | 25 Dec 2026 | Friday | Christmas |

---

## 3. Muhurat Trading & Settlement Holidays

### Muhurat Trading Session
Muhurat trading is a special one-hour auspicious trading session conducted during Diwali Laxmi Pujan (typically falling on a Sunday evening, e.g., 8 November 2026, 18:15–19:15 IST). `vyapaar-market` treats this as `Session::MuhuratTrading` with tailored risk limits.

### Settlement Holidays vs. Trading Holidays
Settlement holidays are dates when clearing corporations do not process fund or security transfers even if trading is open. On settlement holidays (e.g., Annual Bank Closing on 1 April), intraday positions function normally while T+1 funds settlement is postponed by one business day.

---

## 4. Rust Engine API (`vyapaar-market`)

```rust
use vyapaar_market::calendar::{MarketCalendar, NseCalendar, Session};
use chrono::{NaiveDate, DateTime, Utc};

let cal = NseCalendar::new(2026);

// Check if a given date is an open exchange day
let is_open = cal.is_trading_day(NaiveDate::from_ymd_opt(2026, 3, 3).unwrap());
assert!(!is_open); // False (Holi)

// Query next trading session (skips weekends and declared holidays)
let next_day = cal.next_trading_day(NaiveDate::from_ymd_opt(2026, 1, 23).unwrap());
// Skips Saturday, Sunday, and Republic Day (Monday 26 Jan) -> 2026-01-27
```

---

## 5. Python Strategy Integration

```python
from vyapaar.markets.india.calendar import NseTradingCalendar
from datetime import date

cal = NseTradingCalendar(year=2026)
if cal.is_trading_day(date(2026, 10, 2)):
    # Will not execute - Mahatma Gandhi Jayanti
    pass
```
