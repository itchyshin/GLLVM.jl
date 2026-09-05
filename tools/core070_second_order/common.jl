parity_loadings_p5k2() = [
    0.8   0.0
    0.5   0.6
    0.3  -0.4
   -0.2   0.5
    0.1   0.3
]

function parity_site_design(x::AbstractVector{<:Real}, p::Integer)
    n = length(x)
    X = zeros(Float64, p, n, 1)
    @inbounds for t in 1:p, s in 1:n
        X[t, s, 1] = Float64(x[s])
    end
    return X
end

# ---------------------------------------------------------------------------
# Local samplers (ported from the same test files; no Distributions dep for
# the ones the original tests avoided it for -- kept identical so the DGP
# reproduces bit-for-bit under the same seed).
# ---------------------------------------------------------------------------
function _rand_poisson(λ::Float64)
    λ = clamp(λ, 0.0, 1e6)
    L = exp(-λ)
    k = 0
    prod = 1.0
    while true
        k += 1
        prod *= rand()
        prod <= L && return k - 1
    end
end

function _rand_beta_jonk(a::Float64, b::Float64)
    a = max(a, 1e-12)
    b = max(b, 1e-12)
    while true
        u = rand()
        v = rand()
        x = u^(1 / a)
        y = v^(1 / b)
        s = x + y
        if s <= 1.0 && s > 0.0
            return x / s
        end
    end
end

function _rand_gamma_ms(shape::Float64, scale::Float64)
    if shape < 1.0
        return _rand_gamma_ms(shape + 1.0, scale) * rand()^(1.0 / shape)
    end
    d = shape - 1.0 / 3.0
    c = 1.0 / sqrt(9.0 * d)
    while true
        z = randn()
        v = (1.0 + c * z)^3
        v <= 0 && continue
        u = rand()
        z2 = z * z
        u < 1.0 - 0.0331 * z2 * z2 && return d * v * scale
        logu = log(u)
        logu < 0.5 * z2 + d * (1.0 - v + log(v)) && return d * v * scale
    end
end

_rand_nb2_ms(μ::Float64, r::Float64) = _rand_poisson(_rand_gamma_ms(r, μ / r))

# ===========================================================================
# R-side (se=TRUE) fit helpers -- generalized twins of
# fit_gllvmtmb_parity_loglik / _x / _species_x (test/parity/parity_helpers.jl)
# with se=TRUE and sd_report extraction (mirrors se-prerun-01's r_fit.R).
# ===========================================================================
function _require_gllvmtmb!()
    R"""
    suppressMessages(library(gllvmTMB))
    """
end

# no-X
function r_fit_se(y::AbstractMatrix, K::Integer; family::Symbol,
        N::Union{Nothing,AbstractMatrix} = nothing, binomial_link::Symbol = :logit)
    p, n = size(y)
    trials = N === nothing ? ones(Float64, size(y)) : Matrix{Float64}(N)
    trials_provided = N !== nothing
    fam = String(family)
    blink = String(binomial_link)
    _require_gllvmtmb!()
    @rput y K p n fam trials blink trials_provided
    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y)
    )
    fam_obj <- switch(fam,
        gaussian     = stats::gaussian(),
        binomial     = stats::binomial(link = blink),
        poisson      = stats::poisson(),
        gamma        = stats::Gamma(link = "log"),
        negbinomial  = gllvmTMB::nbinom2(),
        nb1          = gllvmTMB::nbinom1(),
        beta         = gllvmTMB::Beta(),
        betabinomial = gllvmTMB::betabinomial(),
        stop(sprintf("unknown family: %s", fam))
    )
    weights_vec <- if (identical(fam, "betabinomial") || (identical(fam, "binomial") && trials_provided)) as.vector(trials) else NULL
    t0 <- Sys.time()
    fit_r <- gllvmTMB(
        value ~ 0 + trait + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long, unit = "site", trait = "trait", family = fam_obj,
        weights = weights_vec,
        control = gllvmTMBcontrol(n_init = 1L, se = TRUE)
    )
    wall_fit <- as.numeric(Sys.time() - t0, units = "secs")
    r_logL  <- as.numeric(stats::logLik(fit_r))
    r_obj   <- as.numeric(fit_r$opt$objective)
    r_conv  <- identical(as.integer(fit_r$opt$convergence), 0L)
    has_sd  <- !is.null(fit_r$sd_report)
    nm <- character(0); pf <- numeric(0); se_raw <- numeric(0); cv <- matrix(numeric(0),0,0)
    pdh <- NA; rcond <- NA_real_
    if (has_sd) {
        sdr <- fit_r$sd_report
        pf  <- sdr$par.fixed
        cv  <- sdr$cov.fixed
        se_raw <- sqrt(diag(cv))
        nm  <- names(pf)
        pdh <- isTRUE(sdr$pdHess)
        rcond <- tryCatch(kappa(cv), error = function(e) NA_real_)
    }
    """
    return (
        logLik = rcopy(Float64, R"r_logL"),
        objective = rcopy(Float64, R"r_obj"),
        converged = rcopy(Bool, R"r_conv"),
        has_sd = rcopy(Bool, R"has_sd"),
        names = has_sd_names(),
        par_fixed = has_sd_pf(),
        cov_fixed = has_sd_cv(),
        pd_hessian = rcopy(Any, R"pdh"),
        r_condition_number = rcopy(Any, R"rcond"),
        wall_fit = rcopy(Float64, R"wall_fit"),
    )
end

# small helpers so the NamedTuple above stays readable (rcopy needs care with
# possibly-empty R vectors)
has_sd_names() = rcopy(Vector{String}, R"nm")
has_sd_pf() = rcopy(Vector{Float64}, R"as.numeric(pf)")
has_sd_cv() = rcopy(Matrix{Float64}, R"matrix(as.numeric(cv), nrow=nrow(cv))")

# shared site-X
function r_fit_se_x(y::AbstractMatrix, x_site::AbstractVector{<:Real}, K::Integer;
        family::Symbol, N::Union{Nothing,AbstractMatrix} = nothing,
        binomial_link::Symbol = :logit)
    p, n = size(y)
    trials = N === nothing ? ones(Float64, size(y)) : Matrix{Float64}(N)
    trials_provided = N !== nothing
    fam = String(family)
    blink = String(binomial_link)
    x = collect(Float64, x_site)
    _require_gllvmtmb!()
    @rput y K p n fam x trials blink trials_provided
    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y),
        x     = rep(as.numeric(x), each = p)
    )
    fam_obj <- switch(fam,
        gaussian     = stats::gaussian(),
        binomial     = stats::binomial(link = blink),
        poisson      = stats::poisson(),
        gamma        = stats::Gamma(link = "log"),
        negbinomial  = gllvmTMB::nbinom2(),
        nb1          = gllvmTMB::nbinom1(),
        beta         = gllvmTMB::Beta(),
        betabinomial = gllvmTMB::betabinomial(),
        stop(sprintf("unknown family: %s", fam))
    )
    weights_vec <- if (identical(fam, "betabinomial") || (identical(fam, "binomial") && trials_provided)) as.vector(trials) else NULL
    t0 <- Sys.time()
    fit_r <- gllvmTMB(
        value ~ 0 + trait + x + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long, unit = "site", trait = "trait", family = fam_obj,
        weights = weights_vec,
        control = gllvmTMBcontrol(n_init = 1L, se = TRUE)
    )
    wall_fit <- as.numeric(Sys.time() - t0, units = "secs")
    r_logL  <- as.numeric(stats::logLik(fit_r))
    r_obj   <- as.numeric(fit_r$opt$objective)
    r_conv  <- identical(as.integer(fit_r$opt$convergence), 0L)
    has_sd  <- !is.null(fit_r$sd_report)
    nm <- character(0); pf <- numeric(0); se_raw <- numeric(0); cv <- matrix(numeric(0),0,0)
    pdh <- NA; rcond <- NA_real_
    if (has_sd) {
        sdr <- fit_r$sd_report
        pf  <- sdr$par.fixed
        cv  <- sdr$cov.fixed
        se_raw <- sqrt(diag(cv))
        nm  <- names(pf)
        pdh <- isTRUE(sdr$pdHess)
        rcond <- tryCatch(kappa(cv), error = function(e) NA_real_)
    }
    """
    return (
        logLik = rcopy(Float64, R"r_logL"),
        objective = rcopy(Float64, R"r_obj"),
        converged = rcopy(Bool, R"r_conv"),
        has_sd = rcopy(Bool, R"has_sd"),
        names = has_sd_names(),
        par_fixed = has_sd_pf(),
        cov_fixed = has_sd_cv(),
        pd_hessian = rcopy(Any, R"pdh"),
        r_condition_number = rcopy(Any, R"rcond"),
        wall_fit = rcopy(Float64, R"wall_fit"),
    )
end

# species-specific X ((0+trait):x)
function r_fit_se_species_x(y::AbstractMatrix, x_site::AbstractVector{<:Real}, K::Integer;
        family::Symbol)
    p, n = size(y)
    fam = String(family)
    x = collect(Float64, x_site)
    _require_gllvmtmb!()
    @rput y K p n fam x
    R"""
    trait_names <- paste0("t", seq_len(p))
    df_long <- data.frame(
        site  = factor(rep(seq_len(n), each = p)),
        trait = factor(rep(trait_names, times = n), levels = trait_names),
        value = as.vector(y),
        x     = rep(as.numeric(x), each = p)
    )
    fam_obj <- switch(fam,
        poisson  = stats::poisson(),
        binomial = stats::binomial(link = "logit"),
        stop(sprintf("unknown family: %s", fam))
    )
    t0 <- Sys.time()
    fit_r <- gllvmTMB(
        value ~ 0 + trait + (0 + trait):x + latent(0 + trait | site, d = K, unique = FALSE),
        data = df_long, unit = "site", trait = "trait", family = fam_obj,
        control = gllvmTMBcontrol(n_init = 1L, se = TRUE)
    )
    wall_fit <- as.numeric(Sys.time() - t0, units = "secs")
    r_logL  <- as.numeric(stats::logLik(fit_r))
    r_obj   <- as.numeric(fit_r$opt$objective)
    r_conv  <- identical(as.integer(fit_r$opt$convergence), 0L)
    has_sd  <- !is.null(fit_r$sd_report)
    nm <- character(0); pf <- numeric(0); se_raw <- numeric(0); cv <- matrix(numeric(0),0,0)
    pdh <- NA; rcond <- NA_real_
    if (has_sd) {
        sdr <- fit_r$sd_report
        pf  <- sdr$par.fixed
        cv  <- sdr$cov.fixed
        se_raw <- sqrt(diag(cv))
        nm  <- names(pf)
        pdh <- isTRUE(sdr$pdHess)
        rcond <- tryCatch(kappa(cv), error = function(e) NA_real_)
    }
    """
    return (
        logLik = rcopy(Float64, R"r_logL"),
        objective = rcopy(Float64, R"r_obj"),
        converged = rcopy(Bool, R"r_conv"),
        has_sd = rcopy(Bool, R"has_sd"),
        names = has_sd_names(),
        par_fixed = has_sd_pf(),
        cov_fixed = has_sd_cv(),
        pd_hessian = rcopy(Any, R"pdh"),
        r_condition_number = rcopy(Any, R"rcond"),
        wall_fit = rcopy(Float64, R"wall_fit"),
    )
end

# ===========================================================================
# JSON writer (hand-rolled -- no JSON dependency assumed in this Project.toml)
# ===========================================================================
function _jnum(x::Real)
    xf = Float64(x)
    isnan(xf) && return "null"
    isinf(xf) && return xf > 0 ? "1e309" : "-1e309"
    return repr(xf)
end
_jnum(::Nothing) = "null"
_jbool(b::Bool) = b ? "true" : "false"
_jstr(s) = "\"" * replace(String(s), "\"" => "\\\"") * "\""

function write_json(path::AbstractString, d::AbstractDict)
    open(path, "w") do io
        println(io, "{")
        ks = collect(keys(d))
        for (i, k) in enumerate(ks)
            v = d[k]
            print(io, "  ", _jstr(k), ": ")
            _write_json_value(io, v)
            println(io, i == length(ks) ? "" : ",")
        end
        println(io, "}")
    end
end

function _write_json_value(io, v)
    if v isa AbstractString || v isa Symbol
        print(io, _jstr(v))
    elseif v isa Bool
        print(io, _jbool(v))
    elseif v isa Integer
        print(io, string(v))
    elseif v isa Real
        print(io, _jnum(v))
    elseif v isa Nothing || v isa Missing
        print(io, "null")
    elseif v isa AbstractVector
        print(io, "[")
        for (i, x) in enumerate(v)
            _write_json_value(io, x)
            i < length(v) && print(io, ", ")
        end
        print(io, "]")
    elseif v isa AbstractDict
        print(io, "{")
        dk = collect(keys(v))
        for (i, k) in enumerate(dk)
            print(io, _jstr(k), ": ")
            _write_json_value(io, v[k])
            i < length(dk) && print(io, ", ")
        end
        print(io, "}")
    else
        print(io, _jstr(string(v)))
    end
end
