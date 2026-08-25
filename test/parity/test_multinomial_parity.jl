# test_multinomial_parity.jl — fixed-effect softmax multinomial vs gllvmTMB (twin fid 16)
#
# Included by runparity.jl. NEVER included by test/runtests.jl.
#
# Identity lock: docs/dev-log/decisions/2026-08-18-multinomial-identity.md (ACCEPTED).
#   · Marker `Multinomial`, baseline-category logit, η₁ ≡ 0.
#   · Pack size (C−1)(1 + p) — per-category intercepts (+ slopes when X is given).
#   · **No latent variables** in v1: `fit_multinomial_gllvm` throws on K / num_lv.
#   · No dispersion parameter.
#   The Identity fenced a twin Δ as FORBIDDEN *"until an engine exists"* and sanctioned
#   exactly this cell once it did: *"A later engine arc may run a FE-only light RCall
#   cell at rtol 1e-6 against twin fid 16."* The engine landed in #257, so the
#   precondition is met and this cell is the sanctioned follow-up.
#
# Why this cell does NOT use the shared oracle helper: every other cell reshapes a
# numeric p×n matrix and fits `value ~ 0 + trait + latent(0 + trait | site, …)`.
# Multinomial's response is a categorical FACTOR column (the twin expands it into C−1
# one-hot pseudo-trait rows internally), and there is no `latent(...)` term because
# Julia v1 is fixed-effects only. The twin supports a no-covstruct multinomial fit, so
# FE-only is a genuine same-model comparison, not a concession.
#
# Comparability: NO Laplace on either side — the FE softmax likelihood is exact and
# concave, so both optimisers target the same unique optimum. The fisher/observed
# curvature question that bit NB1 cannot arise here (there is no latent integral).
#
# NAME CLASH (see 2026-08-18-multinomial-name-clash.md): `Distributions.Multinomial`
# collides with GLLVM's marker. This file imports no Distributions symbol unqualified.
#
# Twin Δ rule: no number is quoted unless this cell runs live under
# GLLVM_PARITY_TESTS=1 against a real gllvmTMB. Never invent, never carry over.

using GLLVM, RCall, Test, Random

# parity_helpers.jl is included once by runparity.jl

# Seed pre-registered BEFORE any run. 42–49, 420–431 and 52–56 are already taken.
const _MN_SEED = 57

@testset "multinomial GLLVM parity: GLLVM.jl vs gllvmTMB (twin fid 16, FE-only)" begin

    Random.seed!(_MN_SEED)
    ncat, n = 4, 400                 # ncat ≥ 3 (2 categories would be binomial)
    # True baseline-category logits with η₁ ≡ 0.
    β_true = [0.0, 0.6, -0.4, 0.25]
    w = exp.(β_true)
    prob = w ./ sum(w)
    cum = cumsum(prob)
    y = [findfirst(>=(rand()), cum) for _ in 1:n]

    @testset "response is well formed for the twin" begin
        @test all(v -> 1 <= v <= ncat, y)
        @test length(unique(y)) == ncat      # every category observed — else the
                                             # twin drops a level and the packs differ
        @test ncat >= 3
    end

    jl_fit = fit_multinomial_gllvm(y; n_categories = ncat)
    @test jl_fit.converged
    @test isfinite(jl_fit.loglik)
    @test jl_fit.n_categories == ncat
    # Pack size (C−1)(1+p) with p = 0 covariates ⇒ C−1 free intercepts.
    @test length(jl_fit.β) == ncat - 1
    jl_logL = jl_fit.loglik

    r = fit_gllvmtmb_parity_loglik_multinomial(y, ncat)
    @test r.converged
    @test isfinite(r.logLik)

    print_parity_loglik(
        "multinomial FE logLik oracle (seed=$(_MN_SEED), ncat=$ncat, n=$n; twin fid 16)";
        jl_logL = jl_logL, r_logL = r.logLik, r_obj = r.objective,
    )

    @testset "log-likelihood agreement (rtol=1e-6)" begin
        @test jl_logL ≈ r.logLik rtol = 1e-6
        @test r.logLik ≈ -r.objective rtol = 0 atol = 1e-10
    end

    # Independent anchor: for an intercept-only multinomial the MLE is the observed
    # category frequency, so the maximised log-likelihood has a closed form,
    # Σ_c n_c log(n_c / n). Asserting it pins BOTH engines to the analytic optimum
    # rather than merely to each other — a cheap guard against the two agreeing on a
    # common mistake, which no jl-vs-r comparison can detect on its own.
    @testset "both match the closed-form intercept-only MLE" begin
        counts = [count(==(c), y) for c in 1:ncat]
        analytic = sum(counts[c] * log(counts[c] / n) for c in 1:ncat)
        @test jl_logL ≈ analytic rtol = 1e-6
        @test r.logLik ≈ analytic rtol = 1e-6
    end
end
