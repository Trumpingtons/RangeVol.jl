# generate_results.jl
#
# Reads the three OHLC CSV files produced by generate_data.R, computes
# RangeVol estimates over the full series, and saves rangevol_results.csv
# beside ttr_results.csv, for the README's table. runtests.jl computes the
# estimates itself and does not read this file.
#
# Run after generate_data.R:
#   julia --project test/generate_results.jl

using CSV, Tables

include(joinpath(@__DIR__, "..", "src", "RangeVol.jl"))
using .RangeVol

data_dir = joinpath(@__DIR__, "data")

function read_ohlc(path)
    tbl = CSV.File(path)
    open  = Float64[r.open  for r in tbl]
    high  = Float64[r.high  for r in tbl]
    low   = Float64[r.low   for r in tbl]
    close = Float64[r.close for r in tbl]
    return open, high, low, close
end

datasets = ["simulated", "aapl", "sp500"]

rows = NamedTuple{(
    :dataset,
    :close_to_close,
    :parkinson,
    :garman_klass,
    :rogers_satchell,
    :garman_klass_yang_zhang,
    :yang_zhang,
)}[]

for name in datasets
    o, h, l, c = read_ohlc(joinpath(data_dir, "$name.csv"))
    push!(rows, (
        dataset                  = name,
        close_to_close           = close_to_close(c;          trading_periods=252),
        parkinson                = parkinson(h, l;             trading_periods=252),
        garman_klass             = garman_klass(o, h, l, c;   trading_periods=252),
        rogers_satchell          = rogers_satchell(o, h, l, c; trading_periods=252),
        garman_klass_yang_zhang  = garman_klass_yang_zhang(o, h, l, c; trading_periods=252),
        yang_zhang               = yang_zhang(o, h, l, c;     trading_periods=252),
    ))
end

CSV.write(joinpath(data_dir, "rangevol_results.csv"), Tables.dictrowtable(rows))
println("Saved rangevol_results.csv")
for r in rows
    println(r)
end
