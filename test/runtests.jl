using Test, CSV, Tables, StableRNGs

include(joinpath(@__DIR__, "..", "src", "RangeVol.jl"))
using .RangeVol

data_dir = joinpath(@__DIR__, "data")

# ── Cross-validation against TTR (R) ─────────────────────────────────────────
# Requires generate_data.R to have been run first: it writes the OHLC series
# and TTR's estimates of them, which are recomputed here with RangeVol.
@testset "TTR cross-validation" begin
    ttr_file = joinpath(data_dir, "ttr_results.csv")

    if !isfile(ttr_file)
        @warn "ttr_results.csv not found — run generate_data.R first"
    else
        estimators = [
            :close_to_close          => (o, h, l, c) -> close_to_close(c; trading_periods = 252),
            :parkinson               => (o, h, l, c) -> parkinson(h, l; trading_periods = 252),
            :garman_klass            => (o, h, l, c) -> garman_klass(o, h, l, c; trading_periods = 252),
            :rogers_satchell         => (o, h, l, c) -> rogers_satchell(o, h, l, c; trading_periods = 252),
            :garman_klass_yang_zhang => (o, h, l, c) -> garman_klass_yang_zhang(o, h, l, c; trading_periods = 252),
            :yang_zhang              => (o, h, l, c) -> yang_zhang(o, h, l, c; trading_periods = 252),
        ]

        for t in CSV.File(ttr_file)
            @testset "$(t.dataset)" begin
                tbl = CSV.File(joinpath(data_dir, "$(t.dataset).csv"))
                o, h, l, c = (Float64[getproperty(r, k) for r in tbl] for k in (:open, :high, :low, :close))
                for (est, f) in estimators
                    @test isapprox(f(o, h, l, c), getproperty(t, est); rtol = 1e-10)
                end
            end
        end
    end
end

# ── Unit tests with StableRNG simulated data ──────────────────────────────────
@testset "Simulated OHLC — basic properties" begin
    rng = StableRNG(42)
    n   = 500
    dt  = 1 / 252
    sigma = 0.20

    # GBM sampled at 390 steps a day: open = previous close (no overnight gap),
    # high and low the extremes of the day's path
    steps = 390
    op, hi, lo, cl = zeros(n), zeros(n), zeros(n), zeros(n)
    p = log(100.0)
    for t in 1:n
        path = p .+ cumsum(sigma * sqrt(dt / steps) .* randn(rng, steps))
        op[t], hi[t], lo[t], cl[t] = exp(p), exp(max(p, maximum(path))), exp(min(p, minimum(path))), exp(path[end])
        p = path[end]
    end

    daily_sigma = sigma / sqrt(252)

    @testset "close_to_close" begin
        vol = close_to_close(cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "parkinson" begin
        vol = parkinson(hi, lo)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "garman_klass" begin
        vol = garman_klass(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "rogers_satchell" begin
        vol = rogers_satchell(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "garman_klass_yang_zhang" begin
        vol = garman_klass_yang_zhang(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "yang_zhang" begin
        vol = yang_zhang(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; rtol = 0.1)
    end

    @testset "alizadeh_brandt_diebold" begin
        lr = alizadeh_brandt_diebold(hi, lo)
        @test length(lr) == n
        @test exp.(lr) ≈ log.(hi ./ lo)
        @test alizadeh_brandt_diebold([1.0], [1.0]) == [-Inf]
    end
end

# ── Argument validation ───────────────────────────────────────────────────────
@testset "Argument validation" begin
    @test_throws ArgumentError close_to_close([100.0])
    @test_throws ArgumentError parkinson([1.0], [0.9, 0.8])
    @test_throws ArgumentError parkinson([1.0], [0.9])
    @test_throws ArgumentError garman_klass([1.0], [1.1], [0.9], [1.0, 1.0])
    @test_throws ArgumentError yang_zhang([1.0, 1.0], [1.1, 1.1], [0.9, 0.9], [1.0, 1.0])
end
