# API Reference

## `close_to_close`

```julia
close_to_close(close; trading_periods=252) -> Float64
```

Classical close-to-close historical volatility estimator (Merton, 1980).

Computes the sample standard deviation of daily log-returns `log(C_t / C_{t-1})` and annualises by `sqrt(trading_periods)`. This is the textbook baseline against which range-based estimators report their relative efficiency gains.

**Arguments**
- `close` — vector of daily closing prices (length ≥ 2)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 2

---

## `parkinson`

```julia
parkinson(high, low; trading_periods=252) -> Float64
```

Parkinson (1980) range-based volatility estimator.

Uses only the daily high-low range. Roughly **5.2×** more efficient than close-to-close when drift is negligible. Does not account for overnight gaps or non-zero drift.

**Arguments**
- `high`, `low` — vectors of daily high and low prices (same length, length ≥ 2)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 2

---

## `garman_klass`

```julia
garman_klass(open, high, low, close; trading_periods=252) -> Float64
```

Garman-Klass (1980) OHLC volatility estimator.

Extends Parkinson by incorporating the open-to-close log-return, achieving roughly **7.4×** the efficiency of close-to-close. Assumes zero drift and no overnight gaps between the close and the next open.

**Arguments**
- `open`, `high`, `low`, `close` — vectors of daily prices (same length, length ≥ 2)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 2

---

## `rogers_satchell`

```julia
rogers_satchell(open, high, low, close; trading_periods=252) -> Float64
```

Rogers-Satchell (1991) OHLC volatility estimator.

Drift-independent estimator that remains unbiased when the expected return is non-zero, achieving roughly **8×** the efficiency of close-to-close. Does not correct for overnight price gaps.

**Arguments**
- `open`, `high`, `low`, `close` — vectors of daily prices (same length, length ≥ 2)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 2

---

## `garman_klass_yang_zhang`

```julia
garman_klass_yang_zhang(open, high, low, close; trading_periods=252) -> Float64
```

Garman-Klass (1980) estimator extended by Yang and Zhang (2000) to account for overnight price gaps.

Prepends the squared overnight log-return `log(Open_t / Close_{t-1})^2` to the standard Garman-Klass intraday terms. Each observation requires the previous day's close, so the estimator uses n−1 consecutive pairs.

**Arguments**
- `open`, `high`, `low`, `close` — vectors of daily prices (same length, length ≥ 2)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 2

---

## `yang_zhang`

```julia
yang_zhang(open, high, low, close; trading_periods=252) -> Float64
```

Yang-Zhang (2000) minimum-variance volatility estimator.

The optimal linear combination of overnight variance, open-to-close variance, and the Rogers-Satchell intraday variance:

```
var_yz = var_o + k * var_c + (1 - k) * var_rs
```

where `k = 0.34 / (1.34 + (m+1)/(m-1))` minimises total variance. Independent of both drift and overnight gaps, and roughly **14×** more efficient than close-to-close.

**Arguments**
- `open`, `high`, `low`, `close` — vectors of daily prices (same length, length ≥ 3)
- `trading_periods` — trading periods per year for annualisation (default: 252)

**Minimum observations:** 3

---

## `alizadeh_brandt_diebold`

```julia
alizadeh_brandt_diebold(high, low) -> Vector{Float64}
```

Alizadeh-Brandt-Diebold (2002) log-range proxy for log-volatility.

Returns the log-range `log(H_t / L_t)` for each period. Under geometric Brownian motion this quantity is approximately normally distributed with mean and variance that are known functions of the true log-volatility, making it a near-Gaussian observable for latent volatility in state-space models.

Returns a **vector** of per-period values, not an annualised scalar, since this is a proxy rather than a direct variance estimator.

**Arguments**
- `high`, `low` — vectors of daily high and low prices (same length, length ≥ 1)

**Minimum observations:** 1

---

## Efficiency summary

| Estimator | Relative efficiency vs close-to-close | Handles drift | Handles overnight gaps |
|---|---|---|---|
| `close_to_close` | 1× (baseline) | yes | yes |
| `parkinson` | ~5.2× | no | no |
| `garman_klass` | ~7.4× | no | no |
| `rogers_satchell` | ~8× | yes | no |
| `garman_klass_yang_zhang` | ~8× | no | yes |
| `yang_zhang` | ~14× | yes | yes |
| `alizadeh_brandt_diebold` | proxy only | — | — |

## Notes

- All scalar estimators return **daily volatility** as a decimal by default (`trading_periods=1`). This is convention-independent.
- To annualise, pass `trading_periods`: 252 for US equities, 260 for FX, 365 for crypto. The relationship is `σ_annual = σ_daily × sqrt(trading_periods)`.
- Common `trading_periods` values: 1 (daily, default), 252 (US equities), 260 (FX), 365 (crypto).
- Negative intermediate variance estimates (which can occur under Garman-Klass due to Jensen's inequality) are clamped to zero before taking the square root.
