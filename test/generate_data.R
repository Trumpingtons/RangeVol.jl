# generate_data.R
#
# Downloads AAPL (stock) OHLC data via quantmod and the S&P 500 (index) from
# PollisDatasets.jl, simulates a synthetic OHLC series, and saves all three to
# test/data/ as CSV files.
# Also computes TTR volatility estimates and saves them for cross-validation.
#
# Run once before the Julia test suite:
#   Rscript test/generate_data.R

library(quantmod)
library(TTR)

data_dir <- file.path(dirname(normalizePath(commandArgs(trailingOnly = FALSE)[
  grep("--file=", commandArgs(trailingOnly = FALSE))
][1], mustWork = FALSE)), "data")
data_dir <- sub("--file=", "", data_dir)
if (!dir.exists(data_dir)) dir.create(data_dir, recursive = TRUE)

# ── 1. Simulated OHLC data ────────────────────────────────────────────────────
# Reproducible GBM simulation matching the Julia StableRNG seed
set.seed(42)
n      <- 500
dt     <- 1 / 252
sigma  <- 0.20
mu     <- 0.05
S      <- numeric(n + 1)
S[1]   <- 100.0

for (i in seq_len(n)) {
  S[i + 1] <- S[i] * exp((mu - 0.5 * sigma^2) * dt + sigma * sqrt(dt) * rnorm(1))
}

# Simulate intraday high/low around each close using a range expansion factor
range_factor <- abs(rnorm(n, mean = 0, sd = sigma * sqrt(dt)))
sim_open  <- S[1:n] * exp(rnorm(n, 0, sigma * sqrt(dt) * 0.5))
sim_close <- S[2:(n + 1)]
sim_high  <- pmax(sim_open, sim_close) * exp(range_factor)
sim_low   <- pmin(sim_open, sim_close) * exp(-range_factor)

sim_data <- data.frame(
  open  = sim_open,
  high  = sim_high,
  low   = sim_low,
  close = sim_close
)
write.csv(sim_data, file.path(data_dir, "simulated.csv"), row.names = FALSE)
cat("Saved simulated.csv (", nrow(sim_data), "rows )\n")

# ── 2. AAPL stock data ────────────────────────────────────────────────────────
getSymbols("AAPL", from = "2023-01-01", to = "2023-12-31", auto.assign = TRUE)
aapl <- data.frame(
  date  = index(AAPL),
  open  = as.numeric(Op(AAPL)),
  high  = as.numeric(Hi(AAPL)),
  low   = as.numeric(Lo(AAPL)),
  close = as.numeric(Cl(AAPL))
)
write.csv(aapl, file.path(data_dir, "aapl.csv"), row.names = FALSE)
cat("Saved aapl.csv (", nrow(aapl), "rows )\n")

# ── 3. S&P 500 index data ─────────────────────────────────────────────────────
# The 250 trading days of 2023 from the sp500 dataset of PollisDatasets.jl
# (Yahoo! Finance ^GSPC, CC0-1.0). Yahoo's EURUSD=X, used before, has the close
# equal to the open on almost every day, which leaves the open-to-close terms of
# the range-based estimators at zero.
sp500_url <- "https://raw.githubusercontent.com/Trumpingtons/PollisDatasets.jl/main/data/sp500.csv"
sp500 <- read.csv(sp500_url)
sp500 <- sp500[startsWith(sp500$date, "2023"), c("date", "open", "high", "low", "close")]
write.csv(sp500, file.path(data_dir, "sp500.csv"), row.names = FALSE)
cat("Saved sp500.csv (", nrow(sp500), "rows )\n")

# ── Helper: compute all TTR estimates for one OHLC data frame ─────────────────
# n = nrow(df) uses the full series, returning a single scalar (last value).
ttr_estimates <- function(df) {
  ohlc <- df[, c("open", "high", "low", "close")]
  n    <- nrow(df)
  last <- function(x) as.numeric(tail(na.omit(x), 1))
  # For gk.yz and yang.zhang, TTR's window n counts cross-day pairs not rows,
  # so pass n-1 to match Julia's convention of using all n-1 consecutive pairs.
  data.frame(
    close_to_close          = last(volatility(ohlc, n = n,     calc = "close",           N = 252)),
    parkinson               = last(volatility(ohlc, n = n,     calc = "parkinson",       N = 252)),
    garman_klass            = last(volatility(ohlc, n = n,     calc = "garman.klass",    N = 252)),
    rogers_satchell         = last(volatility(ohlc, n = n,     calc = "rogers.satchell", N = 252)),
    garman_klass_yang_zhang = last(volatility(ohlc, n = n - 1, calc = "gk.yz",           N = 252)),
    yang_zhang              = last(volatility(ohlc, n = n - 1, calc = "yang.zhang",       N = 252))
  )
}

# ── 4. Compute TTR estimates using full series (n=nrow) ───────────────────────
results <- rbind(
  data.frame(dataset = "simulated", ttr_estimates(sim_data)),
  data.frame(dataset = "aapl",      ttr_estimates(aapl)),
  data.frame(dataset = "sp500",     ttr_estimates(sp500))
)

write.csv(results, file.path(data_dir, "ttr_results.csv"), row.names = FALSE)
cat("Saved ttr_results.csv\n")
print(results)
