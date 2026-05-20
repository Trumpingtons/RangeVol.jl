"""
RangeVol — Range-Based Volatility Estimators

Classical volatility estimators for financial time series, including the
close-to-close baseline, Parkinson (1980), Garman-Klass (1980),
Rogers-Satchell (1991), the Garman-Klass-Yang-Zhang overnight extension,
and the full Yang-Zhang (2000) minimum-variance estimator.

All estimators accept vectors of daily prices and return annualised volatility.
"""
module RangeVol

using Statistics

export close_to_close
export parkinson
export garman_klass
export rogers_satchell
export garman_klass_yang_zhang
export yang_zhang
export alizadeh_brandt_diebold

include("RangeBasedEstimators.jl")

end # module RangeVol
