# Pure preparation for complete-data oracle fixtures; no RCall or fitter.
# This harness deliberately admits integer trials/successes, not every possible
# frozen-R data policy. Missing responses belong to separate required fixtures.
function parity_trial_inputs(y::AbstractMatrix, family::Symbol, N,
                             binomial_link::Symbol = :logit)
    binomial_link in (:logit, :probit, :cloglog) ||
        throw(ArgumentError("unsupported binomial oracle link: $binomial_link"))
    family === :binomial || binomial_link === :logit ||
        throw(ArgumentError("binomial_link applies only to family=:binomial"))
    counted = family in (:binomial, :betabinomial)
    N === nothing || counted ||
        throw(ArgumentError("N is trial counts, supported only for binomial/betabinomial oracles"))
    family === :betabinomial && N === nothing &&
        throw(ArgumentError("family=:betabinomial requires trial counts N (p×n)"))
    if N !== nothing
        size(N) == size(y) || throw(DimensionMismatch("N must have the same p×n shape as y"))
    end
    trials = N === nothing ? ones(Float64, size(y)) : Matrix{Float64}(N)
    if counted
        for i in eachindex(y, trials)
            t = trials[i]
            isfinite(t) && t > 0 && isinteger(t) &&
                (N === nothing || t == N[i]) ||
                throw(ArgumentError("oracle trials must be positive integers exactly representable as Float64"))
            v = y[i]
            v isa Real && isfinite(v) && isinteger(v) && 0 <= v <= t && Float64(v) == v ||
                throw(ArgumentError("oracle successes must be finite integers in [0,N], exactly representable as Float64"))
        end
    end
    return trials, String(binomial_link)
end
