using GLLVM, ForwardDiff
c0, c1, φ = -1.0, 1.0, 10.0
# an interior-mass y with a large-magnitude eta (plausible after one Newton step)
y = 0.5
for η in [3.0, 8.0, 12.0, 20.0]
    s0 = GLLVM._ob_logistic(η - c0); s1 = GLLVM._ob_logistic(η - c1)
    println("η=$η  s0=$s0  s1=$s1  s0-s1=$(s0-s1)  log(s0-s1)=$(log(s0-s1))")
end
println()
s, W = GLLVM._ob_score_weight(y, 20.0, c0, c1, φ)
println("score at η=20: ", s, "  W=", W)
