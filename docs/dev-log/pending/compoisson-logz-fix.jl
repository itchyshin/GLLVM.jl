using SpecialFunctions

# streaming/online log-sum-exp: track running max m and running sum S = Σ exp(logterm-m)
function stable_logz(logλ, ν, cap, tol)
    T = promote_type(typeof(logλ), typeof(ν))
    m = zero(T)      # j=0 term: logterm=0
    S = one(T)        # exp(0-0)=1
    j = 0
    @inbounds while j < cap
        j += 1
        logterm = j * logλ - ν * loggamma(T(j + 1))
        if logterm > m
            S = S * exp(m - logterm) + one(T)
            m = logterm
        else
            S += exp(logterm - m)
        end
        exp(logterm - m) < tol * S && break
    end
    return m + log(S)
end

naive(logλ, ν, cap, tol) = begin
    Z = 1.0; j = 0
    while j < cap
        j += 1
        lt = j*logλ - ν*loggamma(j+1.0)
        t = exp(lt)
        Z += t
        t < tol*Z && break
    end
    log(Z)
end

# Cases where naive still works: compare to machine precision
for logλ in [0.0, 1.0, 3.0, 5.0]
    n = naive(logλ, 1.0, 10_000, 1e-12)
    s = stable_logz(logλ, 1.0, 10_000, 1e-12)
    println("logλ=$logλ  naive=$n  stable=$s  diff=", abs(n-s))
end
println()
# The broken case
for logλ in [8.0, 12.0, 20.0]
    n = naive(logλ, 1.0, 10_000, 1e-12)
    s = stable_logz(logλ, 1.0, 10_000, 1e-12)
    # cross-check against Poisson identity: at ν=1, logZ(λ) = λ (since Σ λ^j/j! = e^λ)
    println("logλ=$logλ  naive=$n  stable=$s  true(=exp(logλ))=", exp(logλ))
end

# Diagnose logλ=12: does the cap (10000) get hit before convergence?
function stable_logz_trace(logλ, ν, cap, tol)
    T = Float64
    m = zero(T); S = one(T); j = 0
    lastj = 0
    while j < cap
        j += 1
        logterm = j * logλ - ν * loggamma(T(j + 1))
        if logterm > m
            S = S * exp(m - logterm) + one(T)
            m = logterm
        else
            S += exp(logterm - m)
        end
        lastj = j
        exp(logterm - m) < tol * S && break
    end
    println("  stopped at j=$lastj of cap=$cap, m=$m")
    return m + log(S)
end
println("logλ=12 trace:"); stable_logz_trace(12.0, 1.0, 10_000, 1e-12)
println("logλ=20 trace:"); stable_logz_trace(20.0, 1.0, 10_000, 1e-12)
