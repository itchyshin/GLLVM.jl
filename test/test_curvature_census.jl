# Structural guard for the Fisher-vs-observed Laplace curvature fault class.
#
# The class exists because `_glm_weight` serves two roles: the Fisher-scoring mode
# search (where expected information is correct) and the Laplace log-det (where TMB
# uses the OBSERVED joint Hessian). A family that ships only a Fisher weight and says
# nothing is silently in the second role with the wrong matrix.
#
# Every prose census of this class so far has been built with `grep`, and every one
# missed sites:
#   * `^_glm_weight(` skipped Beta (`beta.jl:21`) and GP1 (`gp1.jl:65`) — both use
#     `function … end` block form.
#   * A `src/families/*.jl` sweep skipped `_glm_weight(::Normal)` at `spde_latent.jl:54`,
#     which lives outside that directory.
#
# So this guard does NOT grep. It reflects over the method table, which cannot miss a
# definition by formatting or location. Its job is to make the fault class impossible to
# EXTEND silently: add a family with a `_glm_weight` and no curvature declaration and
# this test fails, naming the file and line and telling you what to declare.
#
# It deliberately does not assert which choice is correct — that is a per-family
# modelling decision. It asserts only that a choice was MADE and written down.

using GLLVM, Test

const G = GLLVM

_family_of(m) = (p = Base.unwrap_unionall(m.sig).parameters;
                 length(p) >= 2 ? p[2] : nothing)

# Families whose curvature question is OPEN: they ship a Fisher weight, TMB's log-det
# wants the observed one, and the flip is a pending maintainer decision (it is a parity
# change with a measured accuracy cost — see docs/dev-log/check-log.md 2026-08-26).
# This list is the ledger. Shrinking it is progress; growing it silently is the bug.
const KNOWN_OPEN = Set([:TweedieED, :NB1, :Beta, :GeneralizedPoisson1,
                        :NegativeBinomial, :StudentTFamily])

# Families where Fisher == observed for STRUCTURAL reasons that are not expressed as a
# `_glm_weight_matches_observed` trait, each with the reason recorded.
const STRUCTURALLY_EXEMPT = Dict(
    # Gaussian log-density is quadratic in η at the identity link, so the second
    # derivative carries no y-dependence and expected == observed identically.
    :Normal => "Gaussian/identity: log-density quadratic in η, curvature is y-free",
    # Routed with `hessian = :fisher` EXPLICITLY and deliberately; see the comment at
    # exponential.jl:55-66. Folding it into the class without re-deriving would be wrong.
    :Exponential => "deliberate explicit :fisher routing, documented at exponential.jl:55",
)

@testset "Laplace curvature census (structural guard)" begin
    weight_methods = collect(methods(G._glm_weight))
    @test !isempty(weight_methods)

    # Families that declare Fisher ≡ observed via the trait.
    declared_safe = Set{Symbol}()
    for m in methods(G._glm_weight_matches_observed)
        f = _family_of(m)
        f === Any && continue
        push!(declared_safe, nameof(f))
    end

    # Families that supply an observed-curvature override.
    has_observed = Set{Symbol}()
    for m in methods(G._glm_obs_weight)
        f = _family_of(m)
        f === Any && continue          # the generic ForwardDiff fallback
        push!(has_observed, nameof(f))
    end

    undeclared = Tuple{Symbol,String}[]
    for m in weight_methods
        f = _family_of(m)
        f === nothing && continue
        name = nameof(f)
        site = string(basename(string(m.file)), ":", m.line)

        declared = name in declared_safe ||
                   name in has_observed ||
                   name in KNOWN_OPEN ||
                   haskey(STRUCTURALLY_EXEMPT, name)

        declared || push!(undeclared, (name, site))
    end

    if !isempty(undeclared)
        msg = join(["  $(n) @ $(s)" for (n, s) in undeclared], "\n")
        @error """
        A family defines `_glm_weight` but declares nothing about its Laplace curvature.

        $msg

        `_glm_weight` is used BOTH for the Fisher-scoring mode search and for the
        marginal's log-det. TMB's log-det uses the OBSERVED joint Hessian, so a family
        that only ships the Fisher weight silently computes a different marginal.

        Declare one of:
          * `_glm_weight_matches_observed(::F, ::L) = true`  — if the link is canonical
            and the two coincide (verify it, do not assume it);
          * `_glm_obs_weight(f::F, μ, n, me, y, link, η) = …` plus
            `_default_hessian(::F, ::L) = :observed`  — if they differ and you are fixing it;
          * add it to `KNOWN_OPEN` in this file — if the flip is a pending decision.
        """
    end
    @test isempty(undeclared)

    # The two buckets must stay disjoint: a family cannot be both fixed and open.
    @test isempty(intersect(has_observed, KNOWN_OPEN))

    # Every KNOWN_OPEN entry must actually still define a Fisher weight. If a family is
    # fixed and someone forgets to remove it here, this catches the stale ledger entry —
    # which is exactly how the old prose tally came to read "NB1 … fixed" for an
    # untouched line.
    weight_names = Set(nameof(_family_of(m)) for m in weight_methods
                       if _family_of(m) !== nothing)
    stale = setdiff(KNOWN_OPEN, weight_names)
    @test isempty(stale)

    # A fixed family must pair its override with a family-SPECIFIC `_default_hessian`,
    # or the override is dead code and the marginal still uses the Fisher weight.
    #
    # This must test for a *specialised* method, not merely an applicable one: the
    # generic fallback `_default_hessian(family, link::Link)` at laplace.jl:190 applies
    # to every family, so a `hasmethod` probe would pass vacuously for all of them.
    specialised_default = Set{Symbol}()
    for m in methods(G._default_hessian)
        f = _family_of(m)
        (f === nothing || f === Any) && continue
        push!(specialised_default, nameof(f))
    end
    for name in has_observed
        @test name in specialised_default
    end
end
