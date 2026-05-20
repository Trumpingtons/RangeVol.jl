using Test, CSV, Tables, StableRNGs

include(joinpath(@__DIR__, "..", "src", "RangeVol.jl"))
using .RangeVol

data_dir = joinpath(@__DIR__, "data")

# ── Cross-validation against TTR (R) ─────────────────────────────────────────
# Requires generate_data.R and generate_results.jl to have been run first.
@testset "TTR cross-validation" begin
    ttr_file = joinpath(data_dir, "ttr_results.csv")
    rv_file  = joinpath(data_dir, "rangevol_results.csv")

    if !isfile(ttr_file) || !isfile(rv_file)
        @warn "Cross-validation CSVs not found — run generate_data.R then generate_results.jl first"
    else
        ttr = CSV.File(ttr_file)
        rv  = CSV.File(rv_file)

        estimators = [
            :close_to_close,
            :parkinson,
            :garman_klass,
            :rogers_satchell,
            :garman_klass_yang_zhang,
            :yang_zhang,
        ]

        for (t, r) in zip(ttr, rv)
            @testset "$(t.dataset)" begin
                for est in estimators
                    tv = getproperty(t, est)
                    rv_val = getproperty(r, est)
                    @test isapprox(tv, rv_val; rtol = 1e-4) broken = (tv === missing || rv_val === missing)
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

    # GBM: one price path, open = previous close (no overnight gap)
    log_ret = sigma * sqrt(dt) .* randn(rng, n)
    price   = 100.0 .* cumprod(exp.(log_ret))

    cl = price
    op = vcat([100.0], price[1:end-1])

    # Intraday high/low: Brownian bridge range ~ |N(0,1)| * sigma * sqrt(dt)
    intraday = abs.(randn(rng, n)) .* sigma * sqrt(dt)
    hi = max.(op, cl) .* exp.(intraday .* 0.5)
    lo = min.(op, cl) .* exp.(-intraday .* 0.5)

    daily_sigma = sigma / sqrt(252)

    @testset "close_to_close" begin
        vol = close_to_close(cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "parkinson" begin
        vol = parkinson(hi, lo)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "garman_klass" begin
        vol = garman_klass(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "rogers_satchell" begin
        vol = rogers_satchell(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "garman_klass_yang_zhang" begin
        vol = garman_klass_yang_zhang(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "yang_zhang" begin
        vol = yang_zhang(op, hi, lo, cl)
        @test vol > 0
        @test isapprox(vol, daily_sigma; atol = 0.005)
    end

    @testset "alizadeh_brandt_diebold" begin
        lr = alizadeh_brandt_diebold(hi, lo)
        @test length(lr) == n
        @test all(lr .>= 0)
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
