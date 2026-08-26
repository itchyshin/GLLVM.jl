using GLLVM, ForwardDiff, Printf, Random
const G = GLLVM

# Observed curvature of the conditional part, wrt ηc, straight from the family's own
# `_tp_pieces` log-density. Family-agnostic: whatever structure the family has (hurdle,
# zero-inflated mixture), -d2 logf / d ηc^2 at fixed ηz IS the observed quantity the
# Laplace log-det wants.
obs_Wc(fam, y, ηz, ηc) =
    -ForwardDiff.derivative(a -> ForwardDiff.derivative(b -> G._tp_pieces(fam, y, ηz, b)[5], a), ηc)

fisher_Wc(fam, y, ηz, ηc) = G._tp_pieces(fam, y, ηz, ηc)[4]

println("="^78)
println("CONTROL — does the instrument reproduce DeltaGamma's MERGED override?")
println("="^78)
ok = true
for (α, y, ηc) in [(2.0,1.3,0.4), (2.0,0.7,-0.6), (5.0,2.2,1.1), (0.8,0.3,-1.4)]
    f = G.DeltaGamma(α)
    W  = fisher_Wc(f, y, 0.2, ηc)
    ref = G._tp_observed_Wc(f, y, ηc, W)      # the merged, already-verified formula
    mine = obs_Wc(f, y, 0.2, ηc)
    rel = abs(mine-ref)/max(abs(ref),1e-12)
    global ok &= rel < 1e-8
    @printf("  α=%.1f y=%.2f ηc=%+.2f | merged=%.10f  probe=%.10f  rel=%.2e %s\n",
            α, y, ηc, ref, mine, rel, rel<1e-8 ? "OK" : "MISMATCH")
end
println(ok ? "\n  ⇒ INSTRUMENT VALIDATED against the approved precedent.\n"
           : "\n  ⇒ INSTRUMENT NOT VALIDATED — do not trust the table below.\n")

println("="^78)
println("THE SEVEN OPEN TWO-PART FAMILIES — Fisher Wc vs observed")
println("="^78)
@printf("%-16s %6s %8s %8s %14s %14s %10s %7s\n",
        "family","y","ηz","ηc","Fisher Wc","observed Wc","rel gap","obs<0?")

fams = [("DeltaLogNormal", G.DeltaLogNormal(1.0),  [0.0, 1.4, 3.0]),
        ("HurdlePoisson",  G.HurdlePoisson(),      [0.0, 2.0, 7.0]),
        ("HurdleNB",       G.HurdleNB(2.5),        [0.0, 3.0, 9.0]),
        ("ZIPoisson",      G.ZIPoisson(),          [0.0, 1.0, 6.0]),
        ("ZINB",           G.ZINB(2.0),            [0.0, 2.0, 8.0]),
        ("ZIB",            G.ZIB(10),              [0.0, 3.0, 9.0]),
        ("BetaHurdle",     G.BetaHurdle(8.0),      [0.0, 0.35, 0.9])]

worst = Dict{String,Float64}(); neg = Dict{String,Int}()
for (name, f, ys) in fams
    w = 0.0; nneg = 0
    for y in ys, ηz in (-0.8, 0.5), ηc in (-1.0, 0.3, 1.2)
        fw = try fisher_Wc(f, y, ηz, ηc) catch; NaN end
        ow = try obs_Wc(f, y, ηz, ηc)    catch e; NaN end
        if isnan(ow) || isnan(fw)
            @printf("%-16s %6.2f %8.1f %8.1f %14s %14s %10s %7s\n",
                    name, y, ηz, ηc, "—", "AD failed", "—", "—")
            continue
        end
        rel = abs(ow-fw)/max(abs(fw),1e-12); w = max(w, rel); ow < 0 && (nneg += 1)
        if (y == ys[1] && ηz == -0.8 && ηc == -1.0) || rel > 0.25
            @printf("%-16s %6.2f %8.1f %8.1f %14.6f %14.6f %9.1f%% %7s\n",
                    name, y, ηz, ηc, fw, ow, 100rel, ow<0 ? "YES" : "")
        end
    end
    worst[name] = w; neg[name] = nneg
end

println("\n" * "="^78)
println("SUMMARY — which of the seven actually matter")
println("="^78)
@printf("%-16s %14s %18s\n", "family", "worst rel gap", "negative-obs cells")
for (name, _, _) in fams
    @printf("%-16s %13.1f%% %18d\n", name, 100worst[name], neg[name])
end
