using GLLVM,Random,LinearAlgebra
rng=MersenneTwister(714);p=3;n=36;K=1
Y=reshape([.8,.4,-.3],3,1)*randn(rng,K,n)+.7randn(rng,p,n)
f=fit_gaussian_gllvm(Y;K=K,aghq=3);i=f.integration
for b in 1:2
    Yb=simulate(f,n;rng=MersenneTwister(13+b))
    controls=merge(deepcopy(i.base_controls),(K=K,aghq=i.k,aghq_control=i.controls,
        X=copy(i.data.design),β_fixed=copy(f.pars.β_fixed),mask=copy(i.data.mask),offset=copy(i.data.offset)))
    try
        fb=fit_gaussian_gllvm(Yb;controls...)
        @show b fb.converged fb.integration.actual fb.integration.reason
        for r in fb.integration.result.runs
            @show r.converged r.usable r.stop_reason r.frozen_gradient_max r.relative_gradient
        end
    catch err
        showerror(stdout,err,catch_backtrace());println()
    end
end
