# ============================================================
# Range-Based Volatility Estimators
# ============================================================

"""
    close_to_close(close; trading_periods=252) -> Float64

Classical close-to-close historical volatility estimator.

Computes the sample standard deviation of daily log-returns
`log(C_t / C_{t-1})` and annualises by `sqrt(trading_periods)`.
This is the textbook baseline against which range-based estimators
report their relative efficiency gains.

Requires at least two closing prices (so that at least one log-return
can be formed).

# Arguments
- `close`: vector of daily closing prices (length >= 2)
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Merton, R. C. (1980). On estimating the expected return on the market: An
exploratory investigation. *Journal of Financial Economics*, 8(4), 323–361.
"""
function close_to_close(
    close::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(close)
    n >= 2 || throw(ArgumentError("at least two observations are required"))

    m = n - 1
    r = [log(close[i] / close[i-1]) for i in 2:n]
    mean_r = sum(r) / m
    var_r = sum((ri - mean_r)^2 for ri in r) / (m - 1)
    return sqrt(var_r * trading_periods)
end

"""
    parkinson(high, low; trading_periods=252) -> Float64

Parkinson (1980) range-based volatility estimator.

Uses only the daily high-low range. Roughly 5.2x more efficient than
close-to-close estimation when the underlying drift is negligible. Does not
account for overnight gaps or non-zero drift.

# Arguments
- `high`: vector of daily high prices
- `low`: vector of daily low prices
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Parkinson, M. (1980). The extreme value method for estimating the variance of the
rate of return. *Journal of Business*, 53(1), 61–65.
"""
function parkinson(
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(high)
    n == length(low) || throw(ArgumentError("high and low must have the same length"))
    n >= 2 || throw(ArgumentError("at least two observations are required"))

    var_p = sum(log(high[i] / low[i])^2 for i in 1:n) / (4n * log(2))
    return sqrt(var_p * trading_periods)
end

"""
    garman_klass(open, high, low, close; trading_periods=252) -> Float64

Garman-Klass (1980) OHLC volatility estimator.

Extends Parkinson by incorporating the open-to-close log-return, achieving
roughly 7.4x the efficiency of close-to-close estimation. Assumes zero drift
and no overnight gaps between the close and the next open.

# Arguments
- `open`, `high`, `low`, `close`: vectors of daily prices (same length)
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Garman, M. B., & Klass, M. J. (1980). On the estimation of security price
volatilities from historical data. *Journal of Business*, 53(1), 67–78.
"""
function garman_klass(
    open::AbstractVector{<:Real},
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real},
    close::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(open)
    n == length(high) == length(low) == length(close) ||
        throw(ArgumentError("all price vectors must have the same length"))
    n >= 2 || throw(ArgumentError("at least two observations are required"))

    c = 2log(2) - 1
    var_gk = sum(
        0.5 * log(high[i] / low[i])^2 - c * log(close[i] / open[i])^2
        for i in 1:n
    ) / n
    return sqrt(max(var_gk, 0.0) * trading_periods)
end

"""
    rogers_satchell(open, high, low, close; trading_periods=252) -> Float64

Rogers-Satchell (1991) OHLC volatility estimator.

Drift-independent estimator that remains unbiased when the expected return is
non-zero, achieving roughly 8x the efficiency of close-to-close estimation.
Does not correct for overnight price gaps.

# Arguments
- `open`, `high`, `low`, `close`: vectors of daily prices (same length)
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Rogers, L. C. G., & Satchell, S. E. (1991). Estimating variance from high, low
and closing prices. *Annals of Applied Probability*, 1(4), 504–512.
"""
function rogers_satchell(
    open::AbstractVector{<:Real},
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real},
    close::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(open)
    n == length(high) == length(low) == length(close) ||
        throw(ArgumentError("all price vectors must have the same length"))
    n >= 2 || throw(ArgumentError("at least two observations are required"))

    var_rs = sum(
        log(high[i] / close[i]) * log(high[i] / open[i]) +
        log(low[i] / close[i]) * log(low[i] / open[i])
        for i in 1:n
    ) / n
    return sqrt(max(var_rs, 0.0) * trading_periods)
end

"""
    garman_klass_yang_zhang(open, high, low, close; trading_periods=252) -> Float64

Garman-Klass (1980) estimator extended by Yang and Zhang (2000) to account for
overnight price gaps.

Adds the squared overnight log-return log(Open_t / Close_{t-1})^2 to the standard
Garman-Klass intraday terms. Uses periods 2:n, so n >= 2 consecutive days are
required.

# Arguments
- `open`, `high`, `low`, `close`: vectors of daily prices (length >= 2)
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Yang, D., & Zhang, Q. (2000). Drift-independent volatility estimation based on
high, low, open, and close prices. *Journal of Business*, 73(3), 477–491.
"""
function garman_klass_yang_zhang(
    open::AbstractVector{<:Real},
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real},
    close::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(open)
    n == length(high) == length(low) == length(close) ||
        throw(ArgumentError("all price vectors must have the same length"))
    n >= 2 || throw(ArgumentError("at least two observations are required"))

    c = 2log(2) - 1
    m = n - 1
    var_gkyz = sum(
        log(open[i] / close[i-1])^2 +
        0.5 * log(high[i] / low[i])^2 -
        c * log(close[i] / open[i])^2
        for i in 2:n
    ) / m
    return sqrt(max(var_gkyz, 0.0) * trading_periods)
end

"""
    yang_zhang(open, high, low, close; trading_periods=252) -> Float64

Yang-Zhang (2000) minimum-variance volatility estimator.

The optimal linear combination of overnight variance (var_o), open-to-close
variance (var_c), and the Rogers-Satchell intraday variance (var_rs):

    var_yz = var_o + k * var_c + (1 - k) * var_rs

where the weight `k = 0.34 / (1.34 + (m+1)/(m-1))` minimises the total
variance. Independent of both drift and overnight gaps, and roughly 14x more
efficient than close-to-close estimation.

Requires at least three observations (so that m = n - 1 >= 2 for the sample
variances).

# Arguments
- `open`, `high`, `low`, `close`: vectors of daily prices (length >= 3)
- `trading_periods`: multiply by this before taking the square root (default: 1 = daily volatility; use 252 for annualised equities, 260 for FX, 365 for crypto)

# References
Yang, D., & Zhang, Q. (2000). Drift-independent volatility estimation based on
high, low, open, and close prices. *Journal of Business*, 73(3), 477–491.
"""
function yang_zhang(
    open::AbstractVector{<:Real},
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real},
    close::AbstractVector{<:Real};
    trading_periods::Int = 1,
)
    n = length(open)
    n == length(high) == length(low) == length(close) ||
        throw(ArgumentError("all price vectors must have the same length"))
    n >= 3 || throw(ArgumentError("at least three observations are required"))

    m = n - 1

    r_o = [log(open[i] / close[i-1]) for i in 2:n]
    r_c = [log(close[i] / open[i]) for i in 2:n]

    mean_o = sum(r_o) / m
    mean_c = sum(r_c) / m

    var_o  = sum((r - mean_o)^2 for r in r_o) / (m - 1)
    var_c  = sum((r - mean_c)^2 for r in r_c) / (m - 1)
    var_rs = sum(
        log(high[i] / close[i]) * log(high[i] / open[i]) +
        log(low[i] / close[i]) * log(low[i] / open[i])
        for i in 2:n
    ) / m

    k = 0.34 / (1.34 + (m + 1) / (m - 1))
    var_yz = var_o + k * var_c + (1 - k) * var_rs
    return sqrt(max(var_yz, 0.0) * trading_periods)
end

"""
    alizadeh_brandt_diebold(high, low) -> Vector{Float64}

Alizadeh-Brandt-Diebold (2002) log range, a proxy for log-volatility.

Returns the log range `log(log(H_t) - log(L_t))` for each period: the
logarithm of the range of the log price. Under a random walk in the log
price it is close to normally distributed, with a mean that moves one for
one with the log-volatility `log(sigma_t)` (about `0.43 + log(sigma_t)` for
continuously observed prices) and a standard deviation of about 0.29,
making it a near-Gaussian observation of latent volatility in state-space
models. The range itself, `log(H_t / L_t)`, is right-skewed; take
`exp.(alizadeh_brandt_diebold(high, low))` for it.

A period whose high equals its low has a range of zero and gives `-Inf`;
drop such periods (`filter(isfinite, lr)`) before fitting a model.

Returns a vector of per-period values, not an annualised scalar, since this
is a proxy/observable rather than a direct variance estimator.

# Arguments
- `high`: vector of daily high prices
- `low`: vector of daily low prices

# References
Alizadeh, S., Brandt, M. W., & Diebold, F. X. (2002). Range-based
estimation of stochastic volatility models. *Journal of Finance*,
57(3), 1047–1091.
"""
function alizadeh_brandt_diebold(
    high::AbstractVector{<:Real},
    low::AbstractVector{<:Real},
)
    n = length(high)
    n == length(low) || throw(ArgumentError("high and low must have the same length"))
    n >= 1 || throw(ArgumentError("at least one observation is required"))

    return [log(log(high[i]) - log(low[i])) for i in 1:n]
end
