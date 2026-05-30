using GLLVM, Test

# Quality battery. Aqua (package hygiene) runs always-on under `Pkg.test()`
# (the full-suite command, also what CI runs). Under the quick core run
# `julia --project=. test/runtests.jl` (root env) Aqua is not installed, so the
# testset skips gracefully — run `Pkg.test()` for full coverage.
#
# JET (type-stability) is intentionally NOT wired here yet: it currently
# surfaces real instabilities in the CHOLMOD / sparse gradient path
# (`takahashi_diag` infers as `Any`; CHOLMOD `\` runtime dispatch), which
# cascade through `grad_node_perspecies`. These are correctness-neutral perf
# targets for the Phase 1.3 perf round (tests pass, cross-platform CI green);
# JET wires green once they are fixed.

@testset "quality" begin
    if Base.find_package("Aqua") === nothing
        @info "Aqua not in this environment — run `Pkg.test()` for the full quality battery"
        @test_skip false
    else
        @eval using Aqua
        # ambiguities=false: method ambiguities here originate in dependencies,
        # not GLLVM, so they are noise for this package's hygiene gate.
        Aqua.test_all(GLLVM; ambiguities = false)
    end
end
