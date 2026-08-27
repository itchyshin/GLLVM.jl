# D-139 pre-run test: two cells, timed, BEFORE any campaign submission.
# A pre-run catches a WRONG answer, not just a slow one: check that the
# quadrature oracle and both fits behave sanely on one continuous and one
# count family before an array is ever submitted.
include(joinpath(@__DIR__, "cell.jl"))
out = joinpath(@__DIR__, "prerun_out"); mkpath(out)
for (fam, reg, seed) in (("gamma", "small", 1), ("negbin", "small", 1))
    run_cell(fam, reg, seed, out)
end
