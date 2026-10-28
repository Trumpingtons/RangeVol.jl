# RangeVol.jl

Classical range-based and close-to-close volatility estimators for Julia.

All scalar estimators accept vectors of daily prices and return **daily volatility as a decimal** by default (e.g. `0.0126` = 1.26% per day). Pass `trading_periods` to annualise. The Alizadeh-Brandt-Diebold function is the exception — it returns a vector of per-period log-ranges, which is a proxy for log-volatility rather than a direct variance estimate.

## Estimators

| Function | Inputs | Reference |
|---|---|---|
| `close_to_close` | Close | Merton (1980) |
| `parkinson` | High, Low | Parkinson (1980) |
| `garman_klass` | Open, High, Low, Close | Garman & Klass (1980) |
| `rogers_satchell` | Open, High, Low, Close | Rogers & Satchell (1991) |
| `garman_klass_yang_zhang` | Open, High, Low, Close | Yang & Zhang (2000) |
| `yang_zhang` | Open, High, Low, Close | Yang & Zhang (2000) |
| `alizadeh_brandt_diebold` | High, Low | Alizadeh, Brandt & Diebold (2002) |

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/antseabra/RangeVol.jl")
```

## Quick start

```julia
using RangeVol

# Daily OHLC vectors
open  = [100.0, 101.2, 99.8, 102.3, 101.5]
high  = [103.1, 104.0, 102.5, 105.2, 103.8]
low   = [ 98.5,  99.3,  97.8, 100.1,  98.9]
close = [101.2,  99.8, 102.3, 101.5, 100.7]

# Daily volatility
close_to_close(close)                           # 0.01755297716383068
parkinson(high, low)                            # 0.02846549234018087
garman_klass(open, high, low, close)            # 0.03225544049108485
rogers_satchell(open, high, low, close)         # 0.03349585911206595
garman_klass_yang_zhang(open, high, low, close) # 0.03246305126479791
yang_zhang(open, high, low, close)              # 0.03259109267183659

# Annualised (trading_periods=252):
close_to_close(close; trading_periods=252)      # 0.27864487406575100
parkinson(high, low; trading_periods=252)       # 0.45187568207479560

# Log-range proxy (returns a vector, not a scalar)
alizadeh_brandt_diebold(high, low)
# [0.04564284, 0.04624533, 0.04693822, 0.04969361, 0.04835673]
```

All scalar estimators accept an optional `trading_periods` keyword. The daily variance estimate is multiplied by `trading_periods` before taking the square root:

```
σ_annual = sqrt(σ²_daily × trading_periods)
```

Setting `trading_periods=1` returns **daily volatility**, which is convention-independent:

```
σ_daily = sqrt(σ²_daily × 1)
```

Common values:

| Output | `trading_periods` |
|---|---|
| Daily volatility (default) | 1 |
| Annualised — equities (US) | 252 |
| Annualised — FX | 260 |
| Annualised — crypto | 365 |

```julia
parkinson(high, low)                      # daily volatility (default)
parkinson(high, low; trading_periods=252) # annualised, equities
parkinson(high, low; trading_periods=260) # annualised, FX
parkinson(high, low; trading_periods=365) # annualised, crypto
```

## Cross-validation against R / TTR

The test suite cross-validates every estimator against the [TTR](https://cran.r-project.org/package=TTR) package in R using AAPL stock prices (2023), EUR/USD exchange rates (2023), and simulated GBM data (n=500, σ=20%). Results agree to machine precision (~1e-15).

### Annualised volatility — RangeVol vs TTR (full-series estimates)

#### Simulated GBM (n = 500, σ = 20%)

| Estimator | RangeVol | TTR |
|---|---|---|
| `close_to_close` | 0.1942 | 0.1942 |
| `parkinson` | 0.3442 | 0.3442 |
| `garman_klass` | 0.3829 | 0.3829 |
| `rogers_satchell` | 0.3761 | 0.3761 |
| `garman_klass_yang_zhang` | 0.3949 | 0.3949 |
| `yang_zhang` | 0.3700 | 0.3700 |

#### AAPL (2023, n = 250)

| Estimator | RangeVol | TTR |
|---|---|---|
| `close_to_close` | 0.1992 | 0.1992 |
| `parkinson` | 0.1781 | 0.1781 |
| `garman_klass` | 0.1789 | 0.1789 |
| `rogers_satchell` | 0.1797 | 0.1797 |
| `garman_klass_yang_zhang` | 0.2133 | 0.2133 |
| `yang_zhang` | 0.2134 | 0.2134 |

#### EUR/USD (2023, n = 260)

| Estimator | RangeVol | TTR |
|---|---|---|
| `close_to_close` | 0.0753 | 0.0753 |
| `parkinson` | 0.0657 | 0.0657 |
| `garman_klass` | 0.0774 | 0.0774 |
| `rogers_satchell` | 0.0925 | 0.0925 |
| `garman_klass_yang_zhang` | 0.1079 | 0.1079 |
| `yang_zhang` | 0.1140 | 0.1140 |

To regenerate the reference data:

```bash
Rscript test/generate_data.R       # requires R with TTR and quantmod
julia --project=test test/generate_results.jl
julia --project=test test/runtests.jl
```

## Vignette

[RangeVol: volatility from the day's high and low](vignette/RangeVol.pdf)

## References

- Merton, R. C. (1980). On estimating the expected return on the market. *Journal of Financial Economics*, 8(4), 323–361.
- Parkinson, M. (1980). The extreme value method for estimating the variance of the rate of return. *Journal of Business*, 53(1), 61–65.
- Garman, M. B., & Klass, M. J. (1980). On the estimation of security price volatilities from historical data. *Journal of Business*, 53(1), 67–78.
- Rogers, L. C. G., & Satchell, S. E. (1991). Estimating variance from high, low and closing prices. *Annals of Applied Probability*, 1(4), 504–512.
- Yang, D., & Zhang, Q. (2000). Drift-independent volatility estimation based on high, low, open, and close prices. *Journal of Business*, 73(3), 477–491.
- Alizadeh, S., Brandt, M. W., & Diebold, F. X. (2002). Range-based estimation of stochastic volatility models. *Journal of Finance*, 57(3), 1047–1091.

## License

MIT — see [LICENSE](LICENSE).
