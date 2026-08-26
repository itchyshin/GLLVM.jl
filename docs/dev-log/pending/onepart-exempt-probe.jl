using GLLVM, ForwardDiff, Distributions, Printf
const G = GLLVM
# Is each single-part STRUCTURALLY_EXEMPT family's Fisher weight actually equal to the
# observed one? _glm_obs_weight (laplace.jl:215) is the package's own generic observed
# weight via nested ForwardDiff.
cases = [("Normal / IdentityLink", Normal(0.0,1.0), G.IdentityLink(), [-1.5, 0.4, 2.2]),
         ("Exponential / LogLink", Exponential(1.0), G.LogLink(),      [0.3, 1.0, 4.0])]
for (name, fam, link, ys) in cases
    println("\n=== $name ===")
    @printf("%8s %8s %14s %14s %12s\n", "y", "eta", "Fisher W", "observed W", "rel gap")
    worst = 0.0
    for y in ys, eta in (-0.7, 0.2, 1.1)
        mu = G.linkinv(link, eta)
        me = G.mu_eta(link, eta)
        fw = G._glm_weight(fam, mu, 1, me)
        ow = try G._glm_obs_weight(fam, mu, 1, me, y, link, eta) catch e; NaN end
        rel = isnan(ow) ? NaN : abs(ow-fw)/max(abs(fw),1e-12)
        isnan(rel) || (worst = max(worst, rel))
        @printf("%8.2f %8.2f %14.6f %14.6f %11.2f%%\n", y, eta, fw, ow, 100rel)
    end
    @printf("  worst relative gap: %.2f%%  -> %s\n", 100worst,
            worst < 1e-8 ? "IDENTICAL (exemption is an equality claim, machine-checkable)"
                         : "DIFFERENT (exemption is a DECISION, not an equality)")
end
