"""
Independent structural-equation pedigree oracle for Destination B.
Rows of C express each animal as a sum of independent Mendelian draws.
No R helper, precision inversion or production likelihood is used here.
"""
function destination_b_pedigree_fixture()
    sire = [0, 0, 0, 0, 1, 1, 2, 2, 5, 7, 9, 9]
    dam  = [0, 0, 0, 0, 3, 3, 4, 4, 6, 8, 10, 6]
    n = length(sire)
    C = zeros(n, n)
    B = Matrix{Float64}(I, n, n)
    F = zeros(n)
    D = ones(n)
    for i in 1:n
        s, d = sire[i], dam[i]
        if s != 0 || d != 0
            @assert 0 < s < i && 0 < d < i
            D[i] = 0.5 - 0.25 * (F[s] + F[d])
            C[i, :] .= 0.5 .* (C[s, :] .+ C[d, :])
            B[i, s] = B[i, d] = -0.5
        end
        C[i, i] = sqrt(D[i])
        F[i] = sum(abs2, C[i, :]) - 1
    end
    observed = [12, 5, 9, 7, 10, 6, 11, 8]
    return (; sire, dam, observed, C, B, D, F, A = C*C',
        Q = B' * Diagonal(1 ./ D) * B, log_det_Q = -sum(log, D),
        observation_nodes = repeat(observed; inner = 2))
end
