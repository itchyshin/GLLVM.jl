# Random-effects foundation for GLLVM.jl — grouping-factor coding.
#
# A random-effects (RE) block is a latent block on a grouping factor, integrated out
# by the SAME marginal engines as the ordination latent variables. The per-level
# coefficients/BLUPs are integrated out (exactly like the LV scores z); only the
# variance components enter the packed θ. This file holds the grouping-coder shared by
# the RE fitters (`fit_random_effects.jl`).

# Map an arbitrary grouping column (any element type) to integer codes 1:L, returning
# (codes, levels) where levels[codes[i]] == values[i]. Stable order of first
# appearance, so the coding is deterministic and reproducible.
function _code_grouping(values::AbstractVector)
    levels = Vector{eltype(values)}()
    index = Dict{eltype(values), Int}()
    codes = Vector{Int}(undef, length(values))
    @inbounds for (i, v) in enumerate(values)
        c = get(index, v, 0)
        if c == 0
            push!(levels, v)
            c = length(levels)
            index[v] = c
        end
        codes[i] = c
    end
    return codes, levels
end
