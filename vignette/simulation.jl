# The simulation in the vignette: bias and efficiency of each estimator on prices
# that move as a random walk in log terms, sampled every minute or every second.
#
#   julia --project=. vignette/simulation.jl

using RangeVol, Random, Statistics

# `days` days of `steps` steps each; intraday sd `sd` a day, overnight sd `sn`
function sample(rng, days, steps, sd, sn)
    o = zeros(days); h = zeros(days); l = zeros(days); c = zeros(days)
    p = 0.0
    for d in 1:days
        p += sn * randn(rng)
        o[d] = p; hi = p; lo = p
        for _ in 1:steps
            p += sd / sqrt(steps) * randn(rng)
            hi = max(hi, p); lo = min(lo, p)
        end
        h[d] = hi; l[d] = lo; c[d] = p
    end
    return exp.(o), exp.(h), exp.(l), exp.(c)
end

const ESTIMATORS = (
    close_to_close = (o, h, l, c) -> close_to_close(c),
    parkinson = (o, h, l, c) -> parkinson(h, l),
    garman_klass = garman_klass,
    rogers_satchell = rogers_satchell,
    garman_klass_yang_zhang = garman_klass_yang_zhang,
    yang_zhang = yang_zhang,
)

# Mean of each daily variance estimate over the true one, and its efficiency:
# the variance of close-to-close over the estimator's, each divided by its mean
function run(label; sn = 0.0, reps = 2000, days = 250, steps = 390, sd = 0.0126)
    rng = Xoshiro(1)
    est = Dict(k => Float64[] for k in keys(ESTIMATORS))
    for _ in 1:reps
        o, h, l, c = sample(rng, days, steps, sd, sn)
        for (k, f) in pairs(ESTIMATORS)
            push!(est[k], f(o, h, l, c)^2)
        end
    end
    scaled(v) = v ./ mean(v)
    base = var(scaled(est[:close_to_close]))
    println(label, ": ", reps, " samples of ", days, " days, ", steps, " steps a day")
    for k in keys(ESTIMATORS)
        v = est[k]
        println("  ", rpad(k, 25), "mean/true ", round(mean(v) / (sd^2 + sn^2), digits = 3),
            "   efficiency ", round(base / var(scaled(v)), digits = 2))
    end
end

run("A. Minutes, no overnight move")
run("B. Minutes, overnight moves a fifth of the variance"; sn = 0.0063)
run("C. Seconds, no overnight move"; reps = 400, steps = 23400)
